# Feature Specification: macOS Desktop Styling

**Feature Branch**: `feat/macos-styling`
**Created**: 2026-10-05
**Status**: Implemented on `feat/macos-styling`; not yet submitted
**Input**: User description: "Bring the Mac app's styling in line with the web interface, using
web's charcoal background, starting with the sidebar."

Reference captures: `iosApp/build/screenshots/` (`silo-mac-*.jpg` for the current Mac app,
`web-*.webp` for the live web interface).

**Scope note (2026-10-05)**: this spec began as the sidebar and charcoal shell (User
Stories 1–3). Refinement in the running app added User Stories 4–9, which are written up
below as built. Each story maps to one pull request; see plan.md.

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

---

### User Story 4 - Featured sections as a hero (Priority: P2)

A Home section the server marks as featured appears as a hero, as it does on web: the
current title's backdrop, logo, facts, synopsis, and Play and More Info, with the section's
titles listed along the bottom and the current one outlined.

**Why this priority**: the Mac drew the section as a plain row under its raw server name,
which read as a bug.

**Independent Test**: with a featured section configured on the server, Home opens on a
hero; clicking a title in its list brings that title up.

**Acceptance Scenarios**:

1. **Given** a featured section first on Home, **When** Home opens, **Then** the hero fills
   the window down to the next row's heading and the section's own name is not shown.
2. **Given** the hero, **When** the user clicks another title in its list, **Then** the
   hero shows that title and the outline moves to it.
3. **Given** the hero and the pointer elsewhere, **When** time passes, **Then** it advances
   to the next title; it pauses under the pointer and with Reduce Motion on.
4. **Given** a title with no logo artwork, **When** it is shown, **Then** its name appears
   as text.

---

### User Story 5 - Cards, headings, and captions sized for a desktop (Priority: P2)

Posters, stills, and episode thumbnails are sized for a Mac window, grids fit as many cards
as the window holds, and headings and captions are large enough to read at that size.

**Independent Test**: a library grid fills the window width with evenly spaced cards, and
resizing the window changes the number of columns.

**Acceptance Scenarios**:

1. **Given** a library grid, **When** the window is widened, **Then** more cards fit per row
   at the same card size.
2. **Given** a row of cards with captions of different lengths, **When** displayed,
   **Then** the artwork in the row shares one top edge.
3. **Given** the Poster Size setting, **When** it is changed, **Then** cards scale from the
   Mac's base size.

---

### User Story 6 - Detail page laid out for a desktop (Priority: P2)

A movie or series page shows its backdrop across the full width, the poster on the leading
side, and the title, facts, synopsis, playback options, and actions beside it. Seasons are
poster cards. No part of the page sits under the sidebar.

**Independent Test**: open a series; the poster, logo, all actions, and every season are
visible beside the sidebar, and selecting a season card changes the episode list.

**Acceptance Scenarios**:

1. **Given** a detail page, **When** it opens with the sidebar showing, **Then** nothing is
   hidden behind the sidebar and the backdrop has no hard edge beside it.
2. **Given** a series, **When** the user clicks a season card, **Then** it is outlined and
   its episodes are listed.
3. **Given** the action row, **When** displayed, **Then** More looks like the other actions
   and opens its menu.

---

### User Story 7 - A player that owns the window (Priority: P2)

Starting playback hides the sidebar and centres the picture in the window. The title and
format line sit in the window's title bar beside the back button, and the transport
controls are centred in the control bar.

**Independent Test**: resume an episode; the sidebar hides, the picture is centred, and
going back restores the sidebar.

**Acceptance Scenarios**:

1. **Given** the sidebar showing, **When** playback starts, **Then** the sidebar hides, and
   returns when the user leaves the player.
2. **Given** the sidebar already hidden, **When** the user leaves the player, **Then** it
   stays hidden.
3. **Given** the player, **When** controls are showing, **Then** the title and format are
   in the title bar and no second close button is drawn over the picture.

---

### User Story 8 - Settings that fit a desktop window (Priority: P3)

Settings pages sit in a centred column with monochrome icons and switches, the Downloads
settings form lays out as grouped cards, and the app menu has a Settings item.

**Independent Test**: open Settings from the app menu; each page's rows sit in the column
and no row band runs under the sidebar.

**Acceptance Scenarios**:

1. **Given** any settings page, **When** displayed, **Then** labels and controls sit in one
   centred column.
2. **Given** the app menu, **When** the user chooses Settings… or presses ⌘,, **Then**
   Settings opens.
