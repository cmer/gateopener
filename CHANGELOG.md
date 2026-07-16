# Changelog

All notable changes to GateOpener are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project follows [Semantic Versioning](https://semver.org/) and [Conventional Commits](https://www.conventionalcommits.org/).

## Unreleased

## [1.2.0] - 2026-07-16

### Features

- Add a custom glass gate application icon.

### Build

- Add a signed GitHub release script for Developer ID signing and notarization.
- Publish a Homebrew cask (`cmer/homebrew-tap`) so GateOpener installs with `brew install --cask cmer/tap/gateopener`.
- Update the Homebrew cask automatically at the end of the signed release script (skip with `SKIP_CASK_UPDATE=1`).

### Documentation

- Document signed release setup and usage for Claude.
- Simplify the README to a one-line Homebrew install plus usage; drop build-from-source instructions.

## [1.1.0] - 2026-06-24

### Features

- Report when an app is already unquarantined instead of saying quarantine was removed.

## [1.0.0] - 2026-06-24

### Features

- Create GateOpener macOS app
