// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct HomepageState: ScreenState, Equatable {
    enum NavigationDestination {
        case customizeHomepage
    }

    var windowUUID: WindowUUID
    var headerState: HeaderState
    var pocketState: PocketState
    var navigateTo: NavigationDestination?

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
            pocketState: homepageState.pocketState,
            navigateTo: homepageState.navigateTo
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            headerState: HeaderState(windowUUID: windowUUID),
            pocketState: PocketState(windowUUID: windowUUID)
        )
    }

    private init(
        windowUUID: WindowUUID,
        headerState: HeaderState,
        pocketState: PocketState,
        navigateTo: NavigationDestination? = nil
    ) {
        self.windowUUID = windowUUID
        self.headerState = headerState
        self.pocketState = pocketState
        self.navigateTo = navigateTo
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return HomepageState(
                windowUUID: state.windowUUID,
                headerState: HeaderState.reducer(state.headerState, action),
                pocketState: PocketState.reducer(state.pocketState, action)
            )
        }

        switch action.actionType {
        case HomepageActionType.initialize:
            return HomepageState(
                windowUUID: state.windowUUID,
                headerState: HeaderState.reducer(state.headerState, action),
                pocketState: PocketState.reducer(state.pocketState, action)
            )
        case HomepageActionType.tappedOnCustomizeHomepage:
            return HomepageState(
                windowUUID: state.windowUUID,
                headerState: HeaderState.reducer(state.headerState, action),
                pocketState: PocketState.reducer(state.pocketState, action),
                navigateTo: .customizeHomepage
            )
        default:
            return HomepageState(
                windowUUID: state.windowUUID,
                headerState: HeaderState.reducer(state.headerState, action),
                pocketState: PocketState.reducer(state.pocketState, action)
            )
        }
    }
}
