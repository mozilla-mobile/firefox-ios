# Firefox iOS Copilot Instructions

This is the Mozilla Firefox for iOS and Focus iOS monorepo, built with Swift, UIKit, and WebKit.

## Architecture Overview

### Monorepo Structure
- `firefox-ios/`: Main Firefox iOS app with Redux+Coordinator architecture  
- `focus-ios/`: Focus browser (privacy-focused) - simpler architecture
- `BrowserKit/`: Shared SwiftPM package with reusable components (Redux, WebEngine, etc.)
- `SampleBrowser/`: Reference implementation for BrowserKit usage

### Core Architectural Patterns

**Redux State Management** (Active Migration - ADR-0004):
- **Actions are classes** with `windowUUID` and `actionType` properties
- **Middleware handles business logic** and side effects (API calls, storage)
- **Reducers handle presentation logic only** (pure functions)
- Store automatically runs on main thread
- Use user/API action names, not state change names
- Required test coverage for all state and middleware

**Coordinator Pattern** (ADR-0002):
- `BaseCoordinator` manages navigation and child coordinators
- `Router` wraps `UINavigationController` for navigation operations
- `BrowserCoordinator` is the main coordinator, replaces monolithic BVC
- Each feature has its own coordinator (Library, Settings, QRCode, etc.)

**Key Implementation Examples:**
```swift
// Redux Action Pattern
struct MyAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let payload: SomeData
}

// Coordinator Pattern  
class MyCoordinator: BaseCoordinator {
    func start() {
        let viewController = MyViewController()
        router.setRootViewController(viewController)
    }
}
```

## Development Workflows

### Build Setup
```bash
# Initial setup (bootstrap dependencies)
./bootstrap.sh

# Build JavaScript user scripts (WebView injection)
npm run build  # Production
npm run dev    # Development with source maps

# Xcode project location
open firefox-ios/Client.xcodeproj
```

### Key Build Concepts
- **User Scripts**: JavaScript files compiled via webpack for WebView injection
  - Located in `/Client/Frontend/UserContent/UserScripts/`
  - Organized by frame type (`MainFrame`/`AllFrames`) and timing (`AtDocumentStart`/`AtDocumentEnd`)
  - Built into `/Client/Assets/` as concatenated `.js` files

### Testing Patterns
- **Redux**: Use `MockStoreForMiddleware` for middleware testing
- **Coordinators**: Mock `Router` and verify navigation calls
- **WebEngine**: Extensive mock implementations in `BrowserKit/Tests/WebEngineTests/Mock/`
- **End-to-End XCUITests**: Modern TAE (Test Automation Efficiency) approach with Page Object Model
  - **TAE Framework**: Modular Page Object Model separating test intent from UI implementation
  - **PageScreens**: Classes representing app screens (`BrowserScreen`, `ToolbarScreen`) with semantic methods
  - **Selectors**: Structured element locators using `SelectorShortcuts` API (`buttonById()`, `textFieldById()`)
  - **Navigation Registry**: MappaMundi-based state machine for complex navigation flows
  - **Custom Utilities**: `mozWaitForElementToExist()` methods (up to 25x faster than XCTest defaults)
  - **Launch Arguments**: Control app behavior during testing (`LaunchArguments.ClearProfile`, `LaunchArguments.SkipIntro`)
- **Legacy XCUITests**: Being migrated to TAE - avoid `navigator.goto()` pattern in new tests
- **UI Tests**: L10n screenshot tests via fastlane, organized by locale

## Project-Specific Conventions

### Redux Guidelines
- **2-line switch rule**: Keep reducers and middleware cases concise
- **Actions**: Prefer composition over complex associated values
- **State changes**: Always return new state, never mutate
- **WindowUUID filtering**: Check action.windowUUID matches state.windowUUID in reducers

### Coordinator Patterns
- **Child management**: Use `add(child:)` and `remove(child:)` consistently
- **Router operations**: `push()`, `present()`, `pop()`, `dismiss()` with completion handlers
- **Navigation handlers**: Protocol-based delegation for cross-coordinator communication

### XCUITest Conventions (TAE Approach)
- **Test Structure**: Inherit from `BaseTestCase` or `FeatureFlaggedTestBase`, declare PageScreen properties
- **Page Objects**: Use `@MainActor final class` pattern with semantic methods (`tapSaveButton()`, `assertElementExists()`)
- **Selectors**: Define in separate files with protocols (`BrowserSelectorsSet`) and structs (`BrowserSelectors`)
- **Element Location**: Use `SelectorShortcuts` API over raw accessibility identifiers
- **Waiting Strategy**: Always use `mozWaitForElementToExist()` before interactions, avoid `sleep()`
- **Method Naming**: Actions start with verbs (`tap`, `enter`, `select`), assertions start with `assert`
- **Navigation**: Use Navigation Registry pattern for complex flows, avoid hardcoded navigation paths

### File Organization
- **Feature-based**: Group by functionality (`/Coordinators/Library/`, `/Frontend/Homepage/`)
- **Redux structure**: `State.swift`, `Action.swift`, `Middleware.swift` per feature
- **Testing**: Mirror source structure in test directories

### Dependencies & Integration
- **Mozilla services**: Rust components via `MozillaRustComponents`, Nimbus feature flags
- **Content blocking**: JSON-based rules in `ContentBlockingLists/`
- **Localization**: L10n managed via external repos, imported via scripts
- **External packages**: SwiftPM-managed in `Package.swift`, avoid CocoaPods

## Development Environment
- **Xcode**: 15.2+ required, Swift 5.9+, iOS 15.0+ deployment
- **Node.js**: Required for JavaScript bundling (webpack)
- **Python**: L10n scripts and automation tools

## Key Files to Reference
- [BrowserKit/Sources/Redux/](BrowserKit/Sources/Redux/) - Redux implementation
- [firefox-ios/Client/Coordinators/](firefox-ios/Client/Coordinators/) - Navigation patterns  
- [webpack.config.js](webpack.config.js) - User script compilation
- [adr/](adr/) - Architectural Decision Records for context on major patterns
- [firefox-ios/Client/Frontend/](firefox-ios/Client/Frontend/) - Main app UI implementation

## Testing & Quality
- Unit tests required for Redux state and middleware
- UI automation via fastlane for screenshot testing
- Mock implementations extensively used (see `Tests/*/Mock/` directories)
- CI/CD handles multiple locales and device configurations