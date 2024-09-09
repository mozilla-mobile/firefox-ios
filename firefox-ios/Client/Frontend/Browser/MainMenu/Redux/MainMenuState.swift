// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MenuKit
import Shared
import Redux

struct MainMenuState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var menuElements: [[MenuElement]]
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
            menuElements: mainMenuState.menuElements,
            shouldDismiss: mainMenuState.shouldDismiss
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            menuElements: [],
            shouldDismiss: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        menuElements: [[MenuElement]],
        shouldDismiss: Bool
    ) {
        self.windowUUID = windowUUID
        self.shouldDismiss = shouldDismiss
        self.menuElements = MainMenuConfigurationUtility().populateMenuElements(with: windowUUID)
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case MainMenuActionType.viewDidLoad:
            return MainMenuState(
                windowUUID: state.windowUUID,
                menuElements: state.menuElements,
                shouldDismiss: false
            )
        case MainMenuActionType.closeMenu:
            return MainMenuState(
                windowUUID: state.windowUUID,
                menuElements: state.menuElements,
                shouldDismiss: true
            )
        default:
            return MainMenuState(
                windowUUID: state.windowUUID,
                menuElements: state.menuElements,
                shouldDismiss: false
            )
        }
    }
}

struct MainMenuConfigurationUtility {
    func populateMenuElements(with uuid: WindowUUID) -> [[MenuElement]] {
        let fakeMenuItem = MenuElement(
            title: "Test title",
            iconName: "",
            isEnabled: true,
            isActive: false,
            a11yLabel: "",
            a11yHint: "",
            a11yId: "",
            action: {
                store.dispatch(
                    MainMenuAction(
                        windowUUID: uuid,
                        actionType: MainMenuActionType.closeMenu
                    )
                )
            }
        )

        return [
            [fakeMenuItem, fakeMenuItem],
            [fakeMenuItem, fakeMenuItem, fakeMenuItem, fakeMenuItem, fakeMenuItem],
            [fakeMenuItem, fakeMenuItem, fakeMenuItem, fakeMenuItem, fakeMenuItem],
            [fakeMenuItem, fakeMenuItem, fakeMenuItem, fakeMenuItem, fakeMenuItem],
            [fakeMenuItem, fakeMenuItem],
        ]
    }
}
