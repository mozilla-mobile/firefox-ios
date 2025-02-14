// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct HomepageState: ScreenState, Equatable {
    var windowUUID: WindowUUID

    // Homepage sections state in the order they appear on the collection view
    let headerState: HeaderState
    let messageState: MessageCardState
    let topSitesState: TopSitesSectionState
    let jumpBackInState: JumpBackInSectionState
    let bookmarkState: BookmarksSectionState
    let pocketState: PocketState
    let wallpaperState: WallpaperState
    let availableWidth: CGFloat?

    init(appState: AppState, uuid: WindowUUID) {
        guard let homepageState = store.state.screenState(
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
            jumpBackInState: homepageState.jumpBackInState,
            bookmarkState: homepageState.bookmarkState,
            pocketState: homepageState.pocketState,
            wallpaperState: homepageState.wallpaperState,
            availableWidth: homepageState.availableWidth
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            headerState: HeaderState(windowUUID: windowUUID),
            messageState: MessageCardState(windowUUID: windowUUID),
            topSitesState: TopSitesSectionState(windowUUID: windowUUID),
            jumpBackInState: JumpBackInSectionState(windowUUID: windowUUID),
            bookmarkState: BookmarksSectionState(windowUUID: windowUUID),
            pocketState: PocketState(windowUUID: windowUUID),
            wallpaperState: WallpaperState(windowUUID: windowUUID),
            availableWidth: nil
        )
    }

    private init(
        windowUUID: WindowUUID,
        headerState: HeaderState,
        messageState: MessageCardState,
        topSitesState: TopSitesSectionState,
        jumpBackInState: JumpBackInSectionState,
        bookmarkState: BookmarksSectionState,
        pocketState: PocketState,
        wallpaperState: WallpaperState,
        availableWidth: CGFloat? = nil
    ) {
        self.windowUUID = windowUUID
        self.headerState = headerState
        self.messageState = messageState
        self.topSitesState = topSitesState
        self.jumpBackInState = jumpBackInState
        self.bookmarkState = bookmarkState
        self.pocketState = pocketState
        self.wallpaperState = wallpaperState
        self.availableWidth = availableWidth
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state, action: action)
        }

        switch action.actionType {
        case HomepageActionType.initialize, ViewLifecycleActionType.viewWillTransition:

            var width: CGFloat?
            if let homepageAction = action as? HomepageAction {
                width = homepageAction.availableWidth
            } else if let viewAction = action as? ViewLifecycleAction {
                width = viewAction.size?.width
            }

            guard let width else { return defaultState(from: state) }

            return HomepageState(
                windowUUID: state.windowUUID,
                headerState: HeaderState.reducer(state.headerState, action),
                messageState: MessageCardState.reducer(state.messageState, action),
                topSitesState: TopSitesSectionState.reducer(state.topSitesState, action),
                jumpBackInState: JumpBackInSectionState.reducer(state.jumpBackInState, action),
                bookmarkState: BookmarksSectionState.reducer(state.bookmarkState, action),
                pocketState: PocketState.reducer(state.pocketState, action),
                wallpaperState: WallpaperState.reducer(state.wallpaperState, action),
                availableWidth: width
            )
        default:
            return defaultState(from: state, action: action)
        }
    }

    private static func defaultState(from state: HomepageState, action: Action?) -> HomepageState {
        var headerState = state.headerState
        var messageState = state.messageState
        var pocketState = state.pocketState
        var topSitesState = state.topSitesState
        var jumpBackInState = state.jumpBackInState
        var bookmarkState = state.bookmarkState
        var wallpaperState = state.wallpaperState

        if let action {
            headerState = HeaderState.reducer(state.headerState, action)
            messageState = MessageCardState.reducer(state.messageState, action)
            pocketState = PocketState.reducer(state.pocketState, action)
            jumpBackInState = JumpBackInSectionState.reducer(state.jumpBackInState, action)
            bookmarkState = BookmarksSectionState.reducer(state.bookmarkState, action)
            topSitesState = TopSitesSectionState.reducer(state.topSitesState, action)
            wallpaperState = WallpaperState.reducer(state.wallpaperState, action)
        }

        return HomepageState(
            windowUUID: state.windowUUID,
            headerState: headerState,
            messageState: messageState,
            topSitesState: topSitesState,
            jumpBackInState: jumpBackInState,
            bookmarkState: bookmarkState,
            pocketState: pocketState,
            wallpaperState: wallpaperState,
            availableWidth: state.availableWidth
        )
    }

    static func defaultState(from state: HomepageState) -> HomepageState {
        return defaultState(from: state, action: nil)
    }
}
