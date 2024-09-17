// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MenuKit
import Shared
import Redux

struct MainMenuTabInfo: Equatable {
    let url: URL?
    let isHomepage: Bool
    let isDefaultUserAgentDesktop: Bool
    let hasChangedUserAgent: Bool
}

struct MainMenuState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var menuElements: [MenuSection]
    var shouldDismiss: Bool

    var navigationDestination: MainMenuNavigationDestination?
    var shouldShowDetailsFor: MainMenuDetailsViewType?
    var currentTabInfo: MainMenuTabInfo?

    private let menuConfigurator = MainMenuConfigurationUtility()

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
            currentTabInfo: mainMenuState.currentTabInfo,
            navigationDestination: mainMenuState.navigationDestination,
            shouldShowDetailsFor: mainMenuState.shouldShowDetailsFor,
            shouldDismiss: mainMenuState.shouldDismiss
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            menuElements: [],
            currentTabInfo: nil,
            navigationDestination: nil,
            shouldShowDetailsFor: nil,
            shouldDismiss: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        menuElements: [MenuSection],
        currentTabInfo: MainMenuTabInfo?,
        navigationDestination: MainMenuNavigationDestination? = nil,
        shouldShowDetailsFor submenuType: MainMenuDetailsViewType? = nil,
        shouldDismiss: Bool = false
    ) {
        self.windowUUID = windowUUID
        self.menuElements = menuElements
        self.currentTabInfo = currentTabInfo
        self.navigationDestination = navigationDestination
        self.shouldShowDetailsFor = submenuType
        self.shouldDismiss = shouldDismiss
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case MainMenuActionType.viewDidLoad:
            return MainMenuState(
                windowUUID: state.windowUUID,
                menuElements: state.menuElements,
                currentTabInfo: state.currentTabInfo
            )
        case MainMenuActionType.updateCurrentTabInfo(let info):
            return MainMenuState(
                windowUUID: state.windowUUID,
                menuElements: state.menuConfigurator.generateMenuElements(
                    with: state.windowUUID,
                    andInfo: info
                ),
                currentTabInfo: info
            )
        case MainMenuActionType.openDetailsView(to: let submenuType):
            return MainMenuState(
                windowUUID: state.windowUUID,
                menuElements: state.menuElements,
                currentTabInfo: state.currentTabInfo,
                shouldShowDetailsFor: submenuType
            )
        case MainMenuActionType.show:
            guard let menuAction = action as? MainMenuAction else { return state }
            return MainMenuState(
                windowUUID: state.windowUUID,
                menuElements: state.menuElements,
                currentTabInfo: state.currentTabInfo,
                navigationDestination: menuAction.navigationDestination
            )
        case MainMenuActionType.toggleUserAgent,
            MainMenuActionType.closeMenu:
            return MainMenuState(
                windowUUID: state.windowUUID,
                menuElements: state.menuElements,
                currentTabInfo: state.currentTabInfo,
                shouldDismiss: true
            )
        default:
            return MainMenuState(
                windowUUID: state.windowUUID,
                menuElements: state.menuElements,
                currentTabInfo: state.currentTabInfo
            )
        }
    }
}
