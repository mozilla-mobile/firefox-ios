# 12. Redux Action Guidelines

Date: 2026-07-17

## Status

Accepted

## Context

Our pattern for defining Redux actions has scaled poorly over time in large part because of how we have implemented the `Action` and `ActionType` protocols in the app. 

Today, our notification pattern for Redux involves firing actions with two parts:
1. An action type (the action to fire)
2. An action payload (metadata about the action)

In Swift, the semantic way to define a group of related values like this is with an enumeration. Enums in Swift allow developers to work with groups of related values in a type-safe way.

Our action types are currently defined as enums (e.g. for the `ToolbarAction`, we have `ToolbarActionType`). However, we then define our action payloads separately as one large, common struct that is leveraged for numerous actions.

Let's look at the most egregious example in the app today: the `ToolbarAction`.

```
struct ToolbarAction: Action {
    // Protocol conformance
    let windowUUID: WindowUUID
    let actionType: ActionType

    // ℹ️ Payload optionals -- Can you guess which property you need to set to fire the action keyboardStateDidChange?
    let toolbarPosition: SearchBarPosition?
    let toolbarLayout: ToolbarLayoutStyle?
    let tabTrayButtonStyle: TabTrayButtonStyle?
    let isTranslucent: Bool?
    let numberOfTabs: Int?
    let scrollAlpha: Float?
    let url: URL?
    let searchTerm: String?
    let isPrivate: Bool?
    let showMenuWarningBadge: Bool?
    let isShowingNavigationToolbar: Bool?
    let isShowingTopTabs: Bool?
    let canGoBack: Bool?
    let canGoForward: Bool?
    let canSummarize: Bool
    let readerModeState: ReaderModeState?
    let addressBorderPosition: AddressToolbarBorderPosition?
    let displayNavBorder: Bool?
    let lockIconButtonA11yId: String?
    let lockIconImageName: String?
    let lockIconNeedsTheming: Bool?
    let safeListedURLImageName: String?
    let isLoading: Bool?
    let shouldShowKeyboard: Bool?
    let shouldAnimate: Bool?
    let middleButton: NavigationBarMiddleButtonType?
    let isTranslationsEnabled: Bool?
    let translationConfiguration: TranslationConfiguration?
    let previousTabScreenshot: UIImage?
    let nextTabScreenshot: UIImage?
    ...
}
```
Containing a staggering 30 optional stored properties, the `ToolbarAction` is no longer self-documenting and is incredibly cumbersome to use. There is zero compiler help and zero documentation that describes which combination of these properties must be initialized to fire any one of the 33 Toolbar-related actions in the app. There are over 50 Toolbar-related actions fired across nearly 20 different files. ToolbarActions, and instances of ToolbarAction, are referenced in over 300 lines across 25 files, excluding tests.

Leveraging enum associated values would let us keep our action payload types small and specific, and perhaps more importantly give us compiler hints on exactly what metadata must be included with any given action. This is the safest and most Swifty way for us to implement our action payloads, as historically we cannot depend on developers to write and maintain documentation in this area.

## Decision

We will migrate our Redux actions from structs with enum `actionType` properties to an enum with associated values.

This guarantees that every single Redux action has explicit, non-optional parameters. The presence of these parameters will no longer have to be checked in every reducer and middleware that consumes the action because the presence of required values will be guaranteed (as was impossible with optionals).

Going forward, we must enforce guidelines around creating new actions (naming and best practices), as described in the next section.

Since Redux actions are such a core aspect of the app, we will have to incrementally migrate our "legacy" actions to the new "modern" actions. The chosen approach for the migration is described later in this document.

### Redux Action Rules & Guidelines

#### 1. Action Grouping *(i.e. enum definitions)*

- Action enum names should be suffixed by `Action` 
- Action enums should represent a group of similar events, such as those related to one surface in or component in the app
    - Naming actions fired from a middleware can be less clear; use your discretion on how to best categorize such actions

> [!NOTE]
> Example: Actions describing how a user interacts with the Toolbar (tapping the share button, entering text into the URL bar, etc.) should be grouped together under a `ToolbarAction` enum

> [!NOTE]
> Example: When a middleware finishes processing a webpage translation, firing a "translation action" makes sense. You would add a new case under the `TranslationAction` enum.


#### 2. Action Naming *(i.e. enum cases)*

- Action names should describe what happened
- Action names should be in present tense 

> [!NOTE]
> Examples: `urlDidChange`, `clearSearch`, `didTapButton`


#### 4. Payload Struct Naming

- Payload struct types should be suffixed by `*Payload`

> [!NOTE]
> Examples: `MoveTabPayload`, `DidSelectTabPayload`


