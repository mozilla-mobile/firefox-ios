// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Redux

struct MainMenuState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var shouldDismiss: Bool

    init(appState: AppState, uuid: WindowUUID) {
        guard let mainMenuState = store.state.screenState(
            MainMenuState.self,
            for: .mainMenu,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(
            windowUUID: mainMenuState.windowUUID,
            shouldDismiss: mainMenuState.shouldDismiss
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            shouldDismiss: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        shouldDismiss: Bool
    ) {
        self.windowUUID = windowUUID
        self.shouldDismiss = shouldDismiss
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case MainMenuMiddlewareActionType.dismissMenu:
            return MainMenuState(
                windowUUID: state.windowUUID,
                shouldDismiss: true
            )
        default:
            return MainMenuState(
                windowUUID: state.windowUUID,
                shouldDismiss: false
            )
        }
    }
}
