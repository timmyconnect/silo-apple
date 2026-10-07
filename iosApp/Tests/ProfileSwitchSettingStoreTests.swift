import XCTest
@testable import Silo

@MainActor
final class ProfileSwitchSettingStoreTests: XCTestCase {
    private var identity: HTTPRequestIdentity?
    private var transport: FakeProfileSwitchSettingTransport!

    private static let profileA = HTTPRequestIdentity(
        serverId: "server-1",
        serverURL: "https://silo.example",
        profileId: "profile-a",
        clientFamily: "ios"
    )
    private static let profileB = HTTPRequestIdentity(
        serverId: "server-1",
        serverURL: "https://silo.example",
        profileId: "profile-b",
        clientFamily: "ios"
    )

    override func setUp() async throws {
        try await super.setUp()
        identity = Self.profileA
        transport = FakeProfileSwitchSettingTransport()
    }

    private var savedCount = 0

    private func makeStore() -> ProfileSwitchSettingStore {
        ProfileSwitchSettingStore(
            key: .catalogShowAdvisoryAge,
            title: "Show Advisory Age",
            transport: transport,
            requestIdentity: { [unowned self] in self.identity },
            onSaved: { [unowned self] in self.savedCount += 1 }
        )
    }

    func testSupportedValueHydratesAndWriteUsesCapturedIdentity() async {
        transport.effectiveValue = true
        let store = makeStore()
        await store.refresh()

        XCTAssertTrue(store.isSupported)
        XCTAssertTrue(store.isOn)
        XCTAssertEqual(transport.readIdentities, [Self.profileA])

        await store.setOn(false)
        XCTAssertFalse(store.isOn)
        XCTAssertEqual(transport.writes, [.init(enabled: false, identity: Self.profileA)])
        XCTAssertFalse(store.isSaving)
        XCTAssertEqual(savedCount, 1, "a confirmed save runs the saved hook once")
    }

    func testUnsupportedServerHidesSettingAndDoesNotReadOrWrite() async {
        transport.capabilities = .available(advisoryCapabilities(revision: 9))
        let store = makeStore()
        await store.refresh()

        XCTAssertFalse(store.isSupported)
        XCTAssertFalse(store.isOn)
        XCTAssertTrue(transport.readIdentities.isEmpty)
        await store.setOn(true)
        XCTAssertTrue(transport.writes.isEmpty)
    }

    func testRefreshCannotOverwriteANewerToggle() async {
        let store = makeStore()
        await store.refresh()
        transport.readGate = AsyncTestGate()
        let refresh = Task { await store.refresh() }
        await waitUntil { self.transport.readIdentities.count == 2 }

        await store.setOn(true)
        transport.readGate?.open()
        await refresh.value

        XCTAssertTrue(store.isOn)
    }

    func testOlderUnsupportedResultCannotClearANewerSuccessfulToggle() async {
        let store = makeStore()
        await store.refresh()
        transport.capabilityGate = AsyncTestGate()
        let refresh = Task { await store.refresh() }
        await waitUntil { self.transport.capabilityRequests == 2 }

        await store.setOn(true)
        transport.capabilities = .available(advisoryCapabilities(revision: 9))
        transport.capabilityGate?.open()
        await refresh.value

        XCTAssertTrue(store.isSupported)
        XCTAssertTrue(store.isOn)
    }

    func testFailedWriteDoesNotDiscardConcurrentRefresh() async {
        let store = makeStore()
        await store.refresh()
        transport.effectiveValue = true
        transport.writeError = TestWriteError.failed
        transport.readGate = AsyncTestGate()
        let refresh = Task { await store.refresh() }
        await waitUntil { self.transport.readIdentities.count == 2 }

        await store.setOn(true)
        XCTAssertFalse(store.isOn)
        transport.readGate?.open()
        await refresh.value

        XCTAssertTrue(store.isOn)
        XCTAssertFalse(store.isSaving)
    }

    func testToggleShowsChoiceWhileSaving() async {
        let store = makeStore()
        await store.refresh()
        transport.writeGate = AsyncTestGate()
        let write = Task { await store.setOn(true) }
        await waitUntil { store.isSaving }

        XCTAssertTrue(store.isOn)
        transport.writeGate?.open()
        await write.value
        XCTAssertTrue(store.isOn)
        XCTAssertFalse(store.isSaving)
    }

