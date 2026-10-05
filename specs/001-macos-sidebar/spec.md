# Feature Specification: macOS Sidebar and Charcoal Shell

**Feature Branch**: `feat/macos-styling`
**Created**: 2026-10-05
**Status**: Draft
**Input**: User description: "Bring the Mac app's styling in line with the web interface, using
web's charcoal background, starting with the sidebar."

Reference captures: `iosApp/build/screenshots/` (`silo-mac-*.jpg` for the current Mac app,
`web-*.webp` for the live web interface).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reach any library from the sidebar (Priority: P1)

A Mac user sees their libraries listed by name in the sidebar under a "Libraries" heading
and opens one with a single click, the way the web interface works. Today the sidebar has
one "Libraries" item, and switching library means opening a modal picker sheet.

**Why this priority**: library switching is the most frequent navigation, and it currently
costs three clicks and a modal. It is also the largest visible gap between Mac and web.

**Independent Test**: sign in with a profile that has several libraries; every library the
profile can open appears under "Libraries", and clicking one shows that library's page
with its sidebar row highlighted.

**Acceptance Scenarios**:

1. **Given** a profile with access to 12 libraries, **When** the main window opens,
   **Then** all 12 appear by name under a "Libraries" heading, each with an icon matching
   its media type.
2. **Given** the sidebar is showing, **When** the user clicks a library, **Then** that
   library opens in the content area and its row is the only highlighted row.
3. **Given** the "Libraries" group is expanded, **When** the user collapses its heading,
   **Then** the library rows hide and the choice is remembered at next launch.
4. **Given** a library page is open, **When** the user looks for the old library picker
   sheet, **Then** it is no longer the way to switch libraries on the Mac.

---

### User Story 2 - Grouped sidebar with search and profile (Priority: P2)

The sidebar is organised into the same groups as web: Home at the top, "Libraries",
"Discover" (Search, For You, Calendar), and "Your Stuff" (Downloads). The signed-in profile sits at the bottom of the
sidebar and opens the profile menu. The second header inside each page, with its duplicate
sidebar toggle, search button, and profile control, is removed.

**Why this priority**: it removes duplicated chrome on every page and gives search and
profile a stable home, but the app is usable without it once Story 1 ships.

**Independent Test**: open each sidebar destination; the page shows no in-page sidebar
toggle, search button, or profile control, and all three are reachable from the sidebar or
window toolbar.

**Acceptance Scenarios**:

1. **Given** the main window, **When** the user views the sidebar, **Then** items appear
   under Home, Libraries, Discover, and Your Stuff in that order, with small caps group
   headings.
2. **Given** the sidebar, **When** the user clicks Search or presses the search shortcut,
   **Then** the search page opens and the Search row is highlighted.
3. **Given** the sidebar, **When** the user clicks the profile row at the bottom, **Then**
   a menu offers Settings, Switch Profile, Switch Server, and Sign Out, plus Requests when
   the server enables requests.
4. **Given** any top-level page, **When** it is displayed, **Then** exactly one sidebar
   toggle is visible in the window.
5. **Given** the user opens Settings or Search, **When** the page is displayed, **Then**
   the sidebar highlight reflects where the user is and no longer stays on Home.

---

### User Story 3 - Charcoal shell (Priority: P3)

The Mac window uses web's charcoal background, with the sidebar a slightly different shade
so the two regions read as separate surfaces. Every page uses the same background; no page
falls back to pure black or system grey.

**Why this priority**: it is the agreed visual baseline for the Mac restyle and fixes the
three different backgrounds seen across Settings pages, but it changes no behaviour.

**Independent Test**: visit every sidebar destination and every Settings page; the content
background is the same charcoal on all of them.

**Acceptance Scenarios**:

1. **Given** any page in the Mac app, **When** it is displayed, **Then** its background is
   the shared charcoal colour.
2. **Given** the sidebar and content area side by side, **When** viewed, **Then** the
   sidebar is visibly distinct from the content background without a hard border.
3. **Given** the iOS and tvOS apps, **When** this feature ships, **Then** their backgrounds
   are unchanged.

---

### Edge Cases

- A profile with no libraries: the "Libraries" group is omitted, not shown empty.
- A profile with more libraries than fit: the sidebar scrolls; the profile row stays pinned.
- A library is removed or access is revoked while its page is open: the row disappears and
  the app moves to Home.
