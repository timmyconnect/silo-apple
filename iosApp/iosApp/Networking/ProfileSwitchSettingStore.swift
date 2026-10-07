import Foundation

protocol ProfileSwitchSettingTransport: AnyObject, Sendable {
    func contractCapabilities(requestIdentity: HTTPRequestIdentity) async -> SettingsCapabilitiesResult
    func effectiveValue(requestIdentity: HTTPRequestIdentity) async throws -> EffectiveSettingValuesResponse
    func putValue(_ enabled: Bool, requestIdentity: HTTPRequestIdentity) async throws
}

final class SiloProfileSwitchSettingTransport: ProfileSwitchSettingTransport {
    private let key: SettingKey
    private let api: SiloAPI

    init(key: SettingKey, api: SiloAPI = .shared) {
        self.key = key
        self.api = api
    }

    func contractCapabilities(requestIdentity: HTTPRequestIdentity) async -> SettingsCapabilitiesResult {
        await api.getContractCapabilities(requestIdentity: requestIdentity)
    }

    func effectiveValue(requestIdentity: HTTPRequestIdentity) async throws -> EffectiveSettingValuesResponse {
        try await api.getEffectiveValues(
            keys: [key],
            requestIdentity: requestIdentity
        )
    }

    func putValue(_ enabled: Bool, requestIdentity: HTTPRequestIdentity) async throws {
        try await api.putValue(
            key: key,
            scope: .profile,
            value: .bool(enabled),
            requestIdentity: requestIdentity
        )
    }
}

/// One profile-scoped on/off setting from the server's settings contract.
///
/// Matching the web client, Apple first verifies that the connected settings
/// contract supports the key, then resolves the active profile's effective
/// value. A missing setting or an older server fails closed.
///
/// The Apple app does not subscribe to settings change events, so a change
/// made on another device arrives at the next read: opening Settings, or the
/// first detail page after the app returns to the foreground.
@MainActor
final class ProfileSwitchSettingStore: ObservableObject {
    /// Whether item detail shows advisory ages. The server sends advisory
    /// metadata independently of this setting.
    static let advisoryAge = ProfileSwitchSettingStore(
        key: .catalogShowAdvisoryAge,
        title: "Show Advisory Age"
    )
    /// Whether titles rated 18 or over may appear in Home featured sections.
    /// The server does the filtering, so a saved change drops the cached Home
    /// and refreshes a mounted one.
    static let featuredAdult = ProfileSwitchSettingStore(
        key: .homeShowAdultInFeatured,
        title: "Show Adult Titles in Featured",
        onSaved: PersonalStateSync.invalidateDerivedLists
    )

    @Published private(set) var isOn = false
    /// True once the server supports the setting and this profile's value has
    /// been read, so the toggle never shows a value the app doesn't know.
    @Published private(set) var isSupported = false
    @Published private(set) var isSaving = false
    @Published private(set) var writeError: String?

    private let key: SettingKey
    /// The switch's label, named in a failed save's message.
    private let title: String
    private let transport: ProfileSwitchSettingTransport
    /// Runs after the server confirms a save for the identity that made it.
    private let onSaved: @MainActor () -> Void
    private let requestIdentity: @MainActor () -> HTTPRequestIdentity?
    private var hasHydrated = false
    private var hydrationTask: Task<Void, Never>?
    private var generation: UInt = 0
    private var localMutationRevision: UInt = 0
    /// Bumped by ``markStale()`` so a read already in flight can still show
    /// its answer without counting as the fresh read that was asked for.
    private var staleMarks: UInt = 0
    /// The ``staleMarks`` value the in-flight read started under.
    private var hydrationStaleMark: UInt = 0
    /// The last value the server confirmed; a failed write rolls back to it.
    private var confirmedValue = false

    init(
        key: SettingKey,
        title: String,
        transport: ProfileSwitchSettingTransport? = nil,
        requestIdentity: @escaping @MainActor () -> HTTPRequestIdentity? =
            ProfileSwitchSettingStore.activeRequestIdentity,
        onSaved: @escaping @MainActor () -> Void = {}
    ) {
        self.key = key
        self.title = title
        self.transport = transport ?? SiloProfileSwitchSettingTransport(key: key)
        self.requestIdentity = requestIdentity
        self.onSaved = onSaved
    }

    func hydrateIfNeeded() async {
        guard !hasHydrated else { return }
        await refresh()
    }

