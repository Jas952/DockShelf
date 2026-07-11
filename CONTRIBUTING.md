# Contributing to DockShelf

## Prerequisites

- macOS 13 or later
- Xcode Command Line Tools

DockShelf is a Swift Package with no third-party dependencies.

## Local Development

Build the package:

```bash
swift build
```

Build and launch the development application bundle:

```bash
./script/build_and_run.sh
```

The development bundle uses `local.codex.DockShelf.dev`, separate from the release bundle identifier. This prevents its preferences and launch-at-login agent from affecting a release installation.

## Before Opening a Pull Request

1. Keep changes scoped to the feature or fix.
2. Run `swift build`.
3. Run `./script/build_and_run.sh --verify`.
4. Manually check the affected menu, panel, and settings workflow.
5. Do not commit `dist/`, `release/`, `.build/`, or personal IDE configuration.

## Release Work

`script/package_release.sh` produces local `.app`, `.zip`, and `.dmg` artifacts. Distribution signing and notarization are intentionally separate from normal development; see [docs/releasing.md](docs/releasing.md).
