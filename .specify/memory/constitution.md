# Silo Apple Constitution

## Core Principles

### I. Client-Only Scope, Coordinated Behaviour

This repository owns the iOS, tvOS, and macOS clients and nothing else. Server concerns
(API contracts, auth/session behaviour, migrations) MUST NOT be forced into this repo. A
change that touches auth, API models, playback/session state, library browsing, metadata
display, or any server-synced preference MUST state whether `silo-server` and
`silo-android` need a coordinated change.

Rationale: the clients share synced state and contracts; a one-sided change breaks the others.

### II. Platform Code Lives In Platform Folders

Platform-specific code MUST sit under the existing `iOS`, `tvOS`, or `macOS` folders or
behind an explicit platform conditional in shared code. `iosApp/project.yml` is the source
of truth for project structure; generated `.xcodeproj` files MUST NOT be hand-edited.
Existing bundle IDs and keychain groups MUST be preserved.

Rationale: three targets compile one source tree; unscoped changes leak across platforms.

### III. Styling Comes From Shared Tokens

Spacing, radii, card sizes, type styles, colours, and durations MUST come from the shared
theme (`SiloTheme`, `Typography`, `Colors`, named colour assets). A platform that needs a
different value MUST get its own token branch, not a literal at the call site. New
hardcoded styling literals in view code require a stated reason.

Rationale: per-platform tuning is only possible when values have one home.

### IV. Evidence Before Claims

Visual changes MUST be verified with a rendered check on the affected platform; behaviour
changes get a focused regression test when it meaningfully protects the change. A build
with `CODE_SIGNING_ALLOWED=NO` is compile-only evidence and MUST NOT be installed for an
authenticated run. tvOS focus work MUST follow `docs/tvos-focus.md`.

Rationale: three platforms and a generated project make "it compiles" weak evidence.

### V. Smallest Change, One Concern

Reuse existing helpers and components before adding new ones. Each pull request carries
one concern; independent changes are split. No speculative abstractions or configuration.

Rationale: small, single-purpose changes are reviewable and reversible.

## Security & Configuration

Local signing overrides MUST NOT be committed; start from
`iosApp/Signing/Local.xcconfig.sample`. App Store Connect keys, Match repo URLs, team
identifiers, and any other secret stay in environment variables only and never enter a
commit, a log, or a build setting.

## Development Workflow

- Regenerate the project with `xcodegen generate` after target or source layout changes.
- Build and run through the `mac-builder` routing described in `docs/mac-builder.md`.
- Pull requests are created only on explicit request, use a Conventional Commit title,
  open with the problem, include before-and-after images for UI changes, and end with the
  AI disclosure. PR-only assets are uploaded to GitHub, never committed.
- Human-facing writing leads with the outcome and uses plain, concrete language.

## Governance

This constitution summarises `CLAUDE.md` / `AGENTS.md`; where they conflict, those files
win and this document is amended to match. Amendments are made by pull request, state the
reason, and bump the version: MAJOR for a removed or redefined principle, MINOR for a new
principle or section, PATCH for wording. Every plan produced under `.specify/` MUST include
a constitution check against Principles I–V.

**Version**: 1.0.0 | **Ratified**: 2026-10-05 | **Last Amended**: 2026-10-05
