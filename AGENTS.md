# Repository Guidelines

## Project Structure & Module Organization

This repository contains a small native macOS SwiftUI app.

- `Sources/GateOpener/main.swift` contains the app entry point, SwiftUI window, Finder open handlers, drag-and-drop handling, and quarantine removal logic.
- `Info.plist` is the app bundle metadata template, including document type and Finder Services registration.
- `Makefile` builds and runs the `.app` bundle into `build/GateOpener.app`.
- `README.md` documents end-user build and usage steps.
- `build/` is generated output and should not be committed.

There is no dedicated test target or asset catalog yet.

## Build, Test, and Development Commands

- `make` builds `build/GateOpener.app` using `swiftc`.
- `make run` builds the app if needed, then opens it with macOS `open`.
- `make clean` removes generated build output.
- `./scripts/build-dev.sh` builds Debug configuration and launches the app.
- `./scripts/build-prod.sh 1.0.0` builds Release configuration, ad-hoc signs the app, and creates `build/GateOpener-1.0.0.zip`.
- `./scripts/release-github.sh 1.0.0` builds the production zip and publishes GitHub release tag `v1.0.0` to `cmer/gateopener` with the zip attached. Requires authenticated GitHub CLI (`gh auth login`).
- `plutil -lint build/GateOpener.app/Contents/Info.plist` validates the generated bundle plist after a build.

For a manual open-with smoke test, create a dummy `.app`, add quarantine, open it with GateOpener, then verify the attribute is gone:

```sh
mkdir -p /tmp/GateOpenerTest/Test.app
xattr -w com.apple.quarantine '0081;00000000;Test;00000000' /tmp/GateOpenerTest/Test.app
open -a "$PWD/build/GateOpener.app" /tmp/GateOpenerTest/Test.app
```

## Coding Style & Naming Conventions

Use Swift conventions: four-space indentation, `UpperCamelCase` for types, `lowerCamelCase` for properties/functions, and concise enum case names. Keep UI state on the main actor and keep file-system operations isolated in small helper functions. Prefer clear AppKit/SwiftUI APIs over shelling out, except where this app intentionally invokes `/usr/bin/xattr`.

No formatter or linter is configured. Match the existing style in `main.swift`.

## Testing Guidelines

There is currently no automated test suite. For changes, at minimum run `make clean && make`, lint the generated plist, launch the app, and smoke-test both supported inputs:

- Drag a `.app` bundle onto the window.
- Use Finder-style open handling with `open -a build/GateOpener.app Some.app`.

If adding tests later, prefer focused Swift tests for URL validation and quarantine command result handling.

## Commit & Pull Request Guidelines

The repository has only an initial commit, so no strict commit convention is established. Use short imperative commit subjects, for example `Add Finder open-with support`.

Pull requests should include a brief description, verification commands run, and screenshots or screen recordings for visible UI changes. Note any macOS version assumptions, Finder registration behavior, or security-sensitive behavior changes.

## Changelog Guidelines

Keep `CHANGELOG.md` updated with notable user-facing changes. Follow the existing Keep a Changelog style and group entries under the same headings used by PhotoProof:

- `Features` for new user-visible behavior.
- `Bug Fixes` for bug fixes.
- `Performance` for optimizations users will notice.
- `Refactor` for non-behavioral code changes worth recording.
- `Documentation` for README, comments, and contributor guidance.
- `Build` for build scripts, release scripts, and app bundle configuration.
- `Chores` for dependency bumps and housekeeping.
- `Other` for notable changes that do not fit a recognized category.

Use Conventional Commit-style wording as the source for changelog entries when possible, and write entries as user-readable release notes. Add new versions above older versions. Until this repo has automated changelog tooling, update `CHANGELOG.md` by hand in the same change that introduces the notable behavior or release prep.

## Release Guidelines

Production releases are zip files hosted on GitHub Releases at `cmer/gateopener`. Run `./scripts/build-prod.sh <version>` locally first, smoke-test `build/GateOpener.app`, then publish with `./scripts/release-github.sh <version>`. Tags use the `v<version>` pattern, for example `v1.0.0`. Set `GH_REPO=owner/name` to publish elsewhere.

## Security & Configuration Tips

GateOpener is intentionally unsandboxed so it can remove extended attributes from dropped or opened apps. Keep the accepted input limited to `.app` bundles and avoid broadening file handling without a clear reason.
