# 2. Coordinator Pattern for Navigation

Date: 2023-03-23

## Status

Accepted

## Context

The BrowserViewController (BVC) in Firefox for iOS has grown into a monolithic class responsible for handling navigation, managing views, and coordinating the entire application flow. This design leads to:
- Tight coupling between navigation and presentation logic.
- Duplicate navigation paths, which are difficult to test or reason about.
- Fragile code, where changes often cause regressions in unrelated navigation flows.
- Non-standard view lifecycle management, particularly in the homepage’s presentation logic (e.g., toggling via alpha instead of standard lifecycle calls).

These issues make it difficult to add new features, test navigation, or introduce modern iOS paradigms like multitasking.

## Decision

We will adopt the Coordinator pattern as the navigation management strategy for Firefox iOS.

This involves introducing:
- A Coordinator abstraction responsible for creating view controllers, handling app flow, and delegating navigation decisions.
- A Router abstraction that wraps a UINavigationController, handling navigation operations (push, pop, present, dismiss) and passing back navigation events to the coordinating entity.

## Consequences

### Positive
- Clear separation of concerns between navigation and UI logic.
- Easier unit testing for navigation flows.
- Simplified integration of new features without expanding BVC further.
- Enables standard iOS view lifecycle for homepage and webview.

### Negative
- Initial implementation complexity and migration cost.
- Potential risk of creating “massive coordinators” if responsibilities are not well defined.
- Difficulty of integration with SwiftUI navigation, since coordinators are designed to work with UIKit.

## References
- [Proposal](https://docs.google.com/document/d/1fYN63KDPjL8wl2ZQ3qu_p8lt-MGQ-koIi6m369zpU4c/edit?usp=sharing)
- [Wiki page](https://github.com/mozilla-mobile/firefox-ios/wiki/Navigation-&-Coordinators)