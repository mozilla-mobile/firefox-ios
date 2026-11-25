# 15. Structure Redux to use Passthrough Reducers to Delegate Actions to Sub-reducers

Date: 2026-11-17

## Status

Accepted

## Context

Up until this point when we have a large `State` struct like `HomepageState` or `BrowserViewControllerState` where there's one or more sub-reducers, we have let those structs own variables for things like transient boolean properties all at the same level with little organization or hierarchy. For example, the `HomepageState` looked like this:

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

This means that these top level `State` files could get very bloated with logic in addition to handle reducer actions. Before refactoring `HomepageState` about 85% of the file was duplicated property forwarding.

There was also a mix of the `State` struct handling actions itself and its sub-states handling actions. This decreased clarity when reading and working on the project.


## Decision

In the future, any `StateType` "parent" structs having at least one  `StateType` "child" struct must abide by the following rules:

1. A parent `StateType` may only contain `StateType` properties. It may not contain properties of any other type.
2. A parent `StateType`'s reducer should not handle any actions. It only "passes through" (i.e. forwards) actions to its `StateType` children's reducers.

When a state grows too large, developers should pull out related responsibilities into a new child `StateType` with its own reducer. But once a state has a child `StateType`, its remaining non-`StateType` properties should also move into their own child state(s). This saves the parent state's reducer from implementing a confusing mix of handling some actions itself and forwarding others (as in the `HomepageState` example above).

#### Example:
``` 
@MainActor
    private static func passthroughState(from state: HomepageState, action: Action) -> HomepageState {
        return HomepageState(
            windowUUID: state.windowUUID,
            headerState: HeaderState.reducer.legacyReducer(state.headerState, action),
            privacyNoticeState: PrivacyNoticeState.reducer.legacyReducer(state.privacyNoticeState, action),
            messageState: MessageCardState.reducer.legacyReducer(state.messageState, action),
            topSitesState: TopSitesSectionState.reducer.legacyReducer(state.topSitesState, action),
            searchBarState: SearchBarState.reducer.legacyReducer(state.searchBarState, action),
            jumpBackInState: JumpBackInSectionState.reducer.legacyReducer(state.jumpBackInState, action),
            trackerBlockerModuleState: TrackerBlockerModuleState.reducer
                .legacyReducer(state.trackerBlockerModuleState, action),
            bookmarkState: BookmarksSectionState.reducer.legacyReducer(state.bookmarkState, action),
            merinoState: MerinoState.reducer.legacyReducer(state.merinoState, action),
            wallpaperState: WallpaperState.reducer.legacyReducer(state.wallpaperState, action),
            telemetryState: HomepageTelemetryState.reducer.legacyReducer(state.telemetryState, action)
        )
    }
```


## Consequences

### Positive Consequences

- `State` struct file size will be shorter with less responsibility.
- There will be a clear top level division of responsibilities to the sub-reducers.
- `@Copyable` macro will now never be used with passthrough reducers.
- Reduced repetition and mental overhead when reading `State` files.

### Neutral Consequences
- N/A

### Negative Consequences

- Developers used to the old architecture will have to navigate a level deeper to see functionality in sub-states in some cases.

