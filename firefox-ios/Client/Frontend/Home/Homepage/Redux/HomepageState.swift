// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ModifiedCopy
import Redux

struct HomepageState: ScreenState, Equatable {
    var windowUUID: WindowUUID

    // Homepage sections state in the order they appear on the collection view
    let headerState: HeaderState
    let privacyNoticeState: PrivacyNoticeState
    let messageState: MessageCardState
    let topSitesState: TopSitesSectionState
    let searchBarState: SearchBarState
    let jumpBackInState: JumpBackInSectionState
    let trackerBlockerModuleState: TrackerBlockerModuleState
    let bookmarkState: BookmarksSectionState
    let merinoState: MerinoState
    let wallpaperState: WallpaperState
    let telemetryState: HomepageTelemetryState

    init(appState: AppState, uuid: WindowUUID) {
        guard let homepageState = appState.componentState(
            HomepageState.self,
            for: .homepage,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(
            windowUUID: homepageState.windowUUID,
            headerState: homepageState.headerState,
            privacyNoticeState: homepageState.privacyNoticeState,
            messageState: homepageState.messageState,
            topSitesState: homepageState.topSitesState,
            searchBarState: homepageState.searchBarState,
            jumpBackInState: homepageState.jumpBackInState,
            trackerBlockerModuleState: homepageState.trackerBlockerModuleState,
            bookmarkState: homepageState.bookmarkState,
            merinoState: homepageState.merinoState,
            wallpaperState: homepageState.wallpaperState,
            telemetryState: homepageState.telemetryState
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            headerState: HeaderState(windowUUID: windowUUID),
            privacyNoticeState: PrivacyNoticeState(windowUUID: windowUUID),
            messageState: MessageCardState(windowUUID: windowUUID),
            topSitesState: TopSitesSectionState(windowUUID: windowUUID),
            searchBarState: SearchBarState(windowUUID: windowUUID),
            jumpBackInState: JumpBackInSectionState(windowUUID: windowUUID),
            trackerBlockerModuleState: TrackerBlockerModuleState(windowUUID: windowUUID),
            bookmarkState: BookmarksSectionState(windowUUID: windowUUID),
            merinoState: MerinoState(windowUUID: windowUUID),
            wallpaperState: WallpaperState(windowUUID: windowUUID),
            telemetryState: HomepageTelemetryState(windowUUID: windowUUID)
        )
    }

    private init(
        windowUUID: WindowUUID,
        headerState: HeaderState,
        privacyNoticeState: PrivacyNoticeState,
        messageState: MessageCardState,
        topSitesState: TopSitesSectionState,
        searchBarState: SearchBarState,
        jumpBackInState: JumpBackInSectionState,
        trackerBlockerModuleState: TrackerBlockerModuleState,
        bookmarkState: BookmarksSectionState,
        merinoState: MerinoState,
        wallpaperState: WallpaperState,
        telemetryState: HomepageTelemetryState
    ) {
        self.windowUUID = windowUUID
        self.headerState = headerState
        self.privacyNoticeState = privacyNoticeState
        self.messageState = messageState
        self.topSitesState = topSitesState
        self.searchBarState = searchBarState
        self.jumpBackInState = jumpBackInState
        self.trackerBlockerModuleState = trackerBlockerModuleState
        self.bookmarkState = bookmarkState
        self.merinoState = merinoState
        self.wallpaperState = wallpaperState
        self.telemetryState = telemetryState
    }

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, actionWindowUUID in
        // Does not handle any modern actions
        return defaultState(from: state)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
        return passthroughState(from: state, action: action)
    }

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

    static func defaultState(from state: HomepageState) -> HomepageState {
        return HomepageState(
            windowUUID: state.windowUUID,
            headerState: HeaderState.defaultState(from: state.headerState),
            privacyNoticeState: PrivacyNoticeState.defaultState(from: state.privacyNoticeState),
            messageState: MessageCardState.defaultState(from: state.messageState),
            topSitesState: TopSitesSectionState.defaultState(from: state.topSitesState),
            searchBarState: SearchBarState.defaultState(from: state.searchBarState),
            jumpBackInState: JumpBackInSectionState.defaultState(from: state.jumpBackInState),
            trackerBlockerModuleState: TrackerBlockerModuleState.defaultState(from: state.trackerBlockerModuleState),
            bookmarkState: BookmarksSectionState.defaultState(from: state.bookmarkState),
            merinoState: MerinoState.defaultState(from: state.merinoState),
            wallpaperState: WallpaperState.defaultState(from: state.wallpaperState),
            telemetryState: HomepageTelemetryState.defaultState(from: state.telemetryState)
        )
    }
}
