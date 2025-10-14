# 3. Redux Pilot

Date: 2023-09-07

## Status

Approved

## Context

Firefox iOS currently relies on MVVM in many areas while a large BrowserViewController (BVC) still coordinates significant logic and state. This leads to:
- Cross-coupled view controllers and ad-hoc delegation chains.
- Race conditions and nondeterministic state transitions.
- State scattered across controllers, view models, and services.
- Navigation and side-effects intertwined with UI logic, making testing hard.

## Decision

Adopt a lightweight, in-house Redux-style architecture (inspired by ReSwift’s core types) to be introduced incrementally, starting with a contained feature area.

### Main components

- Information flow is structured and always flows in one single direction.
- There is a single global immutable state kept in store.
- New state can be set only by dispatching an action to store and is calculated by reducer which is a pure function.
- Store notifies subscribers by broadcasting new state.

### Middlewares

- Middleware is where side effects of actions are managed
- Examples: network requests or reading data from storage
- May send a new action back to the store

### Scope (Pilot)

Start with a contained surface (e.g., `ThemeSettingsController`).

Prove: determinism, testability, and developer ergonomics.

## Consequences

### Positive

- Deterministic, serial state evolution; fewer races.
- Easier unit/integration testing of state transitions and effects.
- Clear boundaries (reducers vs middleware vs UI).

### Negative

- Learning curve and mindset shift for the team and external contributors.
- Boilerplate (actions, reducers, wiring) without helper tooling at first.
- Risk of over-modeling state if guidelines aren’t enforced.
- Migration cost and interim duplication with existing MVVM logic.
- If misused, middleware can accumulate too many responsibilities (must be kept small and focused).
- We need a clear interoperability story with our Coordinator + Router navigation approach.

## References
- [Redux on iOS](https://docs.google.com/presentation/d/1_uEOyjK-Hr0schRf0oDOqMCCQ7_IjrXZg10vlrtepBU/edit?usp=sharing)
- [Investigation](https://docs.google.com/document/d/1dVzwrWktGYA6J_4eya3_bay6KQdED9ACiZ81ZfY679w/edit?usp=sharing)
- [Implementation Presentation](https://docs.google.com/presentation/d/1SYgu-1pqyRhdkto0ImNpCWvBKgf1ufDeijHKJ2toYoI/edit?usp=sharing)