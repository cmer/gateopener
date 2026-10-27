# GateOpener Claude Notes

## Project Summary

GateOpener is a small native macOS SwiftUI app that removes Gatekeeper quarantine attributes from dropped or opened `.app` bundles. It intentionally remains unsandboxed so it can edit extended attributes on user-selected applications.

## Build And Verification

- Build locally with `make`.
- Run the app with `make run`.
- Clean generated output with `make clean`.
- Validate a built plist with `plutil -lint build/GateOpener.app/Contents/Info.plist`.
- For release-sensitive changes, run `make clean && make`, lint the generated plist, and smoke-test drag/drop or Finder open handling with a quarantined dummy `.app`.

Smoke-test command:

```sh
mkdir -p /tmp/GateOpenerTest/Test.app
xattr -w com.apple.quarantine '0081;00000000;Test;00000000' /tmp/GateOpenerTest/Test.app
open -a "$PWD/build/GateOpener.app" /tmp/GateOpenerTest/Test.app
```

## Signed GitHub Releases

Use the signed release script for public releases once Apple Developer signing is configured:

```sh
./scripts/release-signed-github.sh 1.2.0
```

The script:

- Finds installed `Developer ID Application` signing identities.
- Uses the only matching identity automatically, or prompts when multiple identities exist.
- Defaults the notary keychain profile to `bloomworks-notary`.
- Defaults the release bundle identifier to `com.cmer.gateopener`.
- Shows the release configuration and asks before publishing.
- Builds Release, signs with hardened runtime and timestamp, notarizes, staples, verifies, zips, and creates the GitHub release.

For unattended use:

```sh
DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="bloomworks-notary" \
SKIP_RELEASE_CONFIRMATION=1 \
  ./scripts/release-signed-github.sh 1.2.0
```

Set `BUNDLE_ID=...` to override the bundle identifier. Set `GH_REPO=owner/name` to publish outside `cmer/gateopener`.

## Homebrew Distribution

GateOpener is distributed through the personal tap `cmer/homebrew-tap` (repo `github.com/cmer/homebrew-tap`, cask at `Casks/gateopener.rb`). Users install with:

```sh
brew install --cask cmer/tap/gateopener
```

At the end of a successful release, `release-signed-github.sh` clones the tap, rewrites the cask's `version` and `sha256` to match the new zip, and pushes the change. This step is best-effort: the GitHub release is already published by then, so a tap failure only prints a warning plus the sha256 for a manual fix.

- Defaults: `TAP_REPO=cmer/homebrew-tap`, `CASK_NAME=gateopener`.
- Set `SKIP_CASK_UPDATE=1` to skip the cask update (still prints the zip sha256).
- Set `TAP_REPO=owner/homebrew-name` / `CASK_NAME=...` to target a different tap or cask.

The cask is arm64-only and requires macOS Ventura (13.0), matching the build's deployment target. Additional apps go in the same tap as more files under `Casks/`.

## One-Time Signing Setup

Install a `Developer ID Application` certificate in the login keychain, then confirm it is visible:

```sh
security find-identity -v -p codesigning
```

Store notarization credentials in Keychain under the expected profile name:

```sh
xcrun notarytool store-credentials bloomworks-notary \
  --apple-id you@example.com \
  --team-id TEAMID
```

If using an App Store Connect API key instead:

```sh
xcrun notarytool store-credentials bloomworks-notary \
  --key /path/to/AuthKey_KEYID.p8 \
  --key-id KEYID \
  --issuer ISSUER_ID
```

## Changelog

Keep `CHANGELOG.md` updated with notable user-facing, build, release, and documentation changes. Add unreleased entries above released versions until release prep promotes them to a versioned section.

End any turn that reports on long-running or delegated work with a short status: **Goal**, **Done**, **Next**, **Needs you** (or "nothing").
