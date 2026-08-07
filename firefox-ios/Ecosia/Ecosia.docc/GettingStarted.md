# Getting started — Ecosia for iOS

This page lists the minimum dependencies and quick setup commands to build and run Ecosia locally.

Requirements

- macOS with Xcode (Xcode 16.2 recommended)
- Swift 5.6
- iOS deployment target: 15.0+
- Homebrew

Install common tooling

```bash
# Homebrew packages used by our scripts
brew update
brew install node swiftlint fastlane
```

Clone and prepare the project

```bash
git clone https://github.com/ecosia/ios-browser
cd ios-browser
./tuist-setup.sh
```

Tuist

We use Tuist to generate the Xcode workspace from manifests. Regenerate when manifests change:

```bash
./tuist-setup.sh --skip-bootstrap --no-open
# or from firefox-ios
tuist install --force-resolved-versions
tuist generate
```

User scripts (Webpack)

User scripts are concatenated/minified with webpack. Rebuild when you edit scripts under Client/Frontend/UserContent/UserScripts:

```bash
npm ci
npm run build
```

Certificates & provisioning (fastlane/match)

The signing repo is https://github.com/ecosia/IosSearchSigning.

```bash
bundle install
bundle exec fastlane match --readonly
```

Registering a device

```bash
bundle exec fastlane run register_device
bundle exec fastlane match development --force_for_new_devices
bundle exec fastlane match adhoc --force_for_new_devices
```

Run in Xcode

1. Open the generated workspace.
2. Select the `Ecosia` or `EcosiaBeta` scheme.
3. Choose a destination and hit Cmd+R.

Notes

- If SPM caching issues occur: Xcode → File → Packages → Reset Package Caches.
- SwiftLint is pinned in CI to 0.63.2; pin locally with `brew pin swiftlint` to avoid accidental upgrades.