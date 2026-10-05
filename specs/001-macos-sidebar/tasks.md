# Tasks: macOS Sidebar and Charcoal Shell

**Input**: Design documents from `/specs/001-macos-sidebar/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Focused XCTests for the pure sidebar model only (research.md R8); visuals are
verified by rendered checks on the Mac.

**Organization**: One phase per pull request. PR 1 carries US1 and the part of US2 that
shares the new list; PR 2 finishes US2; PR 3 is US3.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependencies)
- Paths are relative to `iosApp/`

## Phase 1: Setup

- [x] T001 Confirm the baseline: `xcodegen generate`, build `SiloMac`, and keep the
      "before" captures in `build/screenshots/` for the PR descriptions.

## Phase 2: PR 1 — Grouped sidebar with every library (US1 + US2 grouping) 🎯 MVP

**Goal**: every library is one click away under "Libraries"; the sidebar is grouped;
Search is a destination; the highlight follows the page in view.

**Independent Test**: quickstart.md, US1 steps 1–5 and US2 steps 1, 2, 4, 6.

- [x] T002 [P] [US1] Add `MacSidebarSectionID`, `MacSidebarSection`,
      `macSidebarSections(destinations:libraries:showAudiobooks:)`, and
      `macSidebarIcon(for:)` in `iosApp/Navigation/MacSidebarSections.swift`
      (data-model.md).
- [x] T003 [P] [US2] Add `macSidebarHighlight(selected:path:)` in the same file
      (research.md R2).
- [x] T004 [P] [US1] Add `Tests/MacSidebarSectionsTests.swift` covering research.md R8
      cases 1–6.
- [x] T005 [P] [US1] Add `macSidebarMinWidth` / `macSidebarIdealWidth` /
      `macSidebarMaxWidth` to `iosApp/Theme/SiloTheme.swift`, replacing the literals at
      `ContentView.swift:2725`.
- [x] T006 [US1] Create `iosApp/macOS/MacSidebar.swift`: sectioned `List(selection:)`
      with collapsible headers bound to the three `@AppStorage` keys, and a hidden ⌘K
      shortcut that selects Search (depends on T002, T003).
- [x] T007 [US1] In `iosApp/ContentView.swift`, add the macOS branch of
      `visibleDestinations` that returns the flattened Mac sections, and make
      `macSidebarLayout` use `MacSidebar` (depends on T006).
- [x] T008 [US1] In `iosApp/Screens/Browse/LibrariesTabView.swift`, pass
      `canSwitch: false` on macOS so the picker is no longer offered (FR-008).
- [x] T009 [US1] `xcodegen generate`, build `SiloMac`, run the model tests, and do the
      rendered check; confirm iPad and iPhone navigation is unchanged in a simulator.

**Checkpoint**: PR 1 is shippable on its own.

## Phase 3: PR 2 — Profile in the sidebar, no duplicate page chrome (rest of US2)

**Goal**: the profile row sits at the bottom of the sidebar; pages show no toggle, search,
or profile control of their own.

**Independent Test**: quickstart.md, US2 steps 3 and 5.

- [x] T010 [US2] Make `ProfileAvatarMenu` internal and return `EmptyView()` from
      `TabTopBarActions.body` on macOS in `iosApp/Components/TabTopBarActions.swift`.
- [x] T011 [US2] Add the pinned profile row to `iosApp/macOS/MacSidebar.swift`, reusing
      `ProfileAvatarMenu` with the same action closures pages pass today (depends on T010).
- [x] T012 [US2] Stop injecting `\.sidebarToggle` for the Mac layout in
      `iosApp/ContentView.swift` (research.md R3, edit 1).
- [x] T013 [US2] Build, rendered check on every root page, and confirm the iOS headers
      are unchanged.

## Phase 4: PR 3 — Charcoal shell (US3)

**Goal**: one charcoal canvas on every Mac page and a distinct sidebar shade.

**Independent Test**: quickstart.md, US3 steps 1–3.

- [x] T014 [P] [US3] Add the macOS branch of `siloPageCanvas` and the new
      `siloSidebarCanvas` in `iosApp/Theme/Colors.swift`.
- [x] T015 [US3] Make `SiloPageBackdrop` a flat canvas on macOS in
      `iosApp/Extensions/ViewExtensions.swift` and point `SettingsBackdrop` at it in
      `iosApp/Screens/Settings/SettingsBackdrop.swift` (depends on T014).
- [x] T016 [P] [US3] Use `.settingsListChrome()` on macOS in
      `Screens/Settings/SettingsView.swift:74` and
      `Screens/Settings/InterfaceCustomizationView.swift:330, 623`.
- [x] T017 [P] [US3] Use `.siloPageBackground()` on macOS in
      `Downloads/DownloadsView.swift:51` and
      `Screens/Settings/OpenSourceAcknowledgementsView.swift:91`.
- [x] T018 [US3] Give `MacSidebar` the sidebar canvas and the split view the window
      container background.
- [x] T019 [US3] Rendered check on every page in quickstart US3 step 1, tune the two
      colour values against `web-home-rows.webp`, open a detail page to confirm no content
      is newly hidden (research.md risk 2), and confirm iOS is unchanged.

## Phase 5: Added during refinement (US4–US9)

- [x] T020 [US4] Featured hero with title list and logo artwork (`macOS/MacFeaturedHero.swift`,
      `macOS/MacTitleLogo.swift`, `Screens/Home/HomeView.swift`).
- [x] T021 [US5] Mac card sizes, adaptive grids, caption and heading tokens
      (`Theme/SiloTheme.swift`, `Theme/Typography.swift`, `Components/AdaptiveLayout.swift`).
- [x] T022 [US6] Desktop detail header, season poster cards, More button
      (`Screens/Detail/Phone/`).
- [x] T023 [US7] Player: sidebar hidden, single header, centred transport (`macOS/PlayerView.swift`,
      `macOS/MacPlayerControls.swift`).
- [x] T024 [US8] Settings column, grouped forms, monochrome rows and switches, Settings menu
      item (`Screens/Settings/`, `macOS/MacSettingsCommand.swift`).
- [x] T025 [US9] Window placement (`macOS/MacWindowPlacement.swift`).
- [ ] T026 Verify the items listed as not verified in spec.md.
- [ ] T027 Independent review of the complete diff before any pull request is opened.

## Dependencies

- PR 1 → PR 2 → PR 3. PR 2 and PR 3 both edit `MacSidebar.swift`, so they stack.
- Within PR 1: T002–T005 are parallel; T006 needs T002 and T003; T007 needs T006.

## Out of scope

- Icon rail on detail pages (FR-010) — separate spec.
- Favorites / Watchlist as sidebar rows; card sizes; Home hero; detail and Settings layout.
