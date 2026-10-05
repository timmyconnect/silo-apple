# Data Model: macOS Sidebar

All types are in-memory view models; nothing is synced, and only the collapsed flags persist.

## MainTabDestination (existing, reused)

`ContentView.swift:2035-2067`. Fields: `id: MainTabDestinationID`, `title`, `icon`,
`selectedIcon`. Library rows use `.library(id:label:icon:selectedIcon:)` with a media-type
icon (see below).

## MainTabDestinationID (existing, reused)

`ContentView.swift:2029-2033`: `.app(AppTab)`, `.libraryCategory(PrimaryMenuBuiltin)`,
`.library(Int)`. On Mac only `.app(...)` and `.library(Int)` are produced;
`.libraryCategory` never appears.

## MacSidebarSection (new, `Navigation/MacSidebarSections.swift`)

| Field | Type | Rule |
|---|---|---|
| `id` | `enum MacSidebarSectionID { home, libraries, discover, yourStuff }` | fixed order |
| `title` | `String?` | nil for `home`; "Libraries" / "Discover" / "Your Stuff" otherwise |
| `isCollapsible` | `Bool` | false for `home`, true for the rest (FR-003) |
| `items` | `[MainTabDestination]` | never empty — a section with no items is not emitted |

Builder: `macSidebarSections(destinations:libraries:showAudiobooks:) -> [MacSidebarSection]`

- `home`: `[.app(.home)]`.
- `libraries`: `libraries.filter { showAudiobooks || !$0.isAudiobookLibrary }` in input
  (server) order, mapped to `.library(...)`. Ignores Primary Menu pins (FR-002).
- `discover`: `.app(.search)` first, then `.app(.recommendations)` / `.app(.calendar)` in
  the order they appear in `destinations` (Primary Menu governs).
- `yourStuff`: `.app(.downloads)` if present in `destinations`.
- Anything else in `destinations` (`.app(.libraries)`, `.libraryCategory`, pinned
  `.library`) is dropped; the Libraries group covers it.

Helper: `macSidebarIcon(for: Library)` — movies, series, and audiobooks map to the existing
`PrimaryMenuBuiltin.navigationIcon` (`UICustomizationPreferences.swift:128-137`) via
`libraryMatchesPrimaryMenuCategory`; anything else uses `Library.navigationIcon`
(`Models.swift:1181-1187`).

## Selection state

| Name | Type | Owner | Rule |
|---|---|---|---|
| `selectedDestinationID` | `MainTabDestinationID` | `MainTabView` (existing, `ContentView.swift:2255`) | source of truth for the detail root |
| highlight | `MainTabDestinationID?` | derived: `macSidebarHighlight(selected:path:)` | nil when `router.path` contains a profile-menu route; else `selectedDestinationID` |
| `columnVisibility` | `NavigationSplitViewVisibility` | existing (`ContentView.swift:2266`) | unchanged in this feature |

Invariants: `selectedDestinationID` is always a member of the flattened Mac sections
(enforced by the existing `onChange` → `resolvedVisibleMainTabDestination` resets). When a
library is removed while selected, the selection becomes `.app(.home)`.

## Collapsed-state persistence

`UserDefaults.standard`, per device:

| Key | Type | Default |
|---|---|---|
| `mac.sidebar.librariesExpanded` | Bool | true |
| `mac.sidebar.discoverExpanded` | Bool | true |
| `mac.sidebar.yourStuffExpanded` | Bool | true |

## Profile row

Reuses `ProfileAvatarMenu` (`TabTopBarActions.swift:86-157`) with
`CurrentProfileStore.shared.profile`. Actions are the same closures pages pass today
(`HomeView.swift:160-169`): Settings, Requests (when the server enables it), Switch
Profile, Switch Server, Sign Out.
