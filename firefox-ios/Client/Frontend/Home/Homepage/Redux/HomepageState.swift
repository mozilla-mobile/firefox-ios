// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CopyWithUpdates
import Redux

@CopyWithUpdates
struct HomepageState: ScreenState, Equatable {
    var windowUUID: WindowUUID

    // Homepage sections state in the order they appear on the collection view
    let headerState: HeaderState
    let messageState: MessageCardState
    let topSitesState: TopSitesSectionState
    let searchState: SearchBarState
    let jumpBackInState: JumpBackInSectionState
    let bookmarkState: BookmarksSectionState
    let worldcupState: WorldcupSectionState
    let merinoState: MerinoState
    let wallpaperState: WallpaperState

    /// FXIOS-11504 - This is mainly used for telemetry for top sites and merino and presenting CFRs.
    /// At this time, we are keeping `isZeroSearch` the same as legacy. However, we should revisit this value
    /// and confirm what the expectation is, as it seems inconsistent. See more details in ticket.
    ///
    /// FXIOS-6203 - Comment from legacy homepage:
    /// `isZeroSearch` is true when the homepage is created from the tab tray, a long press
    /// on the tab bar to open a new tab or by pressing the home page button on the tab bar.
    /// The zero search page, aka when the home page is shown by clicking the url bar from a loaded web page.
    /// This needs to be set properly for telemetry and the contextual pop overs that appears on homepage
    let isZeroSearch: Bool
    let shouldTriggerImpression: Bool

    /// `shouldShowPrivacyNotice` is true when the homepage should display the privacy notice card. This is the case when a
    /// new privacy notice is available after a user has already accepted the ToS/ToU
    let shouldShowPrivacyNotice: Bool

    /// `availableContentHeight` represents the height available for the homepage content to occupy when the address is not
    /// being edited. This is used to keep the homepage layout constant, such that it doesn't shift when the homepage's
    /// view size changes eg when the address bar is tapped and the keyboard is presented. This value is kept in state
    /// because it is determined by BVC
    let availableContentHeight: CGFloat

    /// `availableWallpaperHeight` is the height to apply to the homepage wallpaper background so it can remain pinned to
    /// the top of the window while still extending to the same visual bottom as the homepage content.
    let availableWallpaperHeight: CGFloat

    init(appState: AppState, uuid: WindowUUID) {
        guard let homepageState = appState.componentState(
            HomepageState.self,
            for: .homepage,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self = homepageState.copyWithUpdates()
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            headerState: HeaderState(windowUUID: windowUUID),
            messageState: MessageCardState(windowUUID: windowUUID),
            topSitesState: TopSitesSectionState(windowUUID: windowUUID),
            searchState: SearchBarState(windowUUID: windowUUID),
            jumpBackInState: JumpBackInSectionState(windowUUID: windowUUID),
            bookmarkState: BookmarksSectionState(windowUUID: windowUUID),
            worldcupState: WorldcupSectionState(windowUUID: windowUUID),
            merinoState: MerinoState(windowUUID: windowUUID),
            wallpaperState: WallpaperState(windowUUID: windowUUID),
            isZeroSearch: false,
            shouldTriggerImpression: false,
            shouldShowPrivacyNotice: false,
            availableContentHeight: 0,
            availableWallpaperHeight: 0
        )
    }

