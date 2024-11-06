// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct HomepageState: ScreenState, Equatable {
    var windowUUID: WindowUUID

    // Homepage sections state in the order they appear on the collection view
    var headerState: HeaderState
    var topSitesState: TopSitesSectionState
    var pocketState: PocketState

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
            topSitesState: homepageState.topSitesState,
            pocketState: homepageState.pocketState
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            headerState: HeaderState(windowUUID: windowUUID),
            topSitesState: TopSitesSectionState(windowUUID: windowUUID),
            pocketState: PocketState(windowUUID: windowUUID)
        )
    }

    private init(
        windowUUID: WindowUUID,
        headerState: HeaderState,
        topSitesState: TopSitesSectionState,
        pocketState: PocketState
    ) {
        self.windowUUID = windowUUID
        self.headerState = headerState
        self.topSitesState = topSitesState
        self.pocketState = pocketState
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state, action: action)
        }

        switch action.actionType {
        case HomepageActionType.initialize:
            return HomepageState(
                windowUUID: state.windowUUID,
                headerState: HeaderState.reducer(state.headerState, action),
                topSitesState: TopSitesSectionState.reducer(state.topSitesState, action),
                pocketState: PocketState.reducer(state.pocketState, action)
            )
        default:
            return defaultState(from: state, action: action)
        }
    }

    private static func defaultState(from state: HomepageState, action: Action?) -> HomepageState {
        var headerState = state.headerState
        var pocketState = state.pocketState
        
        if let action {
            headerState = HeaderState.reducer(state.headerState, action)
            pocketState = PocketState.reducer(state.pocketState, action)
        }
        
        return HomepageState(
            windowUUID: state.windowUUID,
            headerState: headerState,
            pocketState: pocketState
        )
    }

    static func defaultState(from state: HomepageState) -> HomepageState {
        return defaultState(from: state, action: nil)
    }
}
