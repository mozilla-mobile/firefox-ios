// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ModifiedCopy
import Redux

@Copyable
struct HomepageState: ScreenState, Equatable {
    var windowUUID: WindowUUID

    // Homepage sections state in the order they appear on the collection view
    let headerState: HeaderState
    let messageState: MessageCardState
    let topSitesState: TopSitesSectionState
    let searchState: SearchBarState
    let jumpBackInState: JumpBackInSectionState
    let trackerBlockerModuleState: TrackerBlockerModuleState
    let bookmarkState: BookmarksSectionState
    let worldcupState: WorldCupSectionState
    let merinoState: MerinoState
    let wallpaperState: WallpaperState
    let configurationState: HomepageConfigurationState
    let privacyNoticeState: PrivacyNoticeState

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
            messageState: homepageState.messageState,
            topSitesState: homepageState.topSitesState,
            searchState: homepageState.searchState,
            jumpBackInState: homepageState.jumpBackInState,
            trackerBlockerModuleState: homepageState.trackerBlockerModuleState,
            bookmarkState: homepageState.bookmarkState,
            worldcupState: homepageState.worldcupState,
            merinoState: homepageState.merinoState,
            wallpaperState: homepageState.wallpaperState,
            configurationState: homepageState.configurationState,
            privacyNoticeState: homepageState.privacyNoticeState
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            headerState: HeaderState(windowUUID: windowUUID),
            messageState: MessageCardState(windowUUID: windowUUID),
            topSitesState: TopSitesSectionState(windowUUID: windowUUID),
            searchState: SearchBarState(windowUUID: windowUUID),
            jumpBackInState: JumpBackInSectionState(windowUUID: windowUUID),
            trackerBlockerModuleState: TrackerBlockerModuleState(windowUUID: windowUUID),
            bookmarkState: BookmarksSectionState(windowUUID: windowUUID),
            worldcupState: WorldCupSectionState(windowUUID: windowUUID),
            merinoState: MerinoState(windowUUID: windowUUID),
            wallpaperState: WallpaperState(windowUUID: windowUUID),
            configurationState: HomepageConfigurationState(windowUUID: windowUUID),
            privacyNoticeState: PrivacyNoticeState(windowUUID: windowUUID)
        )
    }

    private init(
        windowUUID: WindowUUID,
        headerState: HeaderState,
        messageState: MessageCardState,
        topSitesState: TopSitesSectionState,
        searchState: SearchBarState,
        jumpBackInState: JumpBackInSectionState,
        trackerBlockerModuleState: TrackerBlockerModuleState,
        bookmarkState: BookmarksSectionState,
        worldcupState: WorldCupSectionState,
        merinoState: MerinoState,
        wallpaperState: WallpaperState,
        configurationState: HomepageConfigurationState,
        privacyNoticeState: PrivacyNoticeState
    ) {
        self.windowUUID = windowUUID
        self.headerState = headerState
        self.messageState = messageState
        self.topSitesState = topSitesState
        self.searchState = searchState
        self.jumpBackInState = jumpBackInState
        self.trackerBlockerModuleState = trackerBlockerModuleState
        self.bookmarkState = bookmarkState
        self.worldcupState = worldcupState
        self.merinoState = merinoState
        self.wallpaperState = wallpaperState
        self.configurationState = configurationState
        self.privacyNoticeState = privacyNoticeState
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
        return state
            .copy(headerState: HeaderState.reducer.legacyReducer(state.headerState, action))
            .copy(messageState: MessageCardState.reducer.legacyReducer(state.messageState, action))
            .copy(topSitesState: TopSitesSectionState.reducer.legacyReducer(state.topSitesState, action))
            .copy(searchState: SearchBarState.reducer.legacyReducer(state.searchState, action))
            .copy(jumpBackInState: JumpBackInSectionState.reducer.legacyReducer(state.jumpBackInState, action))
            .copy(trackerBlockerModuleState: TrackerBlockerModuleState.reducer
                                             .legacyReducer(state.trackerBlockerModuleState, action))
            .copy(bookmarkState: BookmarksSectionState.reducer.legacyReducer(state.bookmarkState, action))
            .copy(worldcupState: WorldCupSectionState.reducer.legacyReducer(state.worldcupState, action))
            .copy(merinoState: MerinoState.reducer.legacyReducer(state.merinoState, action))
            .copy(wallpaperState: WallpaperState.reducer.legacyReducer(state.wallpaperState, action))
            .copy(configurationState: HomepageConfigurationState.reducer.legacyReducer(state.configurationState, action))
            .copy(privacyNoticeState: PrivacyNoticeState.reducer.legacyReducer(state.privacyNoticeState, action))
    }

    static func defaultState(from state: HomepageState) -> HomepageState {
        return state
            .copy(messageState: MessageCardState.defaultState(from: state.messageState))
            .copy(topSitesState: TopSitesSectionState.defaultState(from: state.topSitesState))
            .copy(searchState: SearchBarState.defaultState(from: state.searchState))
            .copy(jumpBackInState: JumpBackInSectionState.defaultState(from: state.jumpBackInState))
            .copy(trackerBlockerModuleState: TrackerBlockerModuleState.defaultState(from: state.trackerBlockerModuleState))
            .copy(bookmarkState: BookmarksSectionState.defaultState(from: state.bookmarkState))
            .copy(worldcupState: WorldCupSectionState.defaultState(from: state.worldcupState))
            .copy(merinoState: MerinoState.defaultState(from: state.merinoState))
            .copy(wallpaperState: WallpaperState.defaultState(from: state.wallpaperState))
            .copy(configurationState: HomepageConfigurationState.defaultState(from: state.configurationState))
            .copy(privacyNoticeState: PrivacyNoticeState.defaultState(from: state.privacyNoticeState))
    }
}
