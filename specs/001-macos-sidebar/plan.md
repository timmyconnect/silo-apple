# Implementation Plan: macOS Sidebar and Charcoal Shell

**Branch**: `feat/macos-styling` | **Date**: 2026-10-05 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-macos-sidebar/spec.md`

## Summary

Replace the Mac's flat sidebar with a grouped, Mac-only sidebar (Home / Libraries /
Discover / Your Stuff + pinned profile row) that lists every library the profile can open,
makes Search a selectable destination, and highlights the row that matches the page in view.
Remove the duplicated in-page toggle/search/profile chrome on Mac by cutting it at the two
shared components it comes from. Give the Mac one charcoal page canvas and a distinct sidebar
shade through platform-branched theme tokens. The detail-page icon rail is deferred to its own
spec after a short layout spike (see research.md R6).

Approach: a new `MacSidebar` view under `iosApp/iosApp/macOS/` fed by a pure,
platform-neutral sections function in `Navigation/`; the shared iPad `sidebarList` is
untouched. Existing `destinationContent(for:)`, `LibrariesTabView(fixedLibraryId:)`,
selection-resolution helpers, and `ProfileAvatarMenu` are reused as-is.

## Technical Context

**Language/Version**: Swift 5, SwiftUI (project.yml target `SiloMac`)
**Primary Dependencies**: SwiftUI `NavigationSplitView`, `List(selection:)`, `Section(_:isExpanded:)`; no new packages
**Storage**: `UserDefaults.standard` via `@AppStorage` for collapsed-group state (per device)
**Testing**: XCTest in `iosApp/Tests/`, run under the iOS `SiloTests` bundle (there is no Mac test target). Rendered checks on the Mac for each story.
**Target Platform**: macOS 26.0 (`iosApp/project.yml:4-7`); iOS 18 / tvOS 26 unchanged
**Project Type**: desktop app shell inside a multi-platform SwiftUI codebase
**Performance Goals**: n/a — the sidebar is at most ~25 static rows
**Constraints**: no server/Android change; Primary Menu setting read, never written (FR-002, FR-012); iOS/iPadOS/tvOS unchanged (FR-011); no hand-edits to `.xcodeproj`
**Scale/Scope**: one shell view (`MainTabView`), 1 new view file, 1 new model file, 1 new test file, about 7 small edits to existing files

## Constitution Check

| Principle | Result | Note |
|---|---|---|
| I. Client-only, coordinated | PASS | Mac only. The library list comes from the existing `/user/libraries` snapshot (`ContentView.swift:2227-2250`); Primary Menu is read via `uiCustomization.primaryMenu` and never written. No `silo-server` / `silo-android` change; state this in the PR. |
| II. Platform code in platform folders | PASS | New view in `iosApp/iosApp/macOS/MacSidebar.swift`; shared-file edits sit behind `#if os(macOS)`. The sections/highlight model lives in `Navigation/MacSidebarSections.swift` without a platform guard so `SiloTests` (iOS host) can compile it; it has no behaviour on iOS. `project.yml` globs `iosApp/` by path, so new files need only `xcodegen generate`. |
| III. Styling from shared tokens | PASS | New colours are a macOS branch of `Color.siloPageCanvas` plus a new `siloSidebarCanvas` in `Theme/Colors.swift`; sidebar widths move from the literals at `ContentView.swift:2725` into `SiloTheme`. Group headings use the existing `.siloCaption`. |
| IV. Evidence before claims | PASS | Pure functions get focused XCTests; each story has a rendered Mac check in quickstart.md. |
| V. Smallest change, one concern | PASS | One PR per story. Reuses `destinationContent`, `resolvedVisibleMainTabDestination`, `LibrariesTabView(fixedLibraryId:)`, `ProfileAvatarMenu`, `settingsListChrome()`. No new protocols or configuration. |

Re-check after Phase 1: no violations; Complexity Tracking left empty.

## Project Structure

### Documentation (this feature)

```text
specs/001-macos-sidebar/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── tasks.md              # /speckit-tasks output, not created here
```

No `contracts/`: this feature has no API or wire-format surface.

### Source Code (repository root)

```text
iosApp/iosApp/
├── ContentView.swift                        # MainTabView: macSidebarLayout (2718-2729) swaps to MacSidebar;
│                                            #   visibleDestinations (2532-2547) gets a macOS branch;
│                                            #   drop the \.sidebarToggle injection (2638-2639)
├── Navigation/
│   └── MacSidebarSections.swift             # NEW: pure model — sections, library icon, highlight rule
├── macOS/
│   └── MacSidebar.swift                     # NEW: grouped List, profile row, ⌘K, collapsed-state storage
├── Components/
│   └── TabTopBarActions.swift               # body → EmptyView on macOS; ProfileAvatarMenu made internal
├── Screens/Browse/LibrariesTabView.swift    # canSwitch: false on macOS (line 346)
├── Theme/
│   ├── Colors.swift                         # macOS branch for siloPageCanvas; new siloSidebarCanvas
│   └── SiloTheme.swift                      # macSidebarMinWidth / IdealWidth / MaxWidth tokens
├── Extensions/ViewExtensions.swift          # SiloPageBackdrop: #elseif os(macOS) flat canvas (line 38)
├── Screens/Settings/
│   ├── SettingsBackdrop.swift               # macOS → SiloPageBackdrop
│   ├── SettingsView.swift                   # macOSBody: .settingsListChrome() (line 74)
│   ├── InterfaceCustomizationView.swift     # lines 330, 623: macOS → .settingsListChrome()
│   └── OpenSourceAcknowledgementsView.swift # line 91: macOS → .siloPageBackground()
└── Downloads/DownloadsView.swift            # line 51: macOS → .siloPageBackground()

iosApp/Tests/
└── MacSidebarSectionsTests.swift            # NEW
```

**Structure Decision**: Keep everything inside the existing single source tree. Mac-only UI
goes under `macOS/`; the testable model goes under `Navigation/` beside `TabRouter.swift`
and `UICustomizationPreferences.swift`, which already hold the cross-platform menu
projection it builds on. No new targets, folders, or packages.

## Complexity Tracking

None — the Constitution Check has no violations.

## PR split (one concern each)

1. `feat(macos): list every library in a grouped sidebar` — US1 plus the grouping, Search,
   and highlight half of US2 (they share the new List). Files: MacSidebarSections,
   MacSidebar, ContentView, LibrariesTabView, SiloTheme, tests.
2. `feat(macos): move profile to the sidebar and drop duplicate page chrome` — the rest of
   US2. Files: MacSidebar (profile row), TabTopBarActions, ContentView (remove toggle env).
3. `feat(macos): charcoal page and sidebar canvas` — US3. Files: Colors, ViewExtensions,
   SettingsBackdrop, SettingsView, InterfaceCustomizationView,
   OpenSourceAcknowledgementsView, DownloadsView, MacSidebar (background).

## Owner decisions (2026-10-05)

1. US4 (icon rail) is deferred to its own spec; research.md R6 holds the spike notes.
2. "Your Stuff" is Downloads only.
3. The profile menu keeps "Requests" when the server enables it.
4. Colour values (`#1A1A1C` canvas, `#121214` sidebar) are placeholders to tune against the
   web capture in PR 3.
