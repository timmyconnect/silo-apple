# Research: macOS Sidebar and Charcoal Shell

`file:line` citations were verified by reading the code on 2026-10-05 unless marked inferred.

## R1. Mac-only sidebar list vs parameterising the shared `sidebarList`

**Decision**: New `MacSidebar` view (`iosApp/iosApp/macOS/MacSidebar.swift`) used only from
`macSidebarLayout` (`ContentView.swift:2718-2729`). The shared
`sidebarList(dismissAfterSelection:nestsPinnedLibraries:)` (`ContentView.swift:2760-2793`)
and `iPadSidebarLayout` (2650-2682) are not touched.

**Rationale**: The Mac list needs sections, collapsible headers, a different data source
for libraries, a pinned footer, and a nil-able selection. Threading five more parameters
through the shared function would change its shape for iPad with no iPad benefit, and
FR-011 forbids iPad drift. A separate view is the smaller diff.

Data flows through the existing shell state: on macOS `visibleDestinations`
(`ContentView.swift:2532-2547`) gets a `#if os(macOS)` branch that returns the flattened
Mac sections instead of the Primary Menu projection, so `resolvedVisibleMainTabDestination`
(2184-2191), the three `onChange` resets (2386-2403), and `destinationContent(for:)`
(2874-2891 — `.library(id)` already maps to `LibrariesTabView(fixedLibraryId:)`) keep
working.

**Alternatives considered**: (a) Parameterise `sidebarList` — rejected above. (b) Build
sections inside `projectedMainTabDestinations` — rejected; it is the cross-client
projection and its tests assert Primary Menu order
(`UICustomizationPreferencesTests.swift:252-342`).

## R2. Selection and highlight model (FR-007)

**Finding**: `selectedDestinationID` is the sidebar selection. Search and Settings are
pushed routes (`router.navigate(to: .search/.settings)` from every page header —
`HomeView.swift:161-162`, `CalendarView.swift:121-122`, `RecommendationsView.swift:86-87`,
`LibrariesTabView.swift:348-349`), so the selection stays on Home. That is the observed bug.

**Decision**:
- Search becomes a Mac destination (`.app(.search)` in the Discover group). `AppTab.search`
  and `tabContent(for: .search)` already exist (`TabRouter.swift:11`,
  `ContentView.swift:2913-2918`).
- Highlight = `macSidebarHighlight(selected:path:) -> MainTabDestinationID?`: returns `nil`
  when `router.path` contains a profile-menu route (`.settings`, `.serverList`,
  `.requestsHub`, `.myRequests`, `.requestApprovals`, `.requestDetail`), otherwise
  `selectedDestinationID`. Detail routes (`.itemDetail`, `.personDetail`, `.browse`, …)
  keep the originating row lit.
- The List's selection binding getter uses that value; the setter calls the existing
  `selectSidebarDestination` (`ContentView.swift:2842-2845`), which pops to root first.
  Because the highlight is `nil` on Settings, clicking Home from Settings fires the setter
  with no special case.

**Rationale**: A pure function, unit-testable in `SiloTests`, with no change to `AppRouter`
or `Route`, which iOS and tvOS share.

**Alternatives considered**: Make Settings a destination too — rejected; FR-007 says
profile-menu pages highlight no row. Intercept `.search` pushes in `AppRouter` — rejected;
it is cross-platform code and unnecessary once the in-page search button is gone (R3). The
one remaining `.search` push on Mac is `BrowseView.swift:124`.

## R3. Suppress in-page toggle / search / profile on Mac (FR-006, FR-008)

**Decision** (three edits, no per-screen edits):
1. Stop injecting `\.sidebarToggle` in `macSidebarLayout` (`ContentView.swift:2638-2639`).
   `SidebarToggleButton` renders nothing when the environment value is nil and
   `reservesSidebarToggleSpace` is false (`SidebarToggleButton.swift:32-52`). This removes
   the in-page toggle on Home, Calendar, For You, Libraries, and the Downloads toolbar
   (`DownloadsView.swift:347-350`) at once. The system title-bar toggle stays, leaving
   exactly one.
