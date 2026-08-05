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

In many cases, this clearing was happening in the memberwise `init` on the State. Default values were assigned to transient properties to clear them implicitly. As a result, it is not obvious what properties are truly transient and which are just conveniently provided a default value.

Furthermore, there has been inconsistent implementation of the `defaultState()` method. We should prefer to use the memberwise state `init` inside `defaultState()` and explicitly set transient values to their defaults. The added benefit to this is that the compiler will alert us to update this function when a new property is added to the State in the future. If we just use the `.copy()` methods, we will not get this feedback.

## Decision

In order to leverage compiler feedback and explicitly define which State properties are transient, we want to enforce standards around the following:

### 1. Usage of the `@Copyable` Macro

All our Redux States should leverage the `@Copyable` macro to make reducer return statements more readable.

You can read more about the macro in [ADR-0011](0011-redux-state-reducer-initializer-cleanup-with-copy-macro.md).

### 2. Our State `init` Pattern

Redux States should have **precisely three** initializers:
1. `init(appState: AppState, uuid: WindowUUID)`: Used in state subscription
2. `init(windowUUID: WindowUUID)`: Used when adding a new presented component to the Redux state hierarchy
3. Memberwise `init(prop1: Type, prop2: Type, ...)` which individually initializes all stored properties

> [!CAUTION]
> Do not add default values to any of these initializers.

### 3. Correct `StateType` `defaultState(from:)` Implementation

All Redux State types conform to `StateType`, which requires a `defaultState(from:)` implementation. 

A correct `defaultState(from:)` implementaiton should:

- Return a new instance of the State using the memberwise `init()`, NOT the `.copy()` methods
- Copy over persistent properties directly from the `state` argument
- Reset all transient properties back to their defaults

> [!CAUTION]
> Never `return state`. You must always construct a *new* state.

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

If your Redux State contains transient properties, you must use the `resetTransientState()` method to clear those properties before leveraging the `@Copyable` macro.

The default implementation for `resetTransientState()` simply calls `defaultState(from:)` on `self`.

Using `resetTransientState()` ensures all transient state is cleared from your copy of the previous state before applying your updates to the state in response to the latest action.

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

When migrating a State type to use `@Copyable`, first check that State's memberwise `init()` method. 

Does it contain default arguments? If it does, you may be dealing with a State which contains transient state.

You should remove the default values from the memberwise `init()` but be considerate of what those values previously cleared.

You should then carefully audit each reducer return statement as you apply the `.copy()` methods. You want to ensure the *before* and *after* behaviour does not change.

## Consequences

### Positive Consequences

- Consistency across Redux States for intializers, `StateType` `defaultState()` implementation, and `resetTransientState()` usage
- Ensures developers are conscious about defining and clearing transient state (code becomes self-documenting)
- Improved compiler feedback

### Neutral Consequences

- N/A

### Negative Consequences

- N/A

## References

- [ADR-0011: Redux State Reducer Initializer Cleanup with Copy Macro](0011-redux-state-reducer-initializer-cleanup-with-copy-macro.md)