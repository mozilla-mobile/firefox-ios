// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MenuKit
import Redux
import SummarizeKit

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
    let isDefaultUserAgentDesktop: Bool?
    let hasChangedUserAgent: Bool?

    init(isHomepage: Bool,
         isActionOn: Bool? = nil,
         isDefaultUserAgentDesktop: Bool? = nil,
         hasChangedUserAgent: Bool? = nil) {
        self.isHomepage = isHomepage
        self.isActionOn = isActionOn
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
    let summaryIsAvailable: Bool
    let summarizerConfig: SummarizerConfig?
    let isBookmarked: Bool
    let isInReadingList: Bool
    let isPinned: Bool
    let accountData: AccountData
}

struct MainMenuState: ScreenState, Sendable {
    let windowUUID: WindowUUID
    let menuElements: [MenuSection]

    let shouldDismiss: Bool

    let accountData: AccountData?
    let accountProfileImage: UIImage?
    let isBrowserDefault: Bool
    let isPhoneLandscape: Bool
    let moreCellTapped: Bool

    let siteProtectionsData: SiteProtectionsData?

    var navigationDestination: MenuNavigationDestination?
    var currentTabInfo: MainMenuTabInfo?

    private let menuConfigurator = MainMenuConfigurationUtility()

    init(appState: AppState, uuid: WindowUUID) {
        guard let mainMenuState = appState.screenState(
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
            shouldDismiss: mainMenuState.shouldDismiss,
            accountData: mainMenuState.accountData,
            accountProfileImage: mainMenuState.accountProfileImage,
            siteProtectionsData: mainMenuState.siteProtectionsData,
            isBrowserDefault: mainMenuState.isBrowserDefault,
            isPhoneLandscape: mainMenuState.isPhoneLandscape,
            moreCellTapped: mainMenuState.moreCellTapped
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            menuElements: [],
            currentTabInfo: nil,
            navigationDestination: nil,
            shouldDismiss: false,
            accountData: nil,
            accountProfileImage: nil,
            siteProtectionsData: nil,
            isBrowserDefault: false,
            isPhoneLandscape: false,
            moreCellTapped: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        menuElements: [MenuSection],
        currentTabInfo: MainMenuTabInfo?,
        navigationDestination: MenuNavigationDestination? = nil,
        shouldDismiss: Bool = false,
        accountData: AccountData?,
        accountProfileImage: UIImage?,
        siteProtectionsData: SiteProtectionsData?,
        isBrowserDefault: Bool,
        isPhoneLandscape: Bool,
        moreCellTapped: Bool
    ) {
        self.windowUUID = windowUUID
        self.menuElements = menuElements
        self.currentTabInfo = currentTabInfo
        self.navigationDestination = navigationDestination
        self.shouldDismiss = shouldDismiss
        self.accountData = accountData
        self.accountProfileImage = accountProfileImage
        self.siteProtectionsData = siteProtectionsData
        self.isBrowserDefault = isBrowserDefault
        self.isPhoneLandscape = isPhoneLandscape
        self.moreCellTapped = moreCellTapped
    }

    static let reducer: Reducer<Self> = { state, action in
        return handleReducer(state: state, action: action)
    }

    @MainActor
    private static func handleReducer(state: MainMenuState, action: Action) -> MainMenuState {
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case MainMenuActionType.viewDidLoad:
            return handleViewDidLoadAction(state: state)
        case MainMenuMiddlewareActionType.updateAccountHeader:
            return handleUpdateAccountHeaderAction(state: state, action: action)
        case MainMenuMiddlewareActionType.updateBannerVisibility:
            return handleUpdateBannerVisibilityAction(state: state, action: action)
        case MainMenuMiddlewareActionType.updateMenuAppearance:
            return handleUpdateMenuAppearanceAction(state: state, action: action)
        case MainMenuActionType.updateSiteProtectionsHeader:
            return handleUpdateSiteProtectionsHeaderAction(state: state, action: action)
        case MainMenuActionType.updateCurrentTabInfo:
            return handleUpdateCurrentTabInfoAction(state: state, action: action)
        case MainMenuActionType.updateProfileImage:
            return handleUpdateProfileImageAction(state: state, action: action)
        case MainMenuActionType.tapMoreOptions:
            return handleShowMoreOptions(state: state, action: action)
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
            accountProfileImage: state.accountProfileImage,
            siteProtectionsData: state.siteProtectionsData,
            isBrowserDefault: state.isBrowserDefault,
            isPhoneLandscape: state.isPhoneLandscape,
            moreCellTapped: state.moreCellTapped
        )
    }

