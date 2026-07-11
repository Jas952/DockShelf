# Release Preparation

DockShelf is currently prepared as a local release candidate only. Nothing is published by the repository scripts.

## Local Candidate

Create a fresh release bundle:

```bash
./script/package_release.sh
```

The script stages:

```bash
release/DockShelf-1.0/DockShelf.app
release/DockShelf-1.0-macOS-arm64.zip
release/DockShelf-1.0-macOS-arm64.dmg
```

The staged bundle includes the release binary, app icon, onboarding demo resource, and production `Info.plist`.

Release builds use `com.dmitriy.DockShelf` by default. Development builds use `local.codex.DockShelf.dev`.

By default the script applies an ad hoc local signature. To sign with Developer ID, pass a signing identity:

```bash
SIGN_IDENTITY="Developer ID Application: Example, Inc. (TEAMID)" ./script/package_release.sh
```

## Verification

Before approving a real release:

1. Run `./script/package_release.sh`.
2. Launch `release/DockShelf-1.0/DockShelf.app`.
3. Verify onboarding, menu bar commands, settings, app launching, autostart, hotkey, and panel positioning.
4. Confirm the About window version.
5. Sign with a Developer ID certificate.
6. Notarize with Apple and staple the ticket.
7. Package into the final distribution format.

## Current Status

- Release artifacts: local only and ignored by Git.
- Code signing: ad-hoc by default; Developer ID signing is available when an identity is supplied.
- Notarization: not configured.
- Publishing: intentionally not performed by scripts.
