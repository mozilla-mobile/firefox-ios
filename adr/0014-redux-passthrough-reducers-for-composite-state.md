# 14. Structure Redux to use Passthrough Reducers to Delegate Actions to Subcomponents

Date: 2026-09-15

## Status

Accepted

## Context

Up until this point when we have a `ScreenState` class like `HomepageState` or `BrowserViewControllerState` we have let those classes own variables for things like transient substates and booleans all at the top level of the file with little organization. For example, the `HomepageState` looked like this:

```
    var windowUUID: WindowUUID

    // Homepage sections state in the order they appear on the collection view
    let headerState: HeaderState
    let messageState: MessageCardState
    let topSitesState: TopSitesSectionState
    let searchState: SearchBarState
    let jumpBackInState: JumpBackInSectionState
    let trackerBlockerModuleState: TrackerBlockerModuleState
    let bookmarkState: BookmarksSectionState
    let merinoState: MerinoState
    let wallpaperState: WallpaperState

    let isZeroSearch: Bool
    let shouldTriggerImpression: Bool
    let shouldShowPrivacyNotice: Bool

```

This means that these top level `ScreenState` files could get very bloated with logic in addition to the reducer actions. Before refactoring `HomepageState` about 85% of the file was duplicated property forwarding.

Having some variables in the `HomepageState` also contributed to this problem - prior to this ADR there is no rule that everything in a `ScreenState` had to be owned by a substate.

## Decision

In the future `ScreenState` classes will have the following rules:

1. Every property should belong to a sub-state. It is fine to create a new sub-state to handle a set of responsibilities for the screen.

2. Because of rule 1, action handling will live in the substates, which will provide clearer separation of responsibilities and smaller files that are easier to understand.

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

- [ADR-0011: Redux State Reducer Initializer Cleanup with Copy Macro](0011-redux-state-reducer-initializer-cleanup-with-copy-macro.md)**