// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct HomepageState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var headerState: HeaderState
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
            pocketState: homepageState.pocketState
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
        pocketState: PocketState
    ) {
        self.windowUUID = windowUUID
        self.headerState = headerState
        self.pocketState = pocketState
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultActionState(from: state, action: action)
        }

        switch action.actionType {
        case HomepageActionType.initialize:
            return HomepageState(
                windowUUID: state.windowUUID,
                headerState: HeaderState.reducer(state.headerState, action),
                pocketState: PocketState.reducer(state.pocketState, action)
            )
        default:
            return defaultActionState(from: state, action: action)
        }
    }

    private static func defaultActionState(from state: HomepageState, action: Action) -> HomepageState {
        let defaultState = defaultState(from: state)
        return HomepageState(windowUUID: defaultState.windowUUID,
                             headerState: HeaderState.reducer(state.headerState, action),
                             pocketState: PocketState.reducer(state.pocketState, action))
    }

    static func defaultState(from state: HomepageState) -> HomepageState {
        // since the default state would depend on other reducers use `defaultActionState(for: ,action:)`
        // as method for default action state
        return HomepageState(
            windowUUID: state.windowUUID,
            headerState: state.headerState,
            pocketState: state.pocketState
        )
    }
}