    private init(
        windowUUID: WindowUUID,
        headerState: HeaderState,
        messageState: MessageCardState,
        topSitesState: TopSitesSectionState,
        searchState: SearchBarState,
        jumpBackInState: JumpBackInSectionState,
        bookmarkState: BookmarksSectionState,
        worldcupState: WorldcupSectionState,
        merinoState: MerinoState,
        wallpaperState: WallpaperState,
        isZeroSearch: Bool,
        shouldTriggerImpression: Bool,
        shouldShowPrivacyNotice: Bool,
        availableContentHeight: CGFloat,
        availableWallpaperHeight: CGFloat
    ) {
        self.windowUUID = windowUUID
        self.headerState = headerState
        self.messageState = messageState
        self.topSitesState = topSitesState
        self.searchState = searchState
        self.jumpBackInState = jumpBackInState
        self.bookmarkState = bookmarkState
        self.worldcupState = worldcupState
        self.merinoState = merinoState
        self.wallpaperState = wallpaperState
        self.isZeroSearch = isZeroSearch
        self.shouldTriggerImpression = shouldTriggerImpression
        self.shouldShowPrivacyNotice = shouldShowPrivacyNotice
        self.availableContentHeight = availableContentHeight
        self.availableWallpaperHeight = availableWallpaperHeight
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
            guard let isZeroSearch = (action as? HomepageAction)?.isZeroSearch else {
                return defaultState(from: state)
            }

            return handleEmbeddedHomepageAction(state: state, action: action, isZeroSearch: isZeroSearch)
        case HomepageActionType.availableContentHeightDidChange:
            return handleAvailableContentHeightChangeAction(state: state, action: action)
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
        return state.copyWithUpdates(
            headerState: HeaderState.reducer(state.headerState, action),
            messageState: MessageCardState.reducer(state.messageState, action),
            topSitesState: TopSitesSectionState.reducer(state.topSitesState, action),
            searchState: SearchBarState.reducer(state.searchState, action),
            jumpBackInState: JumpBackInSectionState.reducer(state.jumpBackInState, action),
            bookmarkState: BookmarksSectionState.reducer(state.bookmarkState, action),
            worldcupState: WorldcupSectionState.reducer(state.worldcupState, action),
            merinoState: MerinoState.reducer(state.merinoState, action),
            wallpaperState: WallpaperState.reducer(state.wallpaperState, action),
            shouldTriggerImpression: false
        )
    }

    @MainActor
    private static func handleEmbeddedHomepageAction(state: HomepageState,
                                                     action: Action,
                                                     isZeroSearch: Bool) -> HomepageState {
        return state.copyWithUpdates(
            headerState: HeaderState.reducer(state.headerState, action),
            messageState: MessageCardState.reducer(state.messageState, action),
            topSitesState: TopSitesSectionState.reducer(state.topSitesState, action),
            searchState: SearchBarState.reducer(state.searchState, action),
            jumpBackInState: JumpBackInSectionState.reducer(state.jumpBackInState, action),
            bookmarkState: BookmarksSectionState.reducer(state.bookmarkState, action),
            worldcupState: WorldcupSectionState.reducer(state.worldcupState, action),
            merinoState: MerinoState.reducer(state.merinoState, action),
            wallpaperState: WallpaperState.reducer(state.wallpaperState, action),
            isZeroSearch: isZeroSearch,
            shouldTriggerImpression: false
        )
    }

    @MainActor
    private static func handleAvailableContentHeightChangeAction(state: HomepageState, action: Action) -> HomepageState {
        guard let homepageAction = action as? HomepageAction else {
            return defaultState(from: state)
        }

        // Height updates can arrive with only one field populated; keep the other value stable.
        let availableContentHeight = homepageAction.availableContentHeight ?? state.availableContentHeight
        let availableWallpaperHeight = homepageAction.availableWallpaperHeight ?? state.availableWallpaperHeight

         return state.copyWithUpdates(
            headerState: HeaderState.reducer(state.headerState, action),
            messageState: MessageCardState.reducer(state.messageState, action),
            topSitesState: TopSitesSectionState.reducer(state.topSitesState, action),
            searchState: SearchBarState.reducer(state.searchState, action),
            jumpBackInState: JumpBackInSectionState.reducer(state.jumpBackInState, action),
            bookmarkState: BookmarksSectionState.reducer(state.bookmarkState, action),
            worldcupState: WorldcupSectionState.reducer(state.worldcupState, action),
            merinoState: MerinoState.reducer(state.merinoState, action),
            wallpaperState: WallpaperState.reducer(state.wallpaperState, action),
            shouldTriggerImpression: false,
            availableContentHeight: availableContentHeight,
            availableWallpaperHeight: availableWallpaperHeight
        )
    }