#### 3. Action Payloads *(i.e. associated values)*

- If your payload includes more than 3 discrete values, wrap them in a payload struct instead
- All associated values in your action enums **must** be explicitly labelled
    - Exception: If you pass a single payload struct, no label is necessary
- If your associated value contains a payload struct, do not pass any other associated values; put them inside the payload struct instead

> [!NOTE]
> Example:
>
> All non-payload parameters are explicitly labelled:
> - ✅ case confirmCloseAllTabs(isPrivateMode: Bool)
> - ✅ case addNewTab(panelType: TabTrayPanelType, isPrivateMode: Bool)
> - ❌ case unlabelledProperty(Bool)
> - ❌ case unlabelledProperty(TabTrayPanelType)
> - ❌ case unlabelledProperties(String, String, String)
>
> Up to 3 labelled properties is acceptable:
> - ✅ case didOpenShareSheet(selectedTab: Int, forURL: URL, panelType: TabTrayPanelType)
> - ❌ case tooManyProperties(prop1: Int, prop2: Int, prop3: Int, prop4: Int, prop5: Int, ...)
>
> For more than 3 properties, use a payload struct:
> - ✅ case moveTab(MoveTabPayload)
> - ❌ case moveTab(payload: MoveTabPayload)
> - ❌ case moveTab(MoveTabPayload, isPrivate: Bool)
> - ❌ case moveTab(MoveTabPayload, Bool, Int)

### Migration Guidelines

For the migration, all middlewares providers should define two providers in a tuple. The first item in the tuple is the old provider which handles the old type of actions (legacy) and the second item in the tuple is the new provider which handles the new type of actions (modern). Likewise, all state reducers will similarly define two reducers in a tuple, a legacy reducer and a modern reducer.

#### Middleware Providers

Below is an example of a middleware that is currently undergoing migration. Note that this middleware supports three actions. The `requestInitialValue` and `increaseCounter` actions have been migrated to `ModernAction`. The `decreaseCounter` action has not yet been migrated and is of the legacy `Action`.

```swift
lazy var fakeProvider: Middleware<FakeReduxState> = (legacyFakeProvider, modernFakeProvider)

lazy var modernProvider: MiddlewareMethod<FakeReduxState> = { [self] state, action, windowUUID in
    // Handles one type of action
    guard let action = action as? FakeReduxModernAction else { return }

    switch action {
    case .requestInitialValue:
        // Implementation...

    case .increaseCounter:
        // Implementation...

    default:
        break
    }
}

lazy var legacyProvider: LegacyMiddlewareMethod<FakeReduxState> = { [self] state, action in
    // Handles one type of action
    guard let actionType = action.actionType as? FakeReduxActionType else { return }

    switch action.actionType {
    case .decreaseCounter:
        // Implementation...

    default:
        break
    }
}
```

A few notes:
- The `[swift]` is an explicit capture of `self` in a closure using a capture list. This makes it so you don't need to explicitly refer to `self` in the body of the closure, which is a handy convenience. However, this comes with a retain cycle implication for our unit tests. See examples of `releaseMiddlewareProvidersFromMemory` in the codebase for how to deal with

#### State Reducers

Below is an example of a Redux state that is currently undergoing migration. Note that this state supports three actions. The `initialValueLoaded` and `counterIncreased` actions have been migrated to `ModernAction`. The `counterDecreased` and `setPrivateModeTo` actions have not yet been migrated and is of the legacy `Action`.

```swift
static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

static let modernReducer: ReducerMethod<Self> = { state, action, actionWindowUUID in
    // Handles one type of action
    guard let action = action as? FakeReduxModernAction else { return defaultState(from: state) }

    switch action {
    case .initialValueLoaded(let counterValue),
        .counterIncreased(let counterValue):
        // Implementation...

    default:
        return defaultState(from: state)
    }
}

static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
    guard let action = action as? FakeReduxAction else { return defaultState(from: state) }

    switch action.actionType {
    case FakeReduxActionType.counterDecreased:
        // Implementation...

    case FakeReduxActionType.setPrivateModeTo:
        // Implementation...
        
    default:
        return defaultState(from: state)
    }
}
```

## Consequences

### Positive Consequences

- Significantly less confusion in requirements for calling any given Redux action
- Middlewares and Reducers no longer need to check for the presence of required parameters as all required parameters are non-Optional
- Increased readability and guidelines for naming and action categorization

### Neutral Consequences

- For actions with more than 3 discrete values in the payload, we can expect the creation of (potentially many) `*Payload` struct types in our codebase

### Negative Consequences

- This is a hefty migration, so we can expect to have our "legacy" actions, middleware providers, and state reducers in place for some time
