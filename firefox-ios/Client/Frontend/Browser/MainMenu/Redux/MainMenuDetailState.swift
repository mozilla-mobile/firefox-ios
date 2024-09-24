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
    var currentTabInfo: MainMenuTabInfo?
    var shouldDismiss: Bool

    var navigationDestination: MainMenuNavigationDestination?
    var submenuType: MainMenuDetailsViewType?

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
            submenuType: currentState.submenuType,
            menuElements: currentState.menuElements,
            currentTabInfo: currentState.currentTabInfo,
            navigationDestination: currentState.navigationDestination,
            shouldDismiss: currentState.shouldDismiss
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            submenuType: nil,
            menuElements: [],
            currentTabInfo: nil,
            navigationDestination: nil,
            shouldDismiss: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        submenuType: MainMenuDetailsViewType?,
        menuElements: [MenuSection],
        currentTabInfo: MainMenuTabInfo?,
        navigationDestination: MainMenuNavigationDestination? = nil,
        shouldDismiss: Bool = false
    ) {
        self.windowUUID = windowUUID
        self.menuElements = menuElements
        self.currentTabInfo = currentTabInfo
        self.navigationDestination = navigationDestination
        self.shouldDismiss = shouldDismiss
        self.submenuType = submenuType
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case MainMenuDetailsActionType.viewDidLoad:
            return MainMenuDetailsState(
                windowUUID: state.windowUUID,
                submenuType: state.submenuType,
                menuElements: state.menuElements,
                currentTabInfo: state.currentTabInfo
            )
        case MainMenuActionType.updateCurrentTabInfo:
            guard let action = action as? MainMenuAction else { return state }

            return MainMenuDetailsState(
                windowUUID: state.windowUUID,
                submenuType: state.submenuType,
                menuElements: state.menuElements,
                currentTabInfo: action.currentTabInfo
            )
        case MainMenuDetailsActionType.updateSubmenuType(let type):
            return MainMenuDetailsState(
                windowUUID: state.windowUUID,
                submenuType: type,
                menuElements: state.menuConfigurator.getSubmenuFor(
                    type: type,
                    with: state.windowUUID
                ),
                currentTabInfo: state.currentTabInfo
            )
        case MainMenuDetailsActionType.dismissView:
            return MainMenuDetailsState(
                windowUUID: state.windowUUID,
                submenuType: state.submenuType,
                menuElements: state.menuElements,
                currentTabInfo: state.currentTabInfo,
                shouldDismiss: true
            )
        default:
            return MainMenuDetailsState(
                windowUUID: state.windowUUID,
                submenuType: state.submenuType,
                menuElements: state.menuElements,
                currentTabInfo: state.currentTabInfo
            )
        }
    }
}
