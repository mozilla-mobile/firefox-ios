# Architecture Guidelines

Compact rules for the architectural patterns used in Firefox iOS. This document is the checklist used by our automated PR reviewer.

Every rule below should be traceable to an ADR, a Confluence page or a Google document. All sources should be linked.. Do not add a rule here without a source; document it first, then add it.

## Coordinators

Coordinators own navigation. View controllers should be flow-agnostic.

- Coordinators control app flow: create view controllers and call the `Router` to push/present. They should not decide *what* to show or contain business logic. The one exception is that a coordinator may hold A/B test variant logic.
- Coordinators should manage only view controllers.
- Coordinators should not hold references to the view controllers they present, unless there is a specific reason to do so.
- `Router` wraps `UINavigationController` and is passed between coordinators. Extend it only to handle navigation events.
- A view controller must not know its position in the app flow. `ViewController A` should not know it is presenting `ViewController B`. Navigation is delegated to a coordinator, or expressed as a Redux navigation action (see Redux → Navigation).

References: [ADR 0002](../adr/0002-coordinators-for-navigation.md), [Confluence: Navigation and Coordinators](https://mozilla-hub.atlassian.net/wiki/spaces/FXIOS/pages/2545713156).

## Redux

Our in-house Redux implementation lives in [`BrowserKit/Sources/Redux`](../BrowserKit/Sources/Redux). New state-holding features use Redux, not MVVM.

References: [0003 Redux Pilot](../adr/0003-redux-pilot.md), [0004 Redux replaces MVVM](../adr/0004-using-redux-to-replace-mvvm.md), [0005 Redux Navigation](../adr/0005-redux-and-navigation.md), [0011 Copy macro](../adr/0011-redux-state-reducer-initializer-cleanup-with-copy-macro.md), [Redux](https://mozilla-hub.atlassian.net/wiki/spaces/FXIOS/pages/2647621724), [Redux: How to Implement](https://mozilla-hub.atlassian.net/wiki/spaces/FXIOS/pages/2647556179), [Redux Guidelines & FAQs](https://mozilla-hub.atlassian.net/wiki/spaces/FXIOS/pages/2647392306)

### State

- State is an immutable `struct` conforming to `ScreenState` and `Equatable`.
- State typically includes a `windowUUID` property to support multiple iPad windows.
- The reducer is a pure function exposed as `static let reducer: Reducer<Self>`.
- Reducers must always return a **new** state. Never `return state`; use `defaultState(from:)` in `else` and `default` branches so transient properties reset to their defaults.
- Reducers should not contain complex logic; they return the state for the view.
- Call sub-reducers explicitly (e.g. `SubState.reducer(state.subState, action)`), rather than passing the previous sub-state through unchanged.
- For large states, prefer the `@Copyable` macro (`state.copy(...)`) over re-initializing every property.

### Actions

- Actions are **classes** inheriting from `Action`. Never `struct`, and never `enum` cases with associated values.
- Each action lives in its own file, paired with a matching `ActionType` enum.
- Payload lives as properties on the action class, not as associated values on the `ActionType` case.
- Actions must carry a `windowUUID` (required by the `Action` protocol).
- Name actions after the **event that triggered them**, not the outcome. Prefer `tapOnButton` over `updateView`.
- User actions are dispatched from the view. Middleware-originated actions are dispatched from the middleware.

### Middleware

- Middleware is where side effects live: network, storage, telemetry, and other external dependencies.
- Middleware is optional. Do not add one without an explicit reason.
- All external dependencies must be injected via the initializer so tests can substitute mocks.
- Middleware handles business logic; reducers handle presentation logic. Keep the split clean.
- If a middleware grows too large or spans multiple responsibilities, split it.
- Do not manually dispatch to the main thread; the store guarantees actions run on the main thread.
- Middleware runs once per action (not once per active screen), so it must respect `windowUUID` when the action targets a specific window.

### Switch statements

- Switch cases in reducers and middleware have a **2-line maximum** per case, to keep them readable.

### Navigation in Redux

- Navigation intent is expressed as Redux state or actions (`NavigationBrowserAction`, `NavigationDestination`), not as direct view controller calls inside reducers or views.
- `BrowserViewController` observes `state.navigationDestination` and calls `handleNavigation(to:)` when it is non-nil. New navigation should follow the same pattern.

### View models

- Do not introduce new view models. Business logic goes to middleware; presentation logic goes to the reducer.
- If a model needs presentation-side shaping, name it `*Configuration` (e.g. `TopSiteConfiguration`).

### Tests

- Every action a state handles directly should have a test.
- Middleware should be tested with mocked dependencies.

## Tests

- Tests must call `super.setUp()` and `super.tearDown()` in their respective overrides.
- `setUp` and `tearDown` must mirror each other. Every property assigned in `setUp` must be reset (typically to `nil`) in `tearDown`, so state does not leak across tests.
- Tests should test for leaks with `trackForMemoryLeaks` whenever possible.


## BrowserKit libraries

- When a new BrowserKit package is added, it should be reminded to check that the code coverage is properly gathered. This needs to be done manually by the owner of the PR. Steps to fix code coverage are [listed in Confluence](https://mozilla-hub.atlassian.net/wiki/spaces/FXIOS/pages/2316894216/How+to+create+a+BrowserKit+package).
- Do not add new code to the `Shared` library. If it's meant to be shared, it should be under `Common` or place new code in a specific feature module, or an appropriate `BrowserKit` component. The `Shared` library is there for historical reasons but we don't want to expand on it.