2. `TabTopBarActions.body` → `EmptyView()` on macOS (`TabTopBarActions.swift:30`). This
   removes search and profile on all four root pages. Make `ProfileAvatarMenu`
   (`TabTopBarActions.swift:86`) internal so the sidebar profile row reuses it unchanged.
3. `LibrariesTopBar(canSwitch:)` → `false` on macOS (`LibrariesTabView.swift:346`), so the
   title stays but the chevron and picker are gone. `LibraryPickerSheet` stays for iOS.

**Alternatives considered**: An environment flag read by each screen — more edits, same
result. Deleting `SidebarToggleButton()` calls per screen — breaks iPad.

## R4. Where Favorites / Watchlist live; "Your Stuff" contents

**Finding**: `FavoritesView` and `WatchlistView` exist only as pushed `Route`s
(`ContentView.swift:2999-3002`); there is no `AppTab` or `MainTabDestinationID` for them.

**Decision**: "Your Stuff" = Downloads only (when `DownloadManager.shared.downloadsEnabled`,
the same gate as today at `ContentView.swift:2540-2545`); the group is omitted otherwise.
Favorites and Watchlist as top-level rows are deferred: making them destinations means
extending `MainTabDestinationID` / `AppTab`, which the iOS `TabView` and tvOS also consume.

**Alternatives considered**: Sidebar rows that `router.navigate(to: .favorites)` — rejected;
they would be unhighlightable pushed pages, the exact bug FR-007 fixes.

## R5. Charcoal shell through tokens (FR-009)

**Findings**:
- The Mac page canvas is `SiloPageBackdrop`'s non-iOS branch → `Color.siloBackground` =
  `#000000` (`ViewExtensions.swift:38-43`, `Colors.swift:7`). Home, Calendar, For You,
  Libraries, Search, Favorites, and Watchlist all use `.siloPageBackground()`.
- Settings root uses `.siloGroupedListStyle()` = `.listStyle(.inset)` on Mac
  (`SettingsView.swift:74`, `ViewExtensions.swift:211-212`) without hiding the scroll
  background → system grey. Same at `InterfaceCustomizationView.swift:330, 623`.
- Settings sub-pages use `settingsListChrome()` → `SettingsBackdrop` = `siloBackground`
  black (`SettingsListChrome.swift:5-9`, `SettingsBackdrop.swift:7`).
  `DownloadsView.swift:51` and `OpenSourceAcknowledgementsView.swift:91` paint
  `siloBackground` directly.
- The repo already separates "page canvas" from "black ink" (`siloPageCanvas` at
  `Colors.swift:118`). `siloBackground` has 66 non-tvOS call sites, several as ink or
  gradient stops, so it is not safe to re-colour.

**Decision**:
- `Colors.swift`: `siloPageCanvas` gets a macOS branch (placeholder `#1A1A1C`; iOS keeps
  `#111111`); add `siloSidebarCanvas` (placeholder `#121214`, macOS). Tune both against
  `web-home-rows.webp` during PR 3's rendered check.
- `SiloPageBackdrop`: `#elseif os(macOS)` → flat `Color.siloPageCanvas`.
- `SettingsBackdrop`: on macOS → `SiloPageBackdrop()`.
- `SettingsView.swift:74`, `InterfaceCustomizationView.swift:330, 623`: on macOS use
  `.settingsListChrome()`. iOS keeps `.siloGroupedListStyle()`.
- `DownloadsView.swift:51`, `OpenSourceAcknowledgementsView.swift:91`: macOS →
  `.siloPageBackground()`.
- `MacSidebar`: `.scrollContentBackground(.hidden).background(Color.siloSidebarCanvas)`.
  Apply `.containerBackground(Color.siloPageCanvas, for: .window)` on the split view so the
  title-bar strip matches (inferred as necessary; verify in the rendered check).

**Alternatives considered**: Re-colour `siloBackground` on Mac — rejected (it doubles as
ink). Per-screen `#if os(macOS) .background(...)` literals — violates Principle III.

