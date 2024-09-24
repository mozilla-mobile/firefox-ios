// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MenuKit
import Shared
import Redux

struct MainMenuDetailsState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var menuElements: [MenuSection]
    var shouldDismiss: Bool

//    typealias Titles = String.MainMenu.ToolsSection
//    let title = submenuType == .tools ? Titles.Tools : Titles.Save

    var navigationDestination: MainMenuNavigationDestination?

    private let menuConfigurator = MainMenuConfigurationUtility()

    init(appState: AppState, uuid: WindowUUID) {
        guard let currentState = store.state.screenState(
            MainMenuDetailsState.self,
            for: .mainMenuDetails,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(
            windowUUID: currentState.windowUUID,
            menuElements: currentState.menuElements,
            navigationDestination: currentState.navigationDestination,
            shouldDismiss: currentState.shouldDismiss
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            menuElements: [],
            navigationDestination: nil,
            shouldDismiss: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        menuElements: [MenuSection],
        navigationDestination: MainMenuNavigationDestination? = nil,
        shouldDismiss: Bool = false
    ) {
        self.windowUUID = windowUUID
        self.menuElements = menuElements
        self.navigationDestination = navigationDestination
        self.shouldDismiss = shouldDismiss
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case MainMenuDetailsActionType.viewDidLoad:
            guard let menuState = store.state.screenState(
                MainMenuState.self,
                for: .mainMenu,
                window: action.windowUUID),
                  let currentTabInfo = menuState.currentTabInfo,
                  let currentSubmenu = menuState.currentSubmenuView
            else { return state }

            return MainMenuDetailsState(
                windowUUID: state.windowUUID,
                menuElements: state.menuConfigurator.generateMenuElements(
                    with: currentTabInfo,
                    for: currentSubmenu,
                    and: action.windowUUID
                )
            )
        case MainMenuDetailsActionType.dismissView:
            return MainMenuDetailsState(
                windowUUID: state.windowUUID,
                menuElements: state.menuElements,
                shouldDismiss: true
            )
        default:
            return MainMenuDetailsState(
                windowUUID: state.windowUUID,
                menuElements: state.menuElements
            )
        }
    }
}
