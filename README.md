# GateOpener

GateOpener is a small macOS app that removes Gatekeeper's quarantine attribute from a dropped `.app` bundle.

## Install

```sh
brew install --cask cmer/tap/gateopener
```

That's it — Homebrew downloads the signed, notarized app and installs it to `/Applications`. Because it comes through Homebrew, macOS won't quarantine GateOpener itself.

Requires an Apple Silicon Mac running macOS Ventura (13.0) or later.

## Use

Drag a `.app` bundle from Finder onto the GateOpener window. GateOpener removes its quarantine attribute so macOS will let it open. Only `.app` bundles are accepted.

You can also right-click an app in Finder and choose **Open With → GateOpener**, or use the **Open in GateOpener** Finder service (it may appear under **Services**).

GateOpener is intentionally unsandboxed so it can edit extended attributes on the applications you drop onto it.