    private static func handleViewDidLoadAction(state: MainMenuState) -> MainMenuState {
        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            accountData: state.accountData,
            accountProfileImage: state.accountProfileImage,
            siteProtectionsData: state.siteProtectionsData,
            isBrowserDefault: state.isBrowserDefault,
            isPhoneLandscape: state.isPhoneLandscape,
            moreCellTapped: state.moreCellTapped
        )
    }

    private static func handleUpdateAccountHeaderAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction else { return defaultState(from: state) }

        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            accountData: action.accountData,
            accountProfileImage: state.accountProfileImage,
            siteProtectionsData: state.siteProtectionsData,
            isBrowserDefault: state.isBrowserDefault,
            isPhoneLandscape: state.isPhoneLandscape,
            moreCellTapped: state.moreCellTapped
        )
    }

    private static func handleUpdateBannerVisibilityAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction else { return defaultState(from: state) }

        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            accountData: state.accountData,
            accountProfileImage: state.accountProfileImage,
            siteProtectionsData: state.siteProtectionsData,
            isBrowserDefault: action.isBrowserDefault,
            isPhoneLandscape: state.isPhoneLandscape,
            moreCellTapped: state.moreCellTapped
        )
    }

    private static func handleUpdateMenuAppearanceAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction else { return defaultState(from: state) }

        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            accountData: state.accountData,
            accountProfileImage: state.accountProfileImage,
            siteProtectionsData: state.siteProtectionsData,
            isBrowserDefault: state.isBrowserDefault,
            isPhoneLandscape: action.isPhoneLandscape,
            moreCellTapped: state.moreCellTapped
        )
    }

    private static func handleUpdateSiteProtectionsHeaderAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction else { return defaultState(from: state) }

        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            accountData: state.accountData,
            accountProfileImage: state.accountProfileImage,
            siteProtectionsData: action.siteProtectionsData,
            isBrowserDefault: state.isBrowserDefault,
            isPhoneLandscape: state.isPhoneLandscape,
            moreCellTapped: state.moreCellTapped
        )
    }

    @MainActor
    private static func handleUpdateCurrentTabInfoAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction,
              let currentTabInfo = action.currentTabInfo
        else { return defaultState(from: state) }

        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuConfigurator.generateMenuElements(
                with: currentTabInfo,
                and: state.windowUUID,
                isExpanded: state.moreCellTapped
            ),
            currentTabInfo: currentTabInfo,
            accountData: state.accountData,
            accountProfileImage: state.accountProfileImage,
            siteProtectionsData: state.siteProtectionsData,
            isBrowserDefault: state.isBrowserDefault,
            isPhoneLandscape: state.isPhoneLandscape,
            moreCellTapped: state.moreCellTapped
        )
    }

    @MainActor
    private static func handleUpdateProfileImageAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction,
              let accountProfileImage = action.accountProfileImage,
              let currentTabInfo = state.currentTabInfo
        else { return defaultState(from: state) }

        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuConfigurator.generateMenuElements(
                with: currentTabInfo,
                and: state.windowUUID,
                isExpanded: state.moreCellTapped,
                profileImage: accountProfileImage
            ),
            currentTabInfo: state.currentTabInfo,
            accountData: state.accountData,
            accountProfileImage: accountProfileImage,
            siteProtectionsData: state.siteProtectionsData,
            isBrowserDefault: state.isBrowserDefault,
            isPhoneLandscape: state.isPhoneLandscape,
            moreCellTapped: state.moreCellTapped
        )
    }

    @MainActor
    private static func handleShowMoreOptions(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction,
              let currentTabInfo = state.currentTabInfo,
              let isExpanded = action.isExpanded
        else { return defaultState(from: state) }

        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuConfigurator.generateMenuElements(
                with: currentTabInfo,
                and: state.windowUUID,
                isExpanded: !isExpanded,
                profileImage: state.accountProfileImage
            ),
            currentTabInfo: state.currentTabInfo,
            accountData: state.accountData,
            accountProfileImage: state.accountProfileImage,
            siteProtectionsData: state.siteProtectionsData,
            isBrowserDefault: state.isBrowserDefault,
            isPhoneLandscape: state.isPhoneLandscape,
            moreCellTapped: true
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
            accountProfileImage: state.accountProfileImage,
            siteProtectionsData: state.siteProtectionsData,
            isBrowserDefault: state.isBrowserDefault,
            isPhoneLandscape: state.isPhoneLandscape,
            moreCellTapped: state.moreCellTapped
        )
    }

    private static func handleTapToggleUserAgentAndTapCloseMenuAction(state: MainMenuState) -> MainMenuState {
        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            shouldDismiss: true,
            accountData: state.accountData,
            accountProfileImage: state.accountProfileImage,
            siteProtectionsData: state.siteProtectionsData,
            isBrowserDefault: state.isBrowserDefault,
            isPhoneLandscape: state.isPhoneLandscape,
            moreCellTapped: state.moreCellTapped
        )
    }

    private static func handleDismissMenuAction(state: MainMenuState) -> MainMenuState {
        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            shouldDismiss: true,
            accountData: state.accountData,
            accountProfileImage: state.accountProfileImage,
            siteProtectionsData: state.siteProtectionsData,
            isBrowserDefault: state.isBrowserDefault,
            isPhoneLandscape: state.isPhoneLandscape,
            moreCellTapped: state.moreCellTapped
        )
    }

    private static func handleTapEditBookmarkAction(state: MainMenuState, action: Action) -> MainMenuState {
        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            navigationDestination: MenuNavigationDestination(.editBookmark),
            accountData: state.accountData,
            accountProfileImage: state.accountProfileImage,
            siteProtectionsData: state.siteProtectionsData,
            isBrowserDefault: state.isBrowserDefault,
            isPhoneLandscape: state.isPhoneLandscape,
            moreCellTapped: state.moreCellTapped
        )
    }

    private static func handleTapZoomAction(state: MainMenuState) -> MainMenuState {
        return MainMenuState(
            windowUUID: state.windowUUID,
            menuElements: state.menuElements,
            currentTabInfo: state.currentTabInfo,
            navigationDestination: MenuNavigationDestination(.zoom),
            accountData: state.accountData,
            accountProfileImage: state.accountProfileImage,
            siteProtectionsData: state.siteProtectionsData,
            isBrowserDefault: state.isBrowserDefault,
            isPhoneLandscape: state.isPhoneLandscape,
            moreCellTapped: state.moreCellTapped
        )
    }
}