    func testFailedWriteRollsBackAndExplains() async {
        let store = makeStore()
        await store.refresh()
        transport.writeError = SettingsAPIError.transport(description: "offline")

        await store.setOn(true)

        XCTAssertFalse(store.isOn)
        XCTAssertEqual(store.writeError, "Couldn't save Show Advisory Age. Check the connection and try again.")
        XCTAssertEqual(savedCount, 0, "a failed save must not run the saved hook")
        transport.writeError = nil
        await store.setOn(true)
        XCTAssertTrue(store.isOn)
        XCTAssertNil(store.writeError)
    }

    func testSettingStaysHiddenUntilItsValueLoads() async {
        transport.effectiveError = TestWriteError.failed
        let store = makeStore()
        await store.refresh()
        XCTAssertFalse(store.isSupported)

        transport.effectiveError = nil
        transport.effectiveValue = true
        await store.hydrateIfNeeded()
        XCTAssertTrue(store.isSupported)
        XCTAssertTrue(store.isOn)
    }

    func testUnavailableSettingsRetryOnNextRead() async {
        transport.capabilities = .unavailable
        let store = makeStore()
        await store.hydrateIfNeeded()
        XCTAssertFalse(store.isSupported)

        transport.capabilities = .available(advisoryCapabilities(revision: 14))
        transport.effectiveValue = true
        await store.hydrateIfNeeded()
        XCTAssertTrue(store.isSupported)
        XCTAssertTrue(store.isOn)
    }

    func testStaleValueIsReadAgainAfterForeground() async {
        let store = makeStore()
        await store.hydrateIfNeeded()
        XCTAssertFalse(store.isOn)

        transport.effectiveValue = true
        await store.hydrateIfNeeded()
        XCTAssertFalse(store.isOn, "a hydrated value is reused until marked stale")
        store.markStale()
        await store.hydrateIfNeeded()
        XCTAssertTrue(store.isOn)
    }

    func testReadInFlightWhenMarkedStaleDoesNotCountAsFresh() async {
        let store = makeStore()
        await store.hydrateIfNeeded()
        transport.readGate = AsyncTestGate()
        let refresh = Task { await store.refresh() }
        await waitUntil { self.transport.readIdentities.count == 2 }

        store.markStale()
        transport.readGate?.open()
        await refresh.value
        transport.effectiveValue = true
        await store.hydrateIfNeeded()

        XCTAssertEqual(transport.readIdentities.count, 3)
        XCTAssertTrue(store.isOn)
    }

    func testHydrateJoiningAStaleReadStartsAFreshOne() async {
        let store = makeStore()
        await store.hydrateIfNeeded()
        transport.readGate = AsyncTestGate()
        let refresh = Task { await store.refresh() }
        await waitUntil { self.transport.readIdentities.count == 2 }

        store.markStale()
        let hydrate = Task { await store.hydrateIfNeeded() }
        for _ in 0..<10 { await Task.yield() }
        transport.readGate?.open()
        await refresh.value
        await hydrate.value

        XCTAssertEqual(transport.readIdentities.count, 3)
    }

    func testMarkedStaleWhileJoinedReadRunsStartsAFreshOne() async {
        let store = makeStore()
        await store.hydrateIfNeeded()
        transport.readGate = AsyncTestGate()
        let refresh = Task { await store.refresh() }
        await waitUntil { self.transport.readIdentities.count == 2 }

        let joined = Task { await store.refresh() }
        for _ in 0..<10 { await Task.yield() }
        store.markStale()
        transport.readGate?.open()
        await refresh.value
        await joined.value

        XCTAssertEqual(transport.readIdentities.count, 3)
    }

    func testFailedWriteIsReconciledByTheNextRead() async {
        let store = makeStore()
        await store.hydrateIfNeeded()
        transport.writeError = SettingsAPIError.transport(description: "timed out")
        await store.setOn(true)
        XCTAssertFalse(store.isOn)

        // The PUT landed even though the client saw it fail.
        transport.effectiveValue = true
        await store.hydrateIfNeeded()
        XCTAssertTrue(store.isOn)
    }

