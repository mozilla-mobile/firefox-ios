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
    var shouldGoBackToMainMenu: Bool
    var navigationDestination: MenuNavigationDestination?
    var submenuType: MainMenuDetailsViewType?
    var isHomepage: Bool?

    var title: String {
        typealias Titles = String.MainMenu.ToolsSection
        return submenuType == .tools ? Titles.Tools : Titles.Save
    }

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
            submenuType: currentState.submenuType,
            isHomepage: currentState.isHomepage,
            navigationDestination: currentState.navigationDestination,
            shouldDismiss: currentState.shouldDismiss,
            shouldGoBackToMenu: currentState.shouldGoBackToMainMenu
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            menuElements: [],
            submenuType: nil,
            isHomepage: nil,
            navigationDestination: nil,
            shouldDismiss: false,
            shouldGoBackToMenu: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        menuElements: [MenuSection],
        submenuType: MainMenuDetailsViewType?,
        isHomepage: Bool?,
        navigationDestination: MenuNavigationDestination? = nil,
        shouldDismiss: Bool = false,
        shouldGoBackToMenu: Bool = false
    ) {
        self.windowUUID = windowUUID
        self.menuElements = menuElements
        self.submenuType = submenuType
        self.isHomepage = isHomepage
        self.navigationDestination = navigationDestination
        self.shouldDismiss = shouldDismiss
        self.shouldGoBackToMainMenu = shouldGoBackToMenu
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case ScreenActionType.showScreen:
            return handleShowScreenAction(action: action, state: state)
        case MainMenuDetailsActionType.tapBackToMainMenu:
            return handleTapBackToMainMenuAction(state: state)
        case MainMenuDetailsActionType.tapDismissView,
            MainMenuDetailsActionType.tapAddToBookmarks,
            MainMenuDetailsActionType.tapAddToShortcuts,
            MainMenuDetailsActionType.tapRemoveFromShortcuts,
            MainMenuDetailsActionType.tapAddToReadingList,
            MainMenuDetailsActionType.tapRemoveFromReadingList,
            MainMenuDetailsActionType.tapToggleNightMode,
            GeneralBrowserActionType.showReaderMode:
            return handleDismissableAction(state: state)
        case MainMenuDetailsActionType.tapEditBookmark:
            return handleTapEditBookmarkAction(state: state)
        case MainMenuDetailsActionType.tapZoom:
            return handleTapZoomAction(state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleShowScreenAction(action: Action, state: Self) -> MainMenuDetailsState {
        guard let screenAction = action as? ScreenAction,
              screenAction.screen == .mainMenuDetails,
              let menuState = store.state.screenState(
                MainMenuState.self,
                for: .mainMenu,
                window: action.windowUUID),
              let currentTabInfo = menuState.currentTabInfo,
              let currentSubmenu = menuState.currentSubmenuView
              // let toolbarState = store.state.screenState(
              //   ToolbarState.self,
              //   for: .toolbar,
              //   window: action.windowUUID),
              // let readerModeState = toolbarState.addressToolbar.readerModeState
        else { return defaultState(from: state) }

        return MainMenuDetailsState(
            windowUUID: state.windowUUID,
            menuElements: state.menuConfigurator.generateMenuElements(
                with: currentTabInfo,
                for: currentSubmenu,
                and: action.windowUUID,
                readerState: nil
            ),
            submenuType: currentSubmenu,
            isHomepage: state.isHomepage
        )
    }

    private static func handleTapBackToMainMenuAction(state: Self) -> MainMenuDetailsState {
        return MainMenuDetailsState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            submenuType: state.submenuType,
            isHomepage: state.isHomepage,
            shouldGoBackToMenu: true
        )
    }

    private static func handleDismissableAction(state: Self) -> MainMenuDetailsState {
        return MainMenuDetailsState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            submenuType: state.submenuType,
            isHomepage: state.isHomepage,
            shouldDismiss: true
        )
    }

    private static func handleTapEditBookmarkAction(state: Self) -> MainMenuDetailsState {
        return MainMenuDetailsState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            submenuType: state.submenuType,
            isHomepage: state.isHomepage,
            navigationDestination: MenuNavigationDestination(.editBookmark)
        )
    }

    private static func handleTapZoomAction(state: Self) -> MainMenuDetailsState {
        return MainMenuDetailsState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            submenuType: state.submenuType,
            isHomepage: state.isHomepage,
            navigationDestination: MenuNavigationDestination(.zoom)
        )
    }

    static func defaultState(from state: MainMenuDetailsState) -> MainMenuDetailsState {
        return MainMenuDetailsState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            submenuType: state.submenuType,
            isHomepage: state.isHomepage
        )
    }
}
