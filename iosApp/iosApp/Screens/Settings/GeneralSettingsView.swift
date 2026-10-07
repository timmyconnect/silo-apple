#if !os(tvOS)
import SwiftUI

/// Device-local startup preferences that do not belong to playback or
/// interface customization.
struct GeneralSettingsView: View {
    /// The profile the settings belong to; nil until the settings screen
    /// has loaded it.
    let activeProfile: UserProfile?

    @State private var launchPreferences = ProfileLaunchPreferences.shared
    @StateObject private var advisoryAgePreference = ProfileSwitchSettingStore.advisoryAge
    @StateObject private var featuredAdultPreference = ProfileSwitchSettingStore.featuredAdult

    /// A profile the app has not loaded yet counts as limited, so the switch
    /// never offers a choice the household manager may have ruled out.
    private var featuredAdultLocked: Bool { activeProfile?.hasRatingLimit ?? true }

    var body: some View {
        List {
            profileSection
            if advisoryAgePreference.isSupported {
                advisoryAgeSection
            }
            if featuredAdultPreference.isSupported {
                featuredAdultSection
            }
        }
        .settingsListChrome()
        .navigationTitle("General")
        .siloNavigationTitleDisplayMode(.inline)
        .siloToolbarColorSchemeDark()
        .task { await advisoryAgePreference.refresh() }
        .task { await featuredAdultPreference.refresh() }
    }

    private var profileSection: some View {
        Section {
            Picker("Profile Selection", selection: $launchPreferences.behavior) {
                ForEach(ProfileLaunchBehavior.allCases) { behavior in
                    Text(behavior.title)
                        .accessibilityHint(behavior.standardDescription)
                        .tag(behavior)
                }
            }
            .foregroundStyle(Color.siloOnSurface)
            .settingsPickerStyle()
            .accessibilityValue(launchPreferences.behavior.title)
            .accessibilityHint(launchPreferences.behavior.standardDescription)
        } header: {
            Text("Profiles")
                .foregroundStyle(Color.siloSecondaryText)
        } footer: {
            Text(launchPreferences.behavior.standardDescription)
                .foregroundStyle(Color.siloSecondaryText)
        }
        .listRowBackground(Color.siloGroupedCell)
    }

    private var advisoryAgeSection: some View {
        Section {
            Toggle(
                "Show Advisory Age",
                isOn: Binding(
                    get: { advisoryAgePreference.isOn },
                    set: { value in
                        Task { await advisoryAgePreference.setOn(value) }
                    }
                )
            )
            .foregroundStyle(Color.siloOnSurface)
            .tint(.siloSwitchOn)
            .disabled(advisoryAgePreference.isSaving)
        } header: {
            Text("Ratings")
                .foregroundStyle(Color.siloSecondaryText)
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Show a suggested minimum viewer age, such as Common Sense Media’s, on movie and show details. This does not change what the profile may watch.")
                if let writeError = advisoryAgePreference.writeError {
                    Text(writeError)
                }
            }
            .foregroundStyle(Color.siloSecondaryText)
        }
        .listRowBackground(Color.siloGroupedCell)
    }

    private var featuredAdultSection: some View {
        Section {
            Toggle(
                "Show Adult Titles in Featured",
                isOn: Binding(
                    get: { !featuredAdultLocked && featuredAdultPreference.isOn },
                    set: { value in
                        Task { await featuredAdultPreference.setOn(value) }
                    }
                )
            )
            .foregroundStyle(Color.siloOnSurface)
            .tint(.siloSwitchOn)
            .disabled(featuredAdultLocked || featuredAdultPreference.isSaving)
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                if featuredAdultLocked {
                    Text("This profile’s rating limit is set by the household manager.")
                } else {
                    Text("Let titles rated 18 or over appear in Featured on Home. Browse and search are not affected.")
                }
                if let writeError = featuredAdultPreference.writeError {
                    Text(writeError)
                }
            }
            .foregroundStyle(Color.siloSecondaryText)
        }
        .listRowBackground(Color.siloGroupedCell)
    }
}
#endif