## R6. Icon rail on detail routes (FR-010) — proposed split

**Findings**: macOS `NavigationSplitView` has no icon-rail mode. `silo-mac-detail.jpg`
shows detail content laid out under the translucent sidebar. Inferred, not verified:
macOS 26 layers the sidebar over the detail column, and the detail heroes ignore the top
safe area (`MovieDetailContent.swift:60`, `SeriesDetailContent.swift:93`,
`AudiobookDetailContent.swift:54`); the horizontal overlap suggests the hero or its
container also escapes the leading inset. An opaque sidebar (R5) would hide that content,
not fix it, so PR 3's rendered check must open a detail page.

**Decision**: Defer US4 to its own spec. Its first task is a short spike: (1) does the
overlap persist with an opaque sidebar; (2) does toggling
`navigationSplitViewColumnWidth(min:ideal:max:)` between a rail width and the full width
re-lay-out reliably on macOS 26 when driven by `router.path.last`. Fallback if dynamic
width is unreliable: on detail routes set `columnVisibility = .detailOnly` and restore on
pop, skipping the restore when the user had hidden the sidebar. That satisfies "no content
covered" and "restore on leave" but not "icons only" — a spec deviation for the owner.

**Alternatives considered**: A custom HStack rail replacing `NavigationSplitView` — loses
the system toggle, title bar, and resize behaviour; far larger than the story warrants.

## R7. Persisting collapsed group state (FR-003)

**Decision**: `@AppStorage("mac.sidebar.librariesExpanded") = true`,
`...discoverExpanded`, `...yourStuffExpanded` in `MacSidebar`, bound to
`Section(_:isExpanded:)`. Per device, not per profile, as the spec says.

**Rationale**: `@AppStorage` is the native mechanism; the app already keys local
preferences in `UserDefaults.standard` with a platform prefix
(`AppNavPreferences.swift:66-74` uses `mac.nav.`). Three Bools beat an encoded set for
three fixed groups.

**Alternatives considered**: `SharedDefaults` / `AppNavPreferences` — those are per-profile
and App-Group-mirrored for Top Shelf; unnecessary here.

## R8. Tests

**Existing**: `UICustomizationPreferencesTests.swift` covers
`projectedMainTabDestinations` and `resolvedVisibleMainTabDestination` (lines 252-560);
`MainTabLayoutSelectionTests.swift` covers only the iOS sidebar/tab policy. There is no Mac
test target.

**Decision**: Add `iosApp/Tests/MacSidebarSectionsTests.swift` (runs under `SiloTests`):
1. Every available library appears in Libraries in input order, whether the Primary Menu
   pins none, a subset, or media-type roots; no duplicates, no category rows.
2. The Libraries group is omitted when the list is empty; audiobook libraries drop when
   `showAudiobooks == false`.
3. Discover: Search first, then For You / Calendar in Primary Menu order; hidden when the
   menu hides them.
4. Your Stuff is present only when Downloads is in the input destinations.
5. `macSidebarHighlight`: nil for paths containing `.settings` / `.serverList` /
   `.requestsHub`; retained for `.itemDetail`; equals the selection for an empty path.
6. Removing a library from the snapshot resolves the selection to Home through the existing
   `resolvedVisibleMainTabDestination` with the Mac destination list.

Not added: UI or snapshot tests; rendered checks cover visuals per Principle IV.

## Risks

1. **US4 icon rail**: see R6.
2. **Opaque sidebar may hide detail content** (R5 + R6): if PR 3's rendered check shows
   hidden content, add a leading safe-area fix to the Mac detail content in that PR or
   hold PR 3 for the US4 spike.
3. **Primary Menu editor still offers library and category pins on Mac** that the Mac
   sidebar ignores, as FR-002 requires. Worth a note in Interface settings later.
4. **`Section(isExpanded:)` header styling** in a sidebar List may not match web's
   small-caps headings exactly; tune in PR 1's rendered check.
5. **⌘K via a hidden `Button().keyboardShortcut("k")`** fires only while the window is
   key; acceptable. Use `.commands` if it misbehaves.
