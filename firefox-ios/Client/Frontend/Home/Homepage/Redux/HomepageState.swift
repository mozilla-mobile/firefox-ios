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

    let shouldTriggerImpression: Bool

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
            worldcupState: homepageState.worldcupState,
            merinoState: homepageState.merinoState,
            wallpaperState: homepageState.wallpaperState,
            shouldTriggerImpression: homepageState.shouldTriggerImpression,
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
            worldcupState: WorldCupSectionState(windowUUID: windowUUID),
            merinoState: MerinoState(windowUUID: windowUUID),
            wallpaperState: WallpaperState(windowUUID: windowUUID),
            shouldTriggerImpression: false,
            shouldShowPrivacyNotice: false
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
        shouldTriggerImpression: Bool,
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
        self.worldcupState = worldcupState
        self.merinoState = merinoState
        self.wallpaperState = wallpaperState
        self.shouldTriggerImpression = shouldTriggerImpression
        self.shouldShowPrivacyNotice = shouldShowPrivacyNotice
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return passthroughState(from: state, action: action)
        }

        switch action.actionType {
        case HomepageActionType.initialize, HomepageActionType.viewWillTransition:
            return handleInitializeAndViewWillTransitionAction(state: state, action: action)
        case HomepageActionType.embeddedHomepage:
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
            .copy(messageState: MessageCardState.reducer(state.messageState, action))
            .copy(topSitesState: TopSitesSectionState.reducer(state.topSitesState, action))
            .copy(searchState: SearchBarState.reducer(state.searchState, action))
            .copy(jumpBackInState: JumpBackInSectionState.reducer(state.jumpBackInState, action))
            .copy(trackerBlockerModuleState: TrackerBlockerModuleState.reducer(state.trackerBlockerModuleState, action))
            .copy(bookmarkState: BookmarksSectionState.reducer(state.bookmarkState, action))
            .copy(worldcupState: WorldCupSectionState.reducer(state.worldcupState, action))
            .copy(merinoState: MerinoState.reducer(state.merinoState, action))
            .copy(wallpaperState: WallpaperState.reducer(state.wallpaperState, action))
            .copy(shouldTriggerImpression: false)
    }

    @MainActor
    private static func handleEmbeddedHomepageAction(state: HomepageState, action: Action) -> HomepageState {
        return state
            .copy(messageState: MessageCardState.reducer(state.messageState, action))
            .copy(topSitesState: TopSitesSectionState.reducer(state.topSitesState, action))
            .copy(searchState: SearchBarState.reducer(state.searchState, action))
            .copy(jumpBackInState: JumpBackInSectionState.reducer(state.jumpBackInState, action))
            .copy(trackerBlockerModuleState: TrackerBlockerModuleState.reducer(state.trackerBlockerModuleState, action))
            .copy(bookmarkState: BookmarksSectionState.reducer(state.bookmarkState, action))
            .copy(worldcupState: WorldCupSectionState.reducer(state.worldcupState, action))
            .copy(merinoState: MerinoState.reducer(state.merinoState, action))
            .copy(wallpaperState: WallpaperState.reducer(state.wallpaperState, action))
            .copy(shouldTriggerImpression: false)
    }

    @MainActor
    private static func handlePrivacyNoticeCloseButtonTappedAction(state: HomepageState, action: Action) -> HomepageState {
        return state
            .copy(messageState: MessageCardState.reducer(state.messageState, action))
            .copy(topSitesState: TopSitesSectionState.reducer(state.topSitesState, action))
            .copy(searchState: SearchBarState.reducer(state.searchState, action))
            .copy(jumpBackInState: JumpBackInSectionState.reducer(state.jumpBackInState, action))
            .copy(trackerBlockerModuleState: TrackerBlockerModuleState.reducer(state.trackerBlockerModuleState, action))
            .copy(bookmarkState: BookmarksSectionState.reducer(state.bookmarkState, action))
            .copy(worldcupState: WorldCupSectionState.reducer(state.worldcupState, action))
            .copy(merinoState: MerinoState.reducer(state.merinoState, action))
            .copy(wallpaperState: WallpaperState.reducer(state.wallpaperState, action))
            .copy(shouldTriggerImpression: false)
            .copy(shouldShowPrivacyNotice: false)
    }

    @MainActor
    private static func handleDidTabChangeToHomepageAction(state: HomepageState, action: Action) -> HomepageState {
        return state
            .copy(messageState: MessageCardState.reducer(state.messageState, action))
            .copy(topSitesState: TopSitesSectionState.reducer(state.topSitesState, action))
            .copy(searchState: SearchBarState.reducer(state.searchState, action))
            .copy(jumpBackInState: JumpBackInSectionState.reducer(state.jumpBackInState, action))
            .copy(trackerBlockerModuleState: TrackerBlockerModuleState.reducer(state.trackerBlockerModuleState, action))
            .copy(bookmarkState: BookmarksSectionState.reducer(state.bookmarkState, action))
            .copy(worldcupState: WorldCupSectionState.reducer(state.worldcupState, action))
            .copy(merinoState: MerinoState.reducer(state.merinoState, action))
            .copy(wallpaperState: WallpaperState.reducer(state.wallpaperState, action))
            .copy(shouldTriggerImpression: true)
    }

    @MainActor
    private static func handlePrivacyNoticeInitialization(action: Action, state: Self) -> HomepageState {
        return state
            .copy(messageState: MessageCardState.reducer(state.messageState, action))
            .copy(topSitesState: TopSitesSectionState.reducer(state.topSitesState, action))
            .copy(searchState: SearchBarState.reducer(state.searchState, action))
            .copy(jumpBackInState: JumpBackInSectionState.reducer(state.jumpBackInState, action))
            .copy(trackerBlockerModuleState: TrackerBlockerModuleState.reducer(state.trackerBlockerModuleState, action))
            .copy(bookmarkState: BookmarksSectionState.reducer(state.bookmarkState, action))
            .copy(worldcupState: WorldCupSectionState.reducer(state.worldcupState, action))
            .copy(merinoState: MerinoState.reducer(state.merinoState, action))
            .copy(wallpaperState: WallpaperState.reducer(state.wallpaperState, action))
            .copy(shouldTriggerImpression: false)
            .copy(shouldShowPrivacyNotice: true)
    }

    @MainActor
    private static func passthroughState(from state: HomepageState, action: Action) -> HomepageState {
        return state
            .copy(messageState: MessageCardState.reducer(state.messageState, action))
            .copy(topSitesState: TopSitesSectionState.reducer(state.topSitesState, action))
            .copy(searchState: SearchBarState.reducer(state.searchState, action))
            .copy(jumpBackInState: JumpBackInSectionState.reducer(state.jumpBackInState, action))
            .copy(trackerBlockerModuleState: TrackerBlockerModuleState.reducer(state.trackerBlockerModuleState, action))
            .copy(bookmarkState: BookmarksSectionState.reducer(state.bookmarkState, action))
            .copy(worldcupState: WorldCupSectionState.reducer(state.worldcupState, action))
            .copy(merinoState: MerinoState.reducer(state.merinoState, action))
            .copy(wallpaperState: WallpaperState.reducer(state.wallpaperState, action))
            .copy(shouldTriggerImpression: false)
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
            .copy(shouldTriggerImpression: false)
    }
}
