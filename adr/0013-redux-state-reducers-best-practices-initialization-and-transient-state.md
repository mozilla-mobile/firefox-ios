# 13. Redux State Best Practices: Initialization and Transient State

Date: 2026-08-05

## Status

Accepted

## Context

Following the introduction of the `@Copyable` macro in [ADR-0011](0011-redux-state-reducer-initializer-cleanup-with-copy-macro.md), we want to create a more detailed standard for how we write our Redux State reducers.

This will further ensure consistency across the broader project.

### Motivation

In a number of our State types, we have **transient state** (i.e. properties that act as one-shot UI signals, like `didNavigate`). These one-shot transient state properties *must* be cleared before a new state is reduced for the next action.

> [!Note]
> **Transient State**: One-shot UI signals that must be cleared after use (e.g. after triggering an animation or navigation).

Throughout the project, we have inconsistent treatment of transient state. In many places, we cleared transient state using default arguments supplied to the State's memberwise `init`. This clears properties implicitly. As a result, it is not obvious what properties are truly transient and which are just conveniently provided a default value.

Furthermore, there has been inconsistent implementation of the `defaultState()` method. We should prefer to use the memberwise state `init` inside `defaultState()` and explicitly set transient values to their defaults. The added benefit to this is that the compiler will alert us when a new property is added to the State in the future. That lets us be conscientious about identifying transient state and assigning defaults. If we just use the `.copy()` methods, we will not get this feedback. 

We want `defautState()` to be the single source of truth for transient properties—not default argument values in the `init` or a strange mix between the two.

## Decision

In order to leverage compiler feedback and explicitly define a source of truth for transient State properties, we want to enforce standards around the following:

### 1. Usage of the `@Copyable` Macro

All our Redux States should leverage the `@Copyable` macro to make reducer return statements more readable.

You can read more about the macro in [ADR-0011](0011-redux-state-reducer-initializer-cleanup-with-copy-macro.md).

### 2. Our State `init` Pattern

Redux States should have **precisely three** initializers:
1. `init(appState: AppState, uuid: WindowUUID)`: Used for state subscription in the presentation layer
2. `init(windowUUID: WindowUUID)`: Used when adding a new presented component to the Redux state hierarchy
3. Memberwise `init(prop1: Type, prop2: Type, ...)` used to individually initialize all stored properties

> [!CAUTION]
> Do NOT add default values to any initializer arguments.

### 3. Correct `StateType` `defaultState(from:)` Implementation

All Redux State types conform to `StateType`, which requires a `defaultState(from:)` implementation. 

A correct `defaultState(from:)` implementation should:

- Return a new instance of the State using the memberwise `init()`, NOT the `.copy()` methods
- Copy over persistent properties directly from the `from` argument
- Reset all transient properties back to their defaults

> [!CAUTION]
> Never return the previous state instance with `return state`. You must always construct a *new* state instance for Redux to work correctly.

Example usage:
```
static func defaultState(from state: TabsPanelState) -> TabsPanelState {
        return TabsPanelState(
            // Copy over persistent properties
            windowUUID: state.windowUUID,
            isPrivateMode: state.isPrivateMode,
            tabs: state.tabs,

            // Reset transient properties
            scrollState: nil,
            didTapAddTab: false,
            urlRequest: nil
        )
    }
```

### 4. Correct `StateType` `resetTransientState()` Usage

If your Redux State contains transient properties, you must use the `resetTransientState()` method to clear those properties before leveraging the `@Copyable` macro's `.copy()` methods.

Using `resetTransientState()` ensures all transient state is cleared from your copy of the previous state *before* applying your updates to the state in response to the latest action.

The default implementation for `resetTransientState()` simply calls `defaultState(from:)` on `self`.

Example usage:
```
func handleSomeAction(...) -> SomeState {
    ...
    return state
        .resetTransientState() // Clears all transient state back to defaults
        .copy(someProperty1: newValue1)
        .copy(someProperty2: newValue2)
        ...
}
```

> [!Note]
> You only need to call `resetTransientState()` if your State contains transient properties.


## Migration Tip

When migrating a State type to use `@Copyable`, first review that State's memberwise `init()` method. 

Does the `init()` contain default arguments? If yes, you may be dealing with a State which contains transient state.

You should remove the default values from the memberwise `init()` as part of the migration work. However, you must be thoughtful about which values must be reset. 

Update the `defaultState()` method to correctly set these default values for any transient state instead (remembering that transient state is state which should always be cleared by the next action, after having been consumed once).

You should then carefully audit each reducer `return` statement as you apply the `.copy()` methods. You want to ensure the *before* behaviour (`init` with default arguments) and *after* behaviour (`.resetTransientState()` and `.copy()` usage) remains the same.

## Consequences

### Positive Consequences

- Consistency across Redux States for intializers, `StateType` `defaultState()` implementation, and `resetTransientState()` usage
- Ensures developers are conscientious about defining and clearing transient state (and the code becomes self-documenting)
- Improved compiler feedback when adding new transient properties

### Neutral Consequences

- Refactoring the Redux State memberwise `init()` to remove default arguments may involve refactoring call sites in unit test files

### Negative Consequences

- N/A

## References

- [ADR-0011: Redux State Reducer Initializer Cleanup with Copy Macro](0011-redux-state-reducer-initializer-cleanup-with-copy-macro.md)