    @MainActor
    private static func handlePrivacyNoticeCloseButtonTappedAction(state: HomepageState, action: Action) -> HomepageState {
        return state.copyWithUpdates(
            headerState: HeaderState.reducer(state.headerState, action),
            messageState: MessageCardState.reducer(state.messageState, action),
            topSitesState: TopSitesSectionState.reducer(state.topSitesState, action),
            searchState: SearchBarState.reducer(state.searchState, action),
            jumpBackInState: JumpBackInSectionState.reducer(state.jumpBackInState, action),
            bookmarkState: BookmarksSectionState.reducer(state.bookmarkState, action),
            worldcupState: WorldcupSectionState.reducer(state.worldcupState, action),
            merinoState: MerinoState.reducer(state.merinoState, action),
            wallpaperState: WallpaperState.reducer(state.wallpaperState, action),
            shouldTriggerImpression: false,
            shouldShowPrivacyNotice: false
        )
    }

    @MainActor
    private static func handleDidTabChangeToHomepageAction(state: HomepageState, action: Action) -> HomepageState {
        return state.copyWithUpdates(
            headerState: HeaderState.reducer(state.headerState, action),
            messageState: MessageCardState.reducer(state.messageState, action),
            topSitesState: TopSitesSectionState.reducer(state.topSitesState, action),
            searchState: SearchBarState.reducer(state.searchState, action),
            jumpBackInState: JumpBackInSectionState.reducer(state.jumpBackInState, action),
            bookmarkState: BookmarksSectionState.reducer(state.bookmarkState, action),
            worldcupState: WorldcupSectionState.reducer(state.worldcupState, action),
            merinoState: MerinoState.reducer(state.merinoState, action),
            wallpaperState: WallpaperState.reducer(state.wallpaperState, action),
            shouldTriggerImpression: true
        )
    }

    @MainActor
    private static func handlePrivacyNoticeInitialization(action: Action, state: Self) -> HomepageState {
        return state.copyWithUpdates(
            headerState: HeaderState.reducer(state.headerState, action),
            messageState: MessageCardState.reducer(state.messageState, action),
            topSitesState: TopSitesSectionState.reducer(state.topSitesState, action),
            searchState: SearchBarState.reducer(state.searchState, action),
            jumpBackInState: JumpBackInSectionState.reducer(state.jumpBackInState, action),
            bookmarkState: BookmarksSectionState.reducer(state.bookmarkState, action),
            worldcupState: WorldcupSectionState.reducer(state.worldcupState, action),
            merinoState: MerinoState.reducer(state.merinoState, action),
            wallpaperState: WallpaperState.reducer(state.wallpaperState, action),
            shouldTriggerImpression: false,
            shouldShowPrivacyNotice: true
        )
    }

    @MainActor
    private static func passthroughState(from state: HomepageState, action: Action) -> HomepageState {
        return state.copyWithUpdates(
            headerState: HeaderState.reducer(state.headerState, action),
            messageState: MessageCardState.reducer(state.messageState, action),
            topSitesState: TopSitesSectionState.reducer(state.topSitesState, action),
            searchState: SearchBarState.reducer(state.searchState, action),
            jumpBackInState: JumpBackInSectionState.reducer(state.jumpBackInState, action),
            bookmarkState: BookmarksSectionState.reducer(state.bookmarkState, action),
            worldcupState: WorldcupSectionState.reducer(state.worldcupState, action),
            merinoState: MerinoState.reducer(state.merinoState, action),
            wallpaperState: WallpaperState.reducer(state.wallpaperState, action),
            shouldTriggerImpression: false
        )
    }

    static func defaultState(from state: HomepageState) -> HomepageState {
        return state.copyWithUpdates(
            messageState: MessageCardState.defaultState(from: state.messageState),
            topSitesState: TopSitesSectionState.defaultState(from: state.topSitesState),
            searchState: SearchBarState.defaultState(from: state.searchState),
            jumpBackInState: JumpBackInSectionState.defaultState(from: state.jumpBackInState),
            bookmarkState: BookmarksSectionState.defaultState(from: state.bookmarkState),
            worldcupState: WorldcupSectionState.defaultState(from: state.worldcupState),
            merinoState: MerinoState.defaultState(from: state.merinoState),
            wallpaperState: WallpaperState.defaultState(from: state.wallpaperState),
            shouldTriggerImpression: false
        )
    }
}