3. **Given** help text that named taps, a remote, or a Downloads tab, **When** shown on the
   Mac, **Then** it uses Mac wording.

---

### User Story 9 - The window reopens where it was (Priority: P3)

The main window reopens on the display it was last used on, or at the same size on the
primary display when that display is gone.

**Independent Test**: move the window to a second display, quit, and relaunch.

**Acceptance Scenarios**:

1. **Given** the window was on a second display, **When** the app relaunches with that
   display connected, **Then** the window opens there at the same frame.
2. **Given** that display is disconnected, **When** the app relaunches, **Then** the window
   opens at the same size, centred on the primary display.

### Edge Cases

- No library list known (a profile with none, or nothing cached and a failed fetch): the
  group shows one "Libraries" row, whose page loads the list and reports the empty state.
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

- **FR-013**: A Home section flagged as featured MUST render as a hero on the Mac, and its
  section name MUST NOT be shown as a row heading.
- **FR-014**: The hero MUST show a title's logo artwork when the server supplies one and
  its name otherwise.
- **FR-015**: The Mac MUST use its own card sizes and caption styles through theme tokens,
  and poster grids MUST fit the window width.
- **FR-016**: Detail pages MUST lay out beside the sidebar, never under it.
- **FR-017**: The player MUST hide the sidebar for the length of playback and restore the
  state it found.
- **FR-018**: Settings pages MUST sit in a centred column, and the app menu MUST offer
  Settings with the ⌘, shortcut.
- **FR-019**: The main window MUST reopen at its last frame when a connected display covers
  it, and on the primary display otherwise.
- **FR-020**: The Mac MUST keep Silo's own branding and take no logo, name, or accent from
  server branding settings (Silo-Server/silo-server#1226, AC2).

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

## Known gaps

- A Mac list draws section footers on one line, so the longest settings help text is cut
  short. Fixing it means moving Settings off `List`.
- A long settings page scrolls only with the pointer over its column.
- With the sidebar hidden there is no on-screen search or profile control; ⌘K and ⌘, work.
- Colours (`#1A1A1C` canvas, `#121214` sidebar) are estimates from web captures.
- Pushed pages still show "Silo" as their window title.
- iPhone, iPad, and Apple TV still draw featured sections as rows.

## Independent review (2026-10-05)

A separate reviewer read the complete `main..mac/9-settings` diff through git, without
building, looking for defects. It reported 1 possible blocker, 2 major and 9 minor findings.

- Fixed: Settings from the menu could be pushed over the player; the custom switch had no
  accessible name; the hero's Play opened the detail page for a series; the hero's index
  could go stale after a reload and did not pause for VoiceOver; the search shortcut lived
  only in the sidebar; window frame saving missed some resizes and could resize a
  full-screen window; the sidebar could lose every way into libraries; the season row's
  alignment change reached iOS; `MacTitleLogo` did not import Nuke (it built regardless).
- Accepted, not changed: Settings… is enabled but inert before sign-in; a featured section
  shown as a hero has no per-title context menu; the router's route mirror, the player's
  sidebar restore, the hero's stepping, and window geometry have no unit tests (there is
  no Mac test target); a few layout literals remain.

## Verification status (2026-10-05)

- Full iOS suite on the final code: 2527 tests, 0 failures on a fresh iPhone 17 Pro
  simulator. On an iPad simulator signed in to a live server, five tests fail (three in
  `HorizontalMediaRailTests`, one each in `ArtworkURLTests` and `ImageSizeCapabilityTests`);
  the same five fail on `main` there.
- tvOS did not build until the Mac sidebar layout was moved under an explicit macOS check
  (it sat in the `#else` of an iOS check). Mac, iOS, and tvOS now build at every branch in
  the chain. The tvOS app was not run, and its tests were not run.
- Seen working on the Mac: sidebar, Search and highlight, profile menu, charcoal on every
  page, hero selection and auto-advance, card sizes and grid, series and movie detail,
  season selection, More menu, player sidebar hide and restore, Settings pages, window
  placement on a second and a missing display, a 1000×640 window.
- Not verified: a widescreen title and full screen in the player, an audiobook detail page,
  the hero's Play button, a title with no artwork, iPhone on screen, Apple TV past sign-in,
  clicking a settings switch.

## Clarifications

### Session 2026-10-05

- Q: Where does the sidebar's library list come from? → A: Option A — always every library
  the profile can open, in server order; Primary Menu still governs the other items.
- Q: Keep the icon rail (former User Story 4) in this feature? → A: No — deferred to its own
  spec. "Your Stuff" is Downloads only, and the profile menu keeps Requests.
