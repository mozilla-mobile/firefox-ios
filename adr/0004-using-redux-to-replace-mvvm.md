# 4. Using Redux to replace MVVM

Date: 2024-09-05

## Status

Approved

## Context

We had some pilot (see `0003-redux-pilot.md`), and we now want to use Redux (if dealing with state); moving away from MVVM.

## Decision

We will now use Redux (if dealing with state); moving away from MVVM.
- Redux and MVVM are two different systems that don’t really work together
- Business logic should be handled by the middleware
- Presentation logic should be handled by the reducer

### Actions
Actions are now classes. This simplifies the data we want to present in all or many cases and removes the need for `ActionContext` on each action enums.

When creating action types, lean towards using user and API action names over state change names. We want our actions to read clearly on what action was taken and not the consequence of the action. The view should not know the consequences. Actions are called currently on main thread

### Store
The store will automatically ensure actions are executed on the main thread so we don’t need to add another check for main thread

## Consequences

We are adopting Redux on the team to utilize the benefits of structuring information in a single directional flow and maintaining state. 

### Positive

- Unified architecture: All new features follow Redux; eliminates inconsistent MVVM usage and removes the need for ViewModels.
- Clear separation of logic:
    - Middleware handles business logic and side effects.
    - Reducers handle presentation logic only.
- Simpler action model: Using class-based actions with properties simplifies payload handling and avoids repetitive associated values like windowUUID.
- Readable and maintainable:
    - The 2-line switch rule keeps reducers and middleware concise.
    - Explicit reducer calls make state flow easier to trace.
- Thread safety built-in: The store ensures all actions run on the main thread—no manual thread handling needed.
- Consistent naming: Emphasis on user/API-style action names improves clarity of intent.
- Test coverage enforced: State and middleware are now required to have tests, improving reliability.
- Feature flag integration: Middleware handles flags and dependencies cleanly without polluting state or views.

### Negative 

- Boilerplate increase: Class-based actions and explicit reducer calls add setup overhead for small features.
- Migration gap: Older MVVM code coexists with new Redux areas, creating hybrid complexity during transition.
- Middleware growth risk: As most dependencies and side effects move there, middleware can become bloated if not well-scoped.
- Action naming ambiguity: Deciding between user/API actions and middleware actions can cause confusion early on.
- Learning curve: Developers must adjust to Redux’s unidirectional flow and avoid thinking in MVVM patterns.
- Testing overhead: Middleware tests require mocking dependencies and setup that can be verbose without utilities.

## References

- [Redux updates presentation](https://docs.google.com/presentation/u/0/d/1kO25b51gv28zQnos9jrSzyMx4vh9Z4yX4H1jCbXMDM4/edit)
- [Redux guidelines document](https://docs.google.com/document/d/1d6DrWrvGM1EWKMJoQ75O_8Ey81-H43257rSHOY2psIQ/edit?usp=sharing)
- [Redux wiki page](https://github.com/mozilla-mobile/firefox-ios/wiki/Redux)
- [How to implement Redux wiki page](https://github.com/mozilla-mobile/firefox-ios/wiki/Redux-%E2%80%90-How-to-Implement)
- [Redux Guidelines](https://github.com/mozilla-mobile/firefox-ios/wiki/Redux-Guidelines---FAQs)