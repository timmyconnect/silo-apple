# Quickstart: macOS Sidebar and Charcoal Shell

## Build and run

Follow `docs/mac-builder.md` host routing. On a Mac with Xcode, from `iosApp/`:

```sh
xcodegen generate
```

```sh
xcodebuild build -project Silo.xcodeproj -scheme SiloMac -destination "platform=macOS,arch=arm64" -configuration Debug -derivedDataPath build/DerivedData
```

```sh
open build/DerivedData/Build/Products/Debug/Silo.app
```

A `CODE_SIGNING_ALLOWED=NO` build is compile-only evidence and must not be used for the
signed-in walk-through.

## Unit tests

There is no Mac test bundle; the model tests run under the iOS `SiloTests` bundle. Replace
the destination with an installed iOS simulator.

```sh
xcodebuild test -project Silo.xcodeproj -scheme Silo -destination "platform=iOS Simulator,name=<simulator>" -only-testing:SiloTests/MacSidebarSectionsTests -only-testing:SiloTests/UICustomizationPreferencesTests
```

## Manual validation

Sign in with a profile that has at least three libraries.

**US1 — Libraries**

1. The sidebar shows Home, then a "Libraries" heading with every library by name, in server
   order, with media-type icons.
2. Click a library: its page opens, only that row is highlighted, and the page title has no
   chevron or picker.
3. Collapse "Libraries", quit, relaunch: it is still collapsed.
4. Switch to a profile with no libraries: there is no Libraries heading.
5. With a profile that hides audiobooks: audiobook libraries are not listed.

**US2 — Groups, Search, profile, chrome**

1. Order is Home / Libraries / Discover (Search, For You, Calendar) / Your Stuff (Downloads,
   only if downloads are enabled).
2. Click Search, then press ⌘K from Home: Search opens and its row is highlighted.
3. The profile row at the bottom opens Settings / Switch Profile / Switch Server / Sign Out.
4. Open Settings: no sidebar row is highlighted. Click Home: Home opens and is highlighted.
5. On every root page there is one sidebar toggle (title bar) and no in-page search or
   profile control.
6. Rearrange the Primary Menu in Settings › Interface: Discover order follows; the
   Libraries group does not change.

**US3 — Charcoal**

1. Visit Home, a library, Search, For You, Calendar, Downloads, Settings root, General,
   Interface, Playback, Subtitles, Downloads settings, and Open Source Licenses: all share
   one content colour, and the sidebar is a distinct shade with no border line.
2. Open a series detail page: no content is hidden behind the sidebar (feeds research R6).
3. Run the iOS app in a simulator and check Home and Settings: unchanged.
