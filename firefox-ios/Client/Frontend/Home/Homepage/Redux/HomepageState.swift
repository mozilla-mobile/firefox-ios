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
    let merinoState: MerinoState
    let wallpaperState: WallpaperState

    let telemetryState: HomepageTelemetryState

    /// `shouldShowPrivacyNotice` is true when the homepage should display the privacy notice card. This is the case when a
    /// new privacy notice is available after a user has already accepted the ToS/ToU
    let shouldShowPrivacyNotice: Bool

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
            merinoState: homepageState.merinoState,
            wallpaperState: homepageState.wallpaperState,
            telemetryState: homepageState.telemetryState,
            shouldShowPrivacyNotice: homepageState.shouldShowPrivacyNotice
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
            merinoState: MerinoState(windowUUID: windowUUID),
            wallpaperState: WallpaperState(windowUUID: windowUUID),
            telemetryState: HomepageTelemetryState(windowUUID: windowUUID),
            shouldShowPrivacyNotice: false,
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
        merinoState: MerinoState,
        wallpaperState: WallpaperState,
        telemetryState: HomepageTelemetryState,
        shouldShowPrivacyNotice: Bool
    ) {
        self.windowUUID = windowUUID
        self.headerState = headerState
        self.messageState = messageState
        self.topSitesState = topSitesState
        self.searchState = searchState
        self.jumpBackInState = jumpBackInState
        self.trackerBlockerModuleState = trackerBlockerModuleState
        self.bookmarkState = bookmarkState
        self.merinoState = merinoState
        self.wallpaperState = wallpaperState
        self.telemetryState = telemetryState
        self.shouldShowPrivacyNotice = shouldShowPrivacyNotice
    }

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, actionWindowUUID in
        // Does not handle any modern actions
        return defaultState(from: state)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return passthroughState(from: state, action: action)
        }

        switch action.actionType {
        case HomepageActionType.initialize, HomepageActionType.viewWillTransition:
            return handleInitializeAndViewWillTransitionAction(state: state, action: action)
        case HomepageActionType.embeddedHomepage:
            guard (action as? HomepageAction)?.isZeroSearch != nil else {
                return defaultState(from: state)
            }

            return handleEmbeddedHomepageAction(state: state, action: action)
        case HomepageActionType.privacyNoticeCloseButtonTapped:
            return handlePrivacyNoticeCloseButtonTappedAction(state: state, action: action)
        case GeneralBrowserActionType.didSelectedTabChangeToHomepage:
            return handleDidTabChangeToHomepageAction(state: state, action: action)
        case HomepageMiddlewareActionType.configuredPrivacyNotice:
            return handlePrivacyNoticeInitialization(action: action, state: state)
        default:
            return passthroughState(from: state, action: action)
        }
    }

    @MainActor
    private static func handleInitializeAndViewWillTransitionAction(state: HomepageState, action: Action) -> HomepageState {
        return state
            .resetTransientState()
            .copy(headerState: HeaderState.reducer.legacyReducer(state.headerState, action))
            .copy(messageState: MessageCardState.reducer.legacyReducer(state.messageState, action))
            .copy(topSitesState: TopSitesSectionState.reducer.legacyReducer(state.topSitesState, action))
            .copy(searchState: SearchBarState.reducer.legacyReducer(state.searchState, action))
            .copy(jumpBackInState: JumpBackInSectionState.reducer.legacyReducer(state.jumpBackInState, action))
            .copy(trackerBlockerModuleState: TrackerBlockerModuleState.reducer
                                             .legacyReducer(state.trackerBlockerModuleState, action))
            .copy(bookmarkState: BookmarksSectionState.reducer.legacyReducer(state.bookmarkState, action))
            .copy(merinoState: MerinoState.reducer.legacyReducer(state.merinoState, action))
            .copy(wallpaperState: WallpaperState.reducer.legacyReducer(state.wallpaperState, action))
            .copy(telemetryState: HomepageTelemetryState.reducer.legacyReducer(state.telemetryState, action))
    }

    @MainActor
    private static func handleEmbeddedHomepageAction(state: HomepageState, action: Action) -> HomepageState {
        return state
            .resetTransientState()
            .copy(headerState: HeaderState.reducer.legacyReducer(state.headerState, action))
            .copy(messageState: MessageCardState.reducer.legacyReducer(state.messageState, action))
            .copy(topSitesState: TopSitesSectionState.reducer.legacyReducer(state.topSitesState, action))
            .copy(searchState: SearchBarState.reducer.legacyReducer(state.searchState, action))
            .copy(jumpBackInState: JumpBackInSectionState.reducer.legacyReducer(state.jumpBackInState, action))
            .copy(trackerBlockerModuleState: TrackerBlockerModuleState.reducer
                                             .legacyReducer(state.trackerBlockerModuleState, action))
            .copy(bookmarkState: BookmarksSectionState.reducer.legacyReducer(state.bookmarkState, action))
            .copy(merinoState: MerinoState.reducer.legacyReducer(state.merinoState, action))
            .copy(wallpaperState: WallpaperState.reducer.legacyReducer(state.wallpaperState, action))
            .copy(telemetryState: HomepageTelemetryState.reducer.legacyReducer(state.telemetryState, action))
    }

    @MainActor
    private static func handlePrivacyNoticeCloseButtonTappedAction(state: HomepageState, action: Action) -> HomepageState {
        return state
            .resetTransientState()
            .copy(headerState: HeaderState.reducer.legacyReducer(state.headerState, action))
            .copy(messageState: MessageCardState.reducer.legacyReducer(state.messageState, action))
            .copy(topSitesState: TopSitesSectionState.reducer.legacyReducer(state.topSitesState, action))
            .copy(searchState: SearchBarState.reducer.legacyReducer(state.searchState, action))
            .copy(jumpBackInState: JumpBackInSectionState.reducer.legacyReducer(state.jumpBackInState, action))
            .copy(trackerBlockerModuleState: TrackerBlockerModuleState.reducer
                                             .legacyReducer(state.trackerBlockerModuleState, action))
            .copy(bookmarkState: BookmarksSectionState.reducer.legacyReducer(state.bookmarkState, action))
            .copy(merinoState: MerinoState.reducer.legacyReducer(state.merinoState, action))
            .copy(wallpaperState: WallpaperState.reducer.legacyReducer(state.wallpaperState, action))
            .copy(telemetryState: HomepageTelemetryState.reducer.legacyReducer(state.telemetryState, action))
            .copy(shouldShowPrivacyNotice: false)
    }

    @MainActor
    private static func handleDidTabChangeToHomepageAction(state: HomepageState, action: Action) -> HomepageState {
        return state
            .resetTransientState()
            .copy(headerState: HeaderState.reducer.legacyReducer(state.headerState, action))
            .copy(messageState: MessageCardState.reducer.legacyReducer(state.messageState, action))
            .copy(topSitesState: TopSitesSectionState.reducer.legacyReducer(state.topSitesState, action))
            .copy(searchState: SearchBarState.reducer.legacyReducer(state.searchState, action))
            .copy(jumpBackInState: JumpBackInSectionState.reducer.legacyReducer(state.jumpBackInState, action))
            .copy(trackerBlockerModuleState: TrackerBlockerModuleState.reducer
                                             .legacyReducer(state.trackerBlockerModuleState, action))
            .copy(bookmarkState: BookmarksSectionState.reducer.legacyReducer(state.bookmarkState, action))
            .copy(merinoState: MerinoState.reducer.legacyReducer(state.merinoState, action))
            .copy(wallpaperState: WallpaperState.reducer.legacyReducer(state.wallpaperState, action))
            .copy(telemetryState: HomepageTelemetryState.reducer.legacyReducer(state.telemetryState, action))
    }

    @MainActor
    private static func handlePrivacyNoticeInitialization(action: Action, state: Self) -> HomepageState {
        return state
            .resetTransientState()
            .copy(headerState: HeaderState.reducer.legacyReducer(state.headerState, action))
            .copy(messageState: MessageCardState.reducer.legacyReducer(state.messageState, action))
            .copy(topSitesState: TopSitesSectionState.reducer.legacyReducer(state.topSitesState, action))
            .copy(searchState: SearchBarState.reducer.legacyReducer(state.searchState, action))
            .copy(jumpBackInState: JumpBackInSectionState.reducer.legacyReducer(state.jumpBackInState, action))
            .copy(trackerBlockerModuleState: TrackerBlockerModuleState.reducer
                                             .legacyReducer(state.trackerBlockerModuleState, action))
            .copy(bookmarkState: BookmarksSectionState.reducer.legacyReducer(state.bookmarkState, action))
            .copy(merinoState: MerinoState.reducer.legacyReducer(state.merinoState, action))
            .copy(wallpaperState: WallpaperState.reducer.legacyReducer(state.wallpaperState, action))
            .copy(telemetryState: HomepageTelemetryState.reducer.legacyReducer(state.telemetryState, action))
            .copy(shouldShowPrivacyNotice: true)
    }

    @MainActor
    private static func passthroughState(from state: HomepageState, action: Action) -> HomepageState {
        return state
            .resetTransientState()
            .copy(headerState: HeaderState.reducer.legacyReducer(state.headerState, action))
            .copy(messageState: MessageCardState.reducer.legacyReducer(state.messageState, action))
            .copy(topSitesState: TopSitesSectionState.reducer.legacyReducer(state.topSitesState, action))
            .copy(searchState: SearchBarState.reducer.legacyReducer(state.searchState, action))
            .copy(jumpBackInState: JumpBackInSectionState.reducer.legacyReducer(state.jumpBackInState, action))
            .copy(trackerBlockerModuleState: TrackerBlockerModuleState.reducer
                                             .legacyReducer(state.trackerBlockerModuleState, action))
            .copy(bookmarkState: BookmarksSectionState.reducer.legacyReducer(state.bookmarkState, action))
            .copy(merinoState: MerinoState.reducer.legacyReducer(state.merinoState, action))
            .copy(wallpaperState: WallpaperState.reducer.legacyReducer(state.wallpaperState, action))
    }

    static func defaultState(from state: HomepageState) -> HomepageState {
        return HomepageState(
            windowUUID: state.windowUUID,
            headerState: HeaderState.defaultState(from: state.headerState),
            messageState: MessageCardState.defaultState(from: state.messageState),
            topSitesState: TopSitesSectionState.defaultState(from: state.topSitesState),
            searchState: SearchBarState.defaultState(from: state.searchState),
            jumpBackInState: JumpBackInSectionState.defaultState(from: state.jumpBackInState),
            trackerBlockerModuleState: TrackerBlockerModuleState.defaultState(from: state.trackerBlockerModuleState),
            bookmarkState: BookmarksSectionState.defaultState(from: state.bookmarkState),
            merinoState: MerinoState.defaultState(from: state.merinoState),
            wallpaperState: WallpaperState.defaultState(from: state.wallpaperState),
            telemetryState: HomepageTelemetryState.defaultState(from: state.telemetryState),
            shouldShowPrivacyNotice: state.shouldShowPrivacyNotice
        )
    }
}
