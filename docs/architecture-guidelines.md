# Architecture Guidelines

Compact rules for the architectural patterns used in Firefox iOS. This document is the checklist used by our automated PR reviewer.

Every rule below should be traceable to an ADR, a Confluence page, a Google document, or a team agreement. All sources should ideally be linked. Do not add a rule here without a source; document it first, then add it.

## General guidelines

- Do not add new global variables or functions in the code.
- Challenge any singleton used without a proper reason. Watch for new `static let shared = X()` or `static let sharedInstance = X()`. Alternatives could be to use dependency injection, or our `DependencyHelper` instead of a singleton.
- Challenge the use of `static func` unless there's a clear reason. Static methods can hide dependencies, bypass dependency injection, reduce testability, and encourage global access patterns. They should generally be reserved for pure, stateless utility functions, factory methods, or namespaced algorithms.
- Any closure that can outlive its caller must capture `self` weakly (`[weak self]`) to avoid retain cycles. This applies to escaping closures (completion handlers, delegate callbacks, `NotificationCenter` observer blocks, timer closures), `Task { }` blocks, and any closure stored as a property. 

## BrowserKit libraries

- When a new BrowserKit package is added, it should be reminded to check that the code coverage is properly gathered. This needs to be done manually by the owner of the PR. Steps to fix code coverage are [listed in Confluence](https://mozilla-hub.atlassian.net/wiki/spaces/FXIOS/pages/2316894216/How+to+create+a+BrowserKit+package).
- Do not add new code to the `Shared` library. If it's meant to be shared, it should be under `Common` or place new code in a specific feature module, or an appropriate `BrowserKit` component. The `Shared` library is there for historical reasons but we don't want to expand on it.

## Modern concurrency
- `Task { ... }` belongs at the topmost entry point of the chain (a view lifecycle callback, an action handler, a Redux middleware entry). Inside an already-`async` function, call the next `async` function directly instead of wrapping it in a new `Task { }`.
- Do not mix Grand Central Dispatch (`DispatchQueue.*`, `.async`, `.asyncAfter`) with Swift concurrency (`async`/`await`, `Task`) in the same call chain. If a path uses Swift concurrency, keep it there. If it still uses GCD, migrate the whole path rather than bridging back and forth between the two models, or keep using GCD.
- `@unchecked Sendable` may only be used on a class that provides its own thread-safety guarantee, such as a lock, or equivalent synchronization mechanism. Test-only classes may use `@unchecked Sendable` without a locking mechanism.

References: [Confluence: Swift Concurrency Best Practices](https://mozilla-hub.atlassian.net/wiki/spaces/FXIOS/pages/2287304722/Swift+Concurrency+Best+Practices).

## Coordinators

- Coordinators own navigation. View controllers should be flow-agnostic.
- Coordinators control app flow: create view controllers and call the `Router` to push/present. They should not decide *what* to show or contain business logic (like network calls, database calls or side-effects). The one exception is that a coordinator may hold A/B test variant logic.
- Coordinators should not hold references to the view controllers they present, unless there is a specific reason to do so.
- View controllers must not perform navigation themselves. Calls like `navigationController?.pushViewController(...)`, `present(_:animated:completion:)`, `dismiss(animated:)` from inside a view controller should be flagged. Route the navigation through a coordinator or dispatch a `NavigationBrowserAction`.

References: [ADR 0002](../adr/0002-coordinators-for-navigation.md), [Confluence: Navigation and Coordinators](https://mozilla-hub.atlassian.net/wiki/spaces/FXIOS/pages/2545713156).

## Theming

All colors and themed images go through the theming system. Hardcoded colors are to be avoided.

- UIKit views must conform to `Themeable`, implement `applyTheme()`, and call `listenForThemeChanges()` in `viewDidLoad()`. Child views conform to `ThemeApplicable` and receive the theme from their parent.
- SwiftUI views use `@Environment(\.themeType)` and implement `applyTheme(theme:)`.
- Use themed colors exclusively: `theme.colors.textPrimary`, `theme.colors.layer1`, etc. Do not use hardcoded `UIColor(red:green:blue:alpha:)`, `UIColor(hex:)`, hex string literals, or system colors such as `UIColor.red` in production code. The only unthemed exception is `.clear`.
- Do not reference `FXColors.*` directly in feature code. Colors are consumed through the theme's colors namespace.
- Do not branch on the theme type in view code (`if theme == .dark { ... }`). If a value must differ between themes, add a token to the theme and let each theme resolve it.
- If the color you need is not in the mobile theme, ask designers to add it to the Figma color tokens before writing the code. Do not add local color constants as a workaround.

Reference: [Theming system wiki](https://github.com/mozilla-mobile/firefox-ios/wiki/Theming-system).

## Accessibility

Every visible UI element must be usable with VoiceOver and Dynamic Type. The reviewer looks for missing or misused accessibility APIs on new views.

- **`accessibilityLabel`**: set on custom UI elements, or on standard elements whose default label is missing or wrong. The label must be a localized string. Do not leave VoiceOver reading unlocalized text or raw asset names.
- **`accessibilityTraits`**: set traits that reflect the element's function when they differ from the default. Common patterns: `.button` for tappable images, `.link` for elements that navigate to external content, `.header` for section headers.
- **`accessibilityHint`**: use only when the label alone does not convey what the action does. VoiceOver reads it after the label, trait, and value, and users can disable hints.
- **`accessibilityIdentifier`**: for UI testing only. It is not user-facing and must not be used in place of `accessibilityLabel`. All identifiers must be declared in the `AccessibilityIdentifiers` struct (never inlined as raw strings in view code), and new entries must be added in alphabetical order within their group. All elements on screen should have an accessibility identifier.
- **Element grouping**: for composite cells (image + title + description), disable `isAccessibilityElement` on the child views and enable it on the parent container with a combined `accessibilityLabel`. VoiceOver should navigate the cell as one element.

### Dynamic Type

- Text-containing views must support Dynamic Type. Use `FXFontStyles` for fonts and set `adjustsFontForContentSizeCategory = true` on labels.
- Scale icon sizes with `UIFontMetrics.default.scaledValue(for:)` so icons grow with text.
- Do not set fixed heights on views that contain text. Use `UIStackView` and set `numberOfLines = 0` for multi-line labels so content can reflow.

References: [Accessibility overview wiki](https://github.com/mozilla-mobile/firefox-ios/wiki/A-Brief-Overview-of-Accessibility), [Strings, AccessibilityIdentifiers, ImageIdentifiers wiki](https://github.com/mozilla-mobile/firefox-ios/wiki/Strings,-%60AccessibilityIdentifiers%60,-%60ImageIdentifiers%60).

## Redux

// TODO: Add Redux guidelines into Github Claude action review https://mozilla-hub.atlassian.net/browse/FXIOS-16394*

- Do not comment on Redux implementation for now since this section needs to be written.

References: [0003 Redux Pilot](../adr/0003-redux-pilot.md), [0004 Redux replaces MVVM](../adr/0004-using-redux-to-replace-mvvm.md), [0005 Redux Navigation](../adr/0005-redux-and-navigation.md), [0011 Copy macro](../adr/0011-redux-state-reducer-initializer-cleanup-with-copy-macro.md), [Redux](https://mozilla-hub.atlassian.net/wiki/spaces/FXIOS/pages/2647621724), [Redux: How to Implement](https://mozilla-hub.atlassian.net/wiki/spaces/FXIOS/pages/2647556179), [Redux Guidelines & FAQs](https://mozilla-hub.atlassian.net/wiki/spaces/FXIOS/pages/2647392306)

## Tests

- Tests must call `super.setUp()` and `super.tearDown()` in their respective overrides.
- `setUp` and `tearDown` must mirror each other. Every property assigned in `setUp` must be reset (typically to `nil`) in `tearDown`, so state does not leak across tests.
- Tests should test for leaks with `trackForMemoryLeaks` whenever possible.
- Unit tests cases shouldn't only cover happy path.
