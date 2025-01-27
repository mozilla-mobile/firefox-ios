// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MenuKit
import Shared
import Redux

struct AccountData: Equatable {
    let title: String
    let subtitle: String?
    let warningIcon: String?
    let iconURL: URL?
}

struct TelemetryInfo: Equatable {
    let isHomepage: Bool
    let isActionOn: Bool?
    let submenuType: MainMenuDetailsViewType?
    let isDefaultUserAgentDesktop: Bool?
    let hasChangedUserAgent: Bool?

    init(isHomepage: Bool,
         isActionOn: Bool? = nil,
         submenuType: MainMenuDetailsViewType? = nil,
         isDefaultUserAgentDesktop: Bool? = nil,
         hasChangedUserAgent: Bool? = nil) {
        self.isHomepage = isHomepage
        self.isActionOn = isActionOn
        self.submenuType = submenuType
        self.isDefaultUserAgentDesktop = isDefaultUserAgentDesktop
        self.hasChangedUserAgent = hasChangedUserAgent
    }
}

struct MainMenuTabInfo: Equatable {
    let tabID: TabUUID
    let url: URL?
    let canonicalURL: URL?
    let isHomepage: Bool
    let isDefaultUserAgentDesktop: Bool
    let hasChangedUserAgent: Bool
    let zoomLevel: CGFloat
    let readerModeIsAvailable: Bool
    let isBookmarked: Bool
    let isInReadingList: Bool
    let isPinned: Bool
}

struct MainMenuState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var menuElements: [MenuSection]

    var shouldDismiss: Bool

    var accountData: AccountData?
    var accountIcon: UIImage?

    var navigationDestination: MenuNavigationDestination?
    var currentTabInfo: MainMenuTabInfo?
    var currentSubmenuView: MainMenuDetailsViewType?

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
            submenuDestination: mainMenuState.currentSubmenuView,
            navigationDestination: mainMenuState.navigationDestination,
            shouldDismiss: mainMenuState.shouldDismiss,
            accountData: mainMenuState.accountData,
            accountIcon: mainMenuState.accountIcon
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            menuElements: [],
            currentTabInfo: nil,
            submenuDestination: nil,
            navigationDestination: nil,
            shouldDismiss: false,
            accountData: nil,
            accountIcon: nil
        )
    }

    private init(
        windowUUID: WindowUUID,
        menuElements: [MenuSection],
        currentTabInfo: MainMenuTabInfo?,
        submenuDestination: MainMenuDetailsViewType? = nil,
        navigationDestination: MenuNavigationDestination? = nil,
        shouldDismiss: Bool = false,
        accountData: AccountData?,
        accountIcon: UIImage?
    ) {
        self.windowUUID = windowUUID
        self.menuElements = menuElements
        self.currentSubmenuView = submenuDestination
        self.currentTabInfo = currentTabInfo
        self.navigationDestination = navigationDestination
        self.shouldDismiss = shouldDismiss
        self.accountData = accountData
        self.accountIcon = accountIcon
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case MainMenuActionType.viewDidLoad:
            return handleViewDidLoadAction(state: state)
        case MainMenuMiddlewareActionType.updateAccountHeader:
            return handleUpdateAccountHeaderAction(state: state, action: action)
        case MainMenuActionType.updateCurrentTabInfo:
            return handleUpdateCurrentTabInfoAction(state: state, action: action)
        case MainMenuActionType.tapShowDetailsView:
            return handleTapShowDetailsViewAction(state: state, action: action)
        case MainMenuActionType.tapNavigateToDestination:
            return handleTapNavigateToDestinationAction(state: state, action: action)
        case MainMenuActionType.tapToggleUserAgent,
            MainMenuActionType.tapCloseMenu:
            return handleTapToggleUserAgentAndTapCloseMenuAction(state: state)
        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: MainMenuState) -> MainMenuState {
        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            accountData: state.accountData,
            accountIcon: state.accountIcon
        )
    }

    private static func handleViewDidLoadAction(state: MainMenuState) -> MainMenuState {
        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            accountData: state.accountData,
            accountIcon: state.accountIcon
        )
    }

    private static func handleUpdateAccountHeaderAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction else { return defaultState(from: state) }

        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            accountData: action.accountData,
            accountIcon: action.accountIcon
        )
    }

    private static func handleUpdateCurrentTabInfoAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction,
              let currentTabInfo = action.currentTabInfo
        else { return defaultState(from: state) }

        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuConfigurator.generateMenuElements(
                with: currentTabInfo,
                for: state.currentSubmenuView,
                and: state.windowUUID
            ),
            currentTabInfo: currentTabInfo,
            accountData: state.accountData,
            accountIcon: state.accountIcon
        )
    }

    private static func handleTapShowDetailsViewAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction else { return defaultState(from: state) }

        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            submenuDestination: action.detailsViewToShow,
            accountData: state.accountData,
            accountIcon: state.accountIcon
        )
    }

    private static func handleTapNavigateToDestinationAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction else { return defaultState(from: state) }

        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            navigationDestination: action.navigationDestination,
            accountData: state.accountData,
            accountIcon: state.accountIcon
        )
    }

    private static func handleTapToggleUserAgentAndTapCloseMenuAction(state: MainMenuState) -> MainMenuState {
        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            shouldDismiss: true,
            accountData: state.accountData,
            accountIcon: state.accountIcon
        )
    }
}
