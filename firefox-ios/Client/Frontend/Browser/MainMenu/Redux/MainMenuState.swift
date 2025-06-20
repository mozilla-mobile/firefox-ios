// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MenuKit
import Redux

struct AccountData: Equatable {
    let title: String
    let subtitle: String?
    let warningIcon: String?
    let needsReAuth: Bool?
    let iconURL: URL?

    init(title: String, subtitle: String?, warningIcon: String? = nil, needsReAuth: Bool? = nil, iconURL: URL? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.warningIcon = warningIcon
        self.needsReAuth = needsReAuth
        self.iconURL = iconURL
    }
}

enum SiteProtectionsState {
    case on
    case off
    case notSecure
}

struct SiteProtectionsData: Equatable {
    let title: String?
    let subtitle: String?
    let image: String?
    let state: SiteProtectionsState
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
    let accountData: AccountData
    let accountProfileImage: UIImage?
}

struct MainMenuState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var menuElements: [MenuSection]

    var shouldDismiss: Bool

    var accountData: AccountData?
    var accountIcon: UIImage?

    var siteProtectionsData: SiteProtectionsData?

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
            accountIcon: mainMenuState.accountIcon,
            siteProtectionsData: mainMenuState.siteProtectionsData
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
            accountIcon: nil,
            siteProtectionsData: nil
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
        accountIcon: UIImage?,
        siteProtectionsData: SiteProtectionsData?
    ) {
        self.windowUUID = windowUUID
        self.menuElements = menuElements
        self.currentSubmenuView = submenuDestination
        self.currentTabInfo = currentTabInfo
        self.navigationDestination = navigationDestination
        self.shouldDismiss = shouldDismiss
        self.accountData = accountData
        self.accountIcon = accountIcon
        self.siteProtectionsData = siteProtectionsData
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
        case MainMenuActionType.updateSiteProtectionsHeader:
            return handleUpdateSiteProtectionsHeaderAction(state: state, action: action)
        case MainMenuActionType.updateCurrentTabInfo:
            return handleUpdateCurrentTabInfoAction(state: state, action: action)
        case MainMenuActionType.tapMoreOptions:
            return handleShowMoreOptions(state: state, action: action)
        case MainMenuActionType.tapShowDetailsView:
            return handleTapShowDetailsViewAction(state: state, action: action)
        case MainMenuActionType.tapNavigateToDestination:
            return handleTapNavigateToDestinationAction(state: state, action: action)
        case MainMenuActionType.tapToggleUserAgent,
            MainMenuActionType.tapCloseMenu:
            return handleTapToggleUserAgentAndTapCloseMenuAction(state: state)
        case MainMenuActionType.tapAddToBookmarks:
            return handleDismissMenuAction(state: state)
        case MainMenuActionType.tapEditBookmark:
            return handleTapEditBookmarkAction(state: state, action: action)
        case MainMenuActionType.tapZoom:
            return handleTapZoomAction(state: state)
        case MainMenuActionType.tapToggleNightMode:
            return handleDismissMenuAction(state: state)
        case MainMenuActionType.tapAddToShortcuts, MainMenuActionType.tapRemoveFromShortcuts:
            return handleDismissMenuAction(state: state)
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
            accountIcon: state.accountIcon,
            siteProtectionsData: state.siteProtectionsData
        )
    }

    private static func handleViewDidLoadAction(state: MainMenuState) -> MainMenuState {
        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            accountData: state.accountData,
            accountIcon: state.accountIcon,
            siteProtectionsData: state.siteProtectionsData
        )
    }

    private static func handleUpdateAccountHeaderAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction else { return defaultState(from: state) }

        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            accountData: action.accountData,
            accountIcon: action.accountIcon,
            siteProtectionsData: state.siteProtectionsData
        )
    }

    private static func handleUpdateSiteProtectionsHeaderAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction else { return defaultState(from: state) }

        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            accountData: state.accountData,
            accountIcon: state.accountIcon,
            siteProtectionsData: action.siteProtectionsData
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
            accountIcon: state.accountIcon,
            siteProtectionsData: state.siteProtectionsData
        )
    }

    private static func handleShowMoreOptions(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction,
              let currentTabInfo = state.currentTabInfo,
              let isExpanded = action.isExpanded
        else { return defaultState(from: state) }

        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuConfigurator.generateMenuElements(
                with: currentTabInfo,
                for: state.currentSubmenuView,
                and: state.windowUUID,
                isExpanded: !isExpanded
            ),
            currentTabInfo: state.currentTabInfo,
            accountData: state.accountData,
            accountIcon: state.accountIcon,
            siteProtectionsData: state.siteProtectionsData
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
            accountIcon: state.accountIcon,
            siteProtectionsData: state.siteProtectionsData
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
            accountIcon: state.accountIcon,
            siteProtectionsData: state.siteProtectionsData
        )
    }

    private static func handleTapToggleUserAgentAndTapCloseMenuAction(state: MainMenuState) -> MainMenuState {
        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            shouldDismiss: true,
            accountData: state.accountData,
            accountIcon: state.accountIcon,
            siteProtectionsData: state.siteProtectionsData
        )
    }

    private static func handleDismissMenuAction(state: MainMenuState) -> MainMenuState {
        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            shouldDismiss: true,
            accountData: state.accountData,
            accountIcon: state.accountIcon,
            siteProtectionsData: state.siteProtectionsData
        )
    }

    private static func handleTapEditBookmarkAction(state: MainMenuState, action: Action) -> MainMenuState {
        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            navigationDestination: MenuNavigationDestination(.editBookmark),
            accountData: state.accountData,
            accountIcon: state.accountIcon,
            siteProtectionsData: state.siteProtectionsData
        )
    }

    private static func handleTapZoomAction(state: MainMenuState) -> MainMenuState {
        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            navigationDestination: MenuNavigationDestination(.zoom),
            accountData: state.accountData,
            accountIcon: state.accountIcon,
            siteProtectionsData: state.siteProtectionsData
        )
    }
}
