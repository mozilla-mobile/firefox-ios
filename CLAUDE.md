# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a monorepo containing three main projects:

- `firefox-ios/` - Firefox for iOS (main app, scheme: `Fennec`)
- `focus-ios/` - Firefox Focus for iOS (scheme: `Focus`)
- `BrowserKit/` - Shared Swift Package used in Firefox

## Setup

```bash
# Recommended: uses fxios-ctl
brew tap mozilla-mobile/fxios && brew install fxios
fxios setup --https   # or --ssh
```

Requirements: Xcode 16.3, Swift 6.2, iOS 15.0+, Node.js.

## Common Commands

### Build & Test

```bash
# Build for testing (Firefox)
fxios test
```

### JavaScript User Scripts

```bash
npm run build   # production build
npm run dev     # watch mode with source maps
```

### Linting

SwiftLint runs automatically via Xcode build phases on the Client target. Install via `brew install swiftlint`. Configuration is in `.swiftlint.yml`.
SwiftLint also runs whenever code is pushed to the remote, using hooks.

## Architecture

### BrowserKit (Shared Swift Package)

BrowserKit is the foundation shared between Firefox and Focus. Key libraries:

- `ComponentLibrary` - Reusable UI components
- `ToolbarKit`, `MenuKit`, `OnboardingKit`, `QuickAnswersKit`, etc. - Feature-specific UI kits
- `Redux` - Redux framework used by in Firefox iOS
- `TabDataStore` - Tab persistence
- `Shared`, `Common` - Utilities, preferences, device info. `Shared` should not be expanded with new code.
- `WebEngine` - WKWebView abstraction and rendering

### Firefox-iOS Client Structure

`firefox-ios/Client/` is organized by responsibility:

- `Coordinators/` - Navigation coordination (see below)
- `Frontend/` - All UI: `Browser/`, `Settings/`, `Library/`, `Home/`, etc.
- `Redux/` - Global app state (`GlobalState`)
- `TabManagement/` - Tab lifecycle and state
- `Storage/` - SQLite persistence, bookmarks, history
- `Providers/` - Networking, top sites, Merino suggestions
- `Telemetry/` - Glean metrics instrumentation
- `Nimbus/` - Feature flags and A/B experiments

### Redux State Management (ADR-4)

Redux is the approved pattern for new features (approved 2024-09). Key rules:

- Actions are **classes**, not enums
- Middleware handles business logic and side effects
- Reducers handle presentation logic only
- The Store guarantees main-thread execution
- Used for: tab management, browser state, settings

### Coordinator Pattern (ADR-2)

Navigation is managed via coordinators, not view controllers directly. Key coordinators: `BrowserCoordinator`, `SettingsCoordinator`, `LibraryCoordinator`, `LaunchViewCoordinator`, `SceneCoordinator`. All extend `BaseCoordinator` and use `ParentCoordinatorDelegate` for child-to-parent communication.

Do not use the name `Coordinator` other than for this specific purpose.

### Key Infrastructure

- **Sync & Accounts**: Firefox Sync and FxA via `mozilla/application-services` (Rust)
- **Storage**: SQLite with Rust-backed keychain (`RustKeychain`, `RustSyncManager`)
- **Telemetry**: Glean (`mozilla/glean`) for metrics, Sentry for error tracking
- **Experiments**: Nimbus feature flags from `mozilla/application-services`
- **Content Blocking**: Custom JS injection + shavar content blocker lists
