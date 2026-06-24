# GateOpener

GateOpener is a small macOS app that removes Gatekeeper's quarantine attribute from a dropped `.app` bundle.

## Build

```sh
make
```

The app bundle is written to:

```text
build/GateOpener.app
```

Run it with:

```sh
make run
```

For day-to-day development, use the dev script. It builds a Debug app and launches it:

```sh
./scripts/build-dev.sh
```

For a production-style build, use the release script. It builds with Release optimization, ad-hoc signs the app, and creates a zip suitable for GitHub Releases:

```sh
./scripts/build-prod.sh 1.0.0
```

The release archive is written to:

```text
build/GateOpener-1.0.0.zip
```

To publish that zip directly to GitHub Releases in `cmer/gateopener`, authenticate the GitHub CLI once with `gh auth login`, then run:

```sh
./scripts/release-github.sh 1.0.0
```

## Use

Drag a `.app` bundle from Finder onto the GateOpener window. The app runs:

```sh
xattr -dr com.apple.quarantine /path/to/App.app
```

Only `.app` bundles are accepted. This app is intentionally unsandboxed so it can edit extended attributes on dropped applications.

You can also right-click an app in Finder and choose `Open With > GateOpener`. If macOS has not registered the freshly built app yet, launch it once with `make run`, or copy `build/GateOpener.app` to `/Applications` and open it once.

GateOpener also declares a Finder Services item named `Open in GateOpener`; depending on the macOS version and Finder's contextual menu layout, it may appear under `Services`.

## Removing GateOpener's Own Quarantine Flag

Release zips are hosted on GitHub. If you download GateOpener through a browser, macOS may quarantine GateOpener itself before you can use it to unlock other apps. That creates a catch-22.

After unzipping the release, remove GateOpener's quarantine flag manually from Terminal:

```sh
xattr -dr com.apple.quarantine /Applications/GateOpener.app
```

Adjust the path if the app is somewhere else, for example:

```sh
xattr -dr com.apple.quarantine ~/Downloads/GateOpener.app
```

Then open GateOpener normally.
