# DockShelf Architecture

## Product Direction

DockShelf is a menu-bar utility with a global hotkey launcher.

The app has no Dock icon. It uses:

- `MenuBarExtra` for commands;
- a right-side sliding `NSPanel` launcher opened by `Option + Space`, menu bar, or a small bottom-right tab;
- a settings window for categories and app shortcuts;
- a startup welcome window;
- optional native Dock folder export.

## Launcher Strategy

The launcher is a non-activating floating `NSPanel` with SwiftUI content. It slides in from the right edge of the active screen. It uses `.regularMaterial`, a compact category list, and a grid of app icons.

A second tiny `NSPanel` provides the bottom-right arrow tab. The tab stays available without adding a Dock icon.

Apps are launched with `NSWorkspace`.

## Settings Strategy

Settings remain a normal SwiftUI window opened from the menu bar. Users can create categories and add any `.app` bundle from the filesystem.

## Welcome Strategy

On each app launch, `OnboardingWindowController` presents a compact SwiftUI welcome window. The app remains a background utility; closing or canceling the startup welcome terminates the app, while opening it manually from the menu bar only presents an informational window that can be dismissed without quitting.

## Optional Dock Stack Strategy

DockShelf can flatten configured apps into:

```bash
~/Applications/DockShelf Agents
```

The user can drag that folder into the right side of the Dock for native Stack/Fan/Grid behavior.

## Autostart Strategy

For this local SwiftPM-built app, login at launch is implemented with a per-user LaunchAgent:

```bash
~/Library/LaunchAgents/<bundle-id>.plist
```

For a signed, distributed app bundle, `SMAppService` would be the cleaner production route.

## Release Staging

`script/package_release.sh` builds the SwiftPM executable in release mode and stages a local `.app` bundle, ZIP archive, and DMG under `release/`. It applies an ad-hoc signature by default for local testing, or can use a supplied Developer ID signing identity. It does not notarize or publish the app.
