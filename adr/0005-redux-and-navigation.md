# 5. Redux-driven Navigation via Navigation Actions & State

Date: 2024-10-17

## Status

Accepted

## Context

Redux needs to integrate navigation inside it's state so we can properly navigate with coordinators. This approach reduces redundancy by centralizing navigation handling in `BrowserViewControllerState`, ensuring that coordinators manage navigation consistently even when destinations overlap across different states.

## Decision

We will adopt the following Redux + Navigation integration pattern across Firefox iOS:
- Creation of a new `NavigationBrowserAction` type and a `NavigationDestination` enum to abstract navigation intents. 
- Moving navigation handling out of `HomepageState` into a more global `BrowserViewControllerState`, reflecting that navigation is not specific to homepage. 
- `BrowserViewController` now listens to `state.navigationDestination` and calls `handleNavigation(to:)` when non-nil. 

These changes formalize a pattern: navigation is expressed as Redux state or actions (intents), not direct view controller calls inside reducers or view logic.

## Consequences

### Positive
- Separation of concerns: Navigation decisions are decoupled from views and view controllers; UI only responds to state changes.
- Consistency and reuse: Shared navigation destinations in browser-level state ensure uniform navigation behavior (e.g. “go to Pocket section” works from many places).
- Incremental adoption: Existing navigation can gradually be migrated to the new pattern as parts of the app adopt Redux navigation state.

### Negative
- Partial legacy overlap: Some parts may still use Coordinators only, leading to hybrid models until full migration.
- This `BrowserViewControllerState` could get bloated.

## References

- [Code Proposal](https://github.com/mozilla-mobile/firefox-ios/pull/22597)