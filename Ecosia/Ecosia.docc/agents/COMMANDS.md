# Development Commands

> [Full setup narrative for humans here](../../../firefox-ios/Ecosia/Ecosia.docc/Ecosia.md)

Run from **workspace root** (`ios-browser/`) unless otherwise specified.

## Bootstrap (First-Time Setup)

```sh
sh ./bootstrap.sh    # Installs hooks, resolves packages, updates content blockers, creates Staging.xcconfig
```

## Build & Run

- Open `firefox-ios/Client.xcodeproj` in Xcode
- Select the **Ecosia** scheme for development builds
- Select the **EcosiaBeta** scheme for running tests

## Tuist Project Regeneration

Run after adding new Swift files, asset catalogues, or directories:

```sh
sh tuist-setup.sh
```

Verify a new file is registered:

```sh
grep "MyNewFile.swift" firefox-ios/Client.xcodeproj/project.pbxproj
```

## Linting

```sh
swiftlint                # Lint locally (uses .swiftlint.yml + baseline)
swiftlint --strict       # Same as CI (GitHub Actions)
```

## Tests

```sh
# Run via Xcode: Cmd+U with EcosiaBeta scheme
# Test plan: firefox-ios/EcosiaTests/UnitTest.xctestplan
```

## User Scripts (JS injected into WKWebView)

```sh
npm run build            # Compile webpack → Client/Assets/AllFramesAtDocumentEnd.js etc.
```

Source: `firefox-ios/Client/Frontend/UserContent/UserScripts/`

## Translations

```sh
python3 ecosify-strings.py firefox-ios    # Rebrand Mozilla strings after upstream merges
```

## CI

- **Circle CI** — full builds
- **GitHub Actions** — SwiftLint, merge unit tests, snapshot tests