    func testWriteCompletionAfterClearCannotRestorePreviousProfileState() async {
        transport.writeGate = AsyncTestGate()
        let store = makeStore()
        await store.refresh()
        let write = Task { await store.setOn(true) }
        await waitUntil { store.isSaving }

        store.clear()
        identity = Self.profileB
        transport.writeGate?.open()
        await write.value

        XCTAssertFalse(store.isOn)
        XCTAssertFalse(store.isSupported)
        XCTAssertFalse(store.isSaving)
    }

    private func waitUntil(
        _ condition: @escaping @MainActor () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 where !condition() {
            await Task.yield()
        }
        XCTAssertTrue(condition(), file: file, line: line)
    }
}

@MainActor
private final class FakeProfileSwitchSettingTransport: ProfileSwitchSettingTransport, @unchecked Sendable {
    struct Write: Equatable {
        let enabled: Bool
        let identity: HTTPRequestIdentity
    }

    var capabilities: SettingsCapabilitiesResult = .available(advisoryCapabilities(revision: 14))
    var effectiveValue = false
    var capabilityGate: AsyncTestGate?
    var readGate: AsyncTestGate?
    var writeGate: AsyncTestGate?
    var writeError: Error?
    var effectiveError: Error?
    private(set) var capabilityRequests = 0
    private(set) var readIdentities: [HTTPRequestIdentity] = []
    private(set) var writes: [Write] = []

    func contractCapabilities(requestIdentity: HTTPRequestIdentity) async -> SettingsCapabilitiesResult {
        capabilityRequests += 1
        await capabilityGate?.wait()
        return capabilities
    }

    func effectiveValue(requestIdentity: HTTPRequestIdentity) async throws -> EffectiveSettingValuesResponse {
        readIdentities.append(requestIdentity)
        await readGate?.wait()
        if let effectiveError { throw effectiveError }
        return try advisoryEffectiveResponse(effectiveValue)
    }

    func putValue(_ enabled: Bool, requestIdentity: HTTPRequestIdentity) async throws {
        writes.append(.init(enabled: enabled, identity: requestIdentity))
        await writeGate?.wait()
        if let writeError { throw writeError }
    }
}

private enum TestWriteError: Error {
    case failed
}

@MainActor
private final class AsyncTestGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters = []
    }
}

private func advisoryCapabilities(revision: Int) -> APIv2SettingsContractCapabilities {
    APIv2SettingsContractCapabilities(
        revision: "capabilities-\(revision)",
        state: "available",
        allowed: true,
        manifestRevision: revision,
        clientFamilies: ["ios"],
        supportsBatchedEffective: true,
        supportsAtomicShortcuts: true
    )
}

private func advisoryEffectiveResponse(_ enabled: Bool) throws -> EffectiveSettingValuesResponse {
    let object: [String: Any] = [
        "items": [[
            "key": SettingKey.catalogShowAdvisoryAge.rawValue,
            "value": enabled,
            "source": "profile",
        ]],
        "revision": 14,
    ]
    let data = try JSONSerialization.data(withJSONObject: object)
    return try SettingsWireCoding.makeDecoder().decode(EffectiveSettingValuesResponse.self, from: data)
}

/// The rule that shows the Featured adult switch off and disabled.
final class ProfileRatingLimitTests: XCTestCase {
    private func profile(isChild: Bool = false, maxContentRating: String? = nil) -> UserProfile {
        UserProfile(id: "p", name: "P", avatarEmoji: nil, hasPin: false, isChild: isChild,
            maxContentRating: maxContentRating)
    }

    func testChildOrAnyCeilingIsLimited() {
        XCTAssertTrue(profile(isChild: true).hasRatingLimit)
        XCTAssertTrue(profile(maxContentRating: "PG-13").hasRatingLimit)
        XCTAssertFalse(profile().hasRatingLimit)
        XCTAssertFalse(profile(maxContentRating: "").hasRatingLimit)
    }

    func testProfileCachedBeforeTheCeilingFieldStillDecodes() throws {
        let cached = Data(#"{"id":"p","name":"P","hasPin":false,"isChild":false,"isPrimary":true}"#.utf8)
        XCTAssertFalse(try JSONDecoder().decode(UserProfile.self, from: cached).hasRatingLimit)
    }
}