    /// Lets the next ``hydrateIfNeeded()`` read again while keeping the last
    /// answer on screen. Called when the app returns to the foreground.
    func markStale() {
        staleMarks &+= 1
        hasHydrated = false
    }

    func refresh() async {
        // Join a read in flight, and read again once it finishes if the value
        // was marked stale before or while it ran.
        while let hydrationTask {
            let taskStaleMark = hydrationStaleMark
            await hydrationTask.value
            if taskStaleMark == staleMarks { return }
        }
        guard let identity = requestIdentity() else { return }

        let currentGeneration = generation
        let mutationRevision = localMutationRevision
        let staleMark = staleMarks
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                if self.generation == currentGeneration {
                    self.hydrationTask = nil
                }
            }

            let capabilities = await self.transport.contractCapabilities(requestIdentity: identity)
            guard self.canApply(generation: currentGeneration, identity: identity) else { return }

            switch capabilities {
            case .available(let contract) where contract.supports(self.key):
                break
            case .available, .serverUpgradeRequired:
                guard self.localMutationRevision == mutationRevision else { return }
                self.isSupported = false
                self.isOn = false
                self.confirmedValue = false
                self.hasHydrated = self.staleMarks == staleMark
                return
            case .unavailable, .failed:
                // Not a verdict about the server's version: keep the last
                // answer and retry on the next read.
                return
            }

            do {
                let response = try await self.transport.effectiveValue(requestIdentity: identity)
                // A write that succeeded while this read ran is newer than its answer.
                guard self.canApply(generation: currentGeneration, identity: identity),
                      self.localMutationRevision == mutationRevision else { return }
                let value = response.value(for: self.key)?.value.boolValue == true
                self.confirmedValue = value
                self.isSupported = true
                self.hasHydrated = self.staleMarks == staleMark
                // A save still in flight keeps showing the choice; if it fails,
                // it rolls back to this answer.
                if !self.isSaving {
                    self.isOn = value
                }
            } catch {
                // Keep the last answer. The next read retries.
            }
        }
        hydrationTask = task
        hydrationStaleMark = staleMark
        await task.value
    }

    /// Shows the choice at once and saves it at profile scope. A failed save
    /// rolls back to the last confirmed value and sets ``writeError``.
    func setOn(_ enabled: Bool) async {
        guard isSupported, !isSaving, let identity = requestIdentity() else { return }
        let currentGeneration = generation
        writeError = nil
        isOn = enabled
        isSaving = true
        defer {
            if generation == currentGeneration {
                isSaving = false
            }
        }
        do {
            try await transport.putValue(enabled, requestIdentity: identity)
            guard canApply(generation: currentGeneration, identity: identity) else { return }
            localMutationRevision &+= 1
            confirmedValue = enabled
            hasHydrated = true
            onSaved()
        } catch {
            guard canApply(generation: currentGeneration, identity: identity) else { return }
            isOn = confirmedValue
            writeError = Self.writeFailureMessage(for: error, title: title)
            // A save that timed out may still have landed; the next read
            // reconciles it.
            markStale()
        }
    }

    func clear() {
        generation &+= 1
        hydrationTask?.cancel()
        hydrationTask = nil
        isOn = false
        confirmedValue = false
        isSupported = false
        isSaving = false
        writeError = nil
        hasHydrated = false
    }

    private func canApply(generation: UInt, identity: HTTPRequestIdentity) -> Bool {
        !Task.isCancelled && self.generation == generation && requestIdentity() == identity
    }

    static func writeFailureMessage(for error: Error, title: String) -> String {
        switch SettingsAPIError.from(error) {
        case .transport:
            return "Couldn't save \(title). Check the connection and try again."
        case .serverUpgradeRequired, .unknownSetting:
            return "This server can't save \(title)."
        default:
            return "The server didn't save \(title). Try again."
        }
    }

    private static func activeRequestIdentity() -> HTTPRequestIdentity? {
        guard let server = ServerRegistry.shared.activeServer,
              ServerRegistry.shared.activeServerId == server.id,
              let profileId = AuthService.shared.profileId,
              !profileId.isEmpty else { return nil }
        return HTTPRequestIdentity(
            serverId: server.id,
            serverURL: server.url,
            profileId: profileId,
            clientFamily: AppleDeviceIdentity.current.clientFamily
        )
    }
}
