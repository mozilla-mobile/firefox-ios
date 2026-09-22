# 14. Structure Redux to use Passthrough Reducers to Delegate Actions to Subcomponents

Date: 2026-10-06

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

This means that these top level `ScreenState` files could get very bloated with logic in addition to handle reducer actions. Before refactoring `HomepageState` about 85% of the file was duplicated property forwarding.

There was also a mix of the `ScreenState` handling actions itself and it's sub `StateType`s handling actions, this decreased clarity when reading and working on the project.


## Decision

In the future `ScreenState` classes will have the following rules:

1. `ScreenState` will function as a parent state that hold multiple `StateType` classes that handle Redux Actions.

1. `ScreenState` should not have action handling itself and instead delgate to `StateType`

1. Every property that could theoretically belong to `ScreenState` should instead belong to a sub-state of `StateType`. It is fine to create a new sub-state to handle a set of responsibilities for the screen.

1. The `ScreenState` will now have a single passthrough reducer to forward actions on to the subreducers.

####Example:
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

- `ScreenState` struct file size will be shorter with less responsibility.
- There will be a clear top level division of responsibilities to the sub-reducers.
- `@Copyable` macro will no longer be needed and reduce repetition and mental overhead when reading `ScreenState` files.

### Negative Consequences

- Developers used to the old architecture will have to navigate a level deeper to see functionality in sub-states in some cases.