- Audiobook libraries hidden by profile settings do not appear in the list.
- The server is unreachable at launch: the sidebar shows the last known libraries, or only
  the built-in destinations if none are cached.
- The window is narrowed to its minimum width: the sidebar collapses before content clips.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Mac sidebar MUST list each library the active profile can open as its own
  row under a "Libraries" group.
- **FR-002**: The Libraries group MUST show every library the active profile can open, in
  server order, regardless of what the synced Primary Menu setting pins. The Primary Menu
  setting continues to control the order and visibility of the other destinations.
- **FR-003**: The sidebar MUST group its rows as Home, Libraries, Discover, and Your Stuff,
  and each group other than Home MUST be collapsible with its state remembered per device.
- **FR-004**: Search MUST be a sidebar destination and MUST have a keyboard shortcut.
- **FR-005**: The active profile MUST appear at the bottom of the sidebar and open the
  existing profile menu actions.
- **FR-006**: Top-level pages on the Mac MUST NOT show their own sidebar toggle, search
  button, or profile control.
- **FR-007**: The highlighted sidebar row MUST match the page in view, including Search and
  pages reached from the profile menu, which highlight no navigation row.
- **FR-008**: The modal library picker MUST NOT be the way to switch libraries on the Mac.
- **FR-009**: All Mac pages MUST use one shared charcoal background, and the sidebar MUST
  use one shared, distinct sidebar shade.
- **FR-010**: Deferred to a separate feature (sidebar icon rail on detail pages).
- **FR-011**: iOS, iPadOS, and tvOS navigation and colours MUST be unchanged.
- **FR-012**: The feature MUST NOT change the format or meaning of any server-synced
  setting.

### Key Entities

- **Library**: a server-defined collection the profile can open; has a name, a media type,
  and an order.
- **Sidebar destination**: a row the user can select — a built-in page or a library.
- **Sidebar group**: a labelled, collapsible set of destinations.
- **Primary Menu setting**: the existing per-profile, cross-client preference for which
  destinations are pinned and in what order.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can switch from one library to any other in one click, down from three.
- **SC-002**: Every library the profile can open is visible in the sidebar without opening
  a picker.
- **SC-003**: Each top-level page shows exactly one sidebar toggle and no duplicate search
  or profile control.
- **SC-004**: All sidebar destinations and all Settings pages share one background colour.
- **SC-005**: Making the sidebar a solid shade hides no detail-page content that is visible
  today.
- **SC-006**: Side-by-side with the web interface, the Mac sidebar shows the same groups in
  the same order for the same account.
- **SC-007**: The iOS and tvOS apps look and navigate exactly as before.

## Assumptions

- The change is Mac only. iPad keeps its current sidebar even though it shares code with
  the Mac sidebar today.
- Charcoal applies to the Mac only; iOS and tvOS keep the pure black in
  `iosApp/DESIGN_LANGUAGE.md`. Exact colour values are matched to the web captures during
  planning.
- "Your Stuff" contains Downloads only, and only when downloads are enabled. Favorites and
  Watchlist are not top-level pages on the Mac today; adding them is a later feature, as
  are Watch Party, History, and Collections.
- Collapsing the sidebar to an icon rail on detail pages is a separate, later feature; it
  needs a layout spike first (see research.md R6).
- The Mac keeps Silo's own branding. Per Silo-Server/silo-server#1226 (AC2: "First-party
  clients do not adopt server branding"), the sidebar logo is the bundled Silo wordmark and
  the charcoal colours are fixed client tokens; nothing is read from a server's name, logo,
  or accent settings. Web is the reference for layout only.
- Titles keep the system typeface; web's display typeface is not adopted.
- Card sizes, the Home hero, the detail page layout, and Settings layout are separate,
  later features.
- No server or Android change is needed: the library list is derived on the Mac and the
  synced Primary Menu setting is read, never rewritten, by this feature.
- Library and media-type entries pinned in the Primary Menu setting are not shown a second
  time on the Mac; the Libraries group already covers them.

## Clarifications

### Session 2026-10-05

- Q: Where does the sidebar's library list come from? → A: Option A — always every library
  the profile can open, in server order; Primary Menu still governs the other items.
- Q: Keep the icon rail (former User Story 4) in this feature? → A: No — deferred to its own
  spec. "Your Stuff" is Downloads only, and the profile menu keeps Requests.
