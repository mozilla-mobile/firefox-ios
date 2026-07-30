// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MenuKit
import Redux
import SummarizeKit
import ModifiedCopy

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

struct ReaderModeConfiguration: Equatable {
    /// Whether Reader mode is supported by the web page.
    let isAvailable: Bool
    /// Whether Reader mode is activated on the web page.
    let isActive: Bool
}

struct MainMenuTabInfo: Equatable {
    let tabID: TabUUID
    let url: URL?
    let canonicalURL: URL?
    let isHomepage: Bool
    let isDefaultUserAgentDesktop: Bool
    let hasChangedUserAgent: Bool
    let zoomLevel: CGFloat
    let readerModeConfiguration: ReaderModeConfiguration
    let summaryIsAvailable: Bool
    let summarizerConfig: SummarizerConfig?
    let isBookmarked: Bool
    let isInReadingList: Bool
    let isPinned: Bool
    let accountData: AccountData
    let translationConfiguration: TranslationConfiguration?
}

@Copyable
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

    private var menuConfigurator: MainMenuConfigurationUtility {
        MainMenuConfigurationUtility()
    }

    init(appState: AppState, uuid: WindowUUID) {
        guard let mainMenuState = appState.componentState(
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
            shouldDismiss: mainMenuState.shouldDismiss,
            accountData: mainMenuState.accountData,
            accountProfileImage: mainMenuState.accountProfileImage,
            isBrowserDefault: mainMenuState.isBrowserDefault,
            isPhoneLandscape: mainMenuState.isPhoneLandscape,
            moreCellTapped: mainMenuState.moreCellTapped,
            siteProtectionsData: mainMenuState.siteProtectionsData,
            navigationDestination: mainMenuState.navigationDestination,
            currentTabInfo: mainMenuState.currentTabInfo
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            menuElements: [],
            shouldDismiss: false,
            accountData: nil,
            accountProfileImage: nil,
            isBrowserDefault: false,
            isPhoneLandscape: false,
            moreCellTapped: false,
            siteProtectionsData: nil,
            navigationDestination: nil,
            currentTabInfo: nil
        )
    }

    private init(
        windowUUID: WindowUUID,
        menuElements: [MenuSection],
        shouldDismiss: Bool = false,
        accountData: AccountData?,
        accountProfileImage: UIImage?,
        isBrowserDefault: Bool,
        isPhoneLandscape: Bool,
        moreCellTapped: Bool,
        siteProtectionsData: SiteProtectionsData?,
        navigationDestination: MenuNavigationDestination? = nil,
        currentTabInfo: MainMenuTabInfo?
    ) {
        self.windowUUID = windowUUID
        self.menuElements = menuElements
        self.shouldDismiss = shouldDismiss
        self.accountData = accountData
        self.accountProfileImage = accountProfileImage
        self.isBrowserDefault = isBrowserDefault
        self.isPhoneLandscape = isPhoneLandscape
        self.moreCellTapped = moreCellTapped
        self.siteProtectionsData = siteProtectionsData
        self.navigationDestination = navigationDestination
        self.currentTabInfo = currentTabInfo
    }

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, actionWindowUUID in
        // Does not handle any modern actions
        return defaultState(from: state)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
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
        return state.copy(windowUUID: state.windowUUID)
            .copy(menuElements: state.menuElements)
            .copy(currentTabInfo: state.currentTabInfo)
            .copy(accountData: state.accountData)
            .copy(accountProfileImage: state.accountProfileImage)
            .copy(siteProtectionsData: state.siteProtectionsData)
            .copy(isBrowserDefault: state.isBrowserDefault)
            .copy(isPhoneLandscape: state.isPhoneLandscape)
            .copy(moreCellTapped: state.moreCellTapped)
    }

    private static func handleViewDidLoadAction(state: MainMenuState) -> MainMenuState {
        return state.copy(windowUUID: state.windowUUID)
            .copy(menuElements: state.menuElements)
            .copy(currentTabInfo: state.currentTabInfo)
            .copy(accountData: state.accountData)
            .copy(accountProfileImage: state.accountProfileImage)
            .copy(siteProtectionsData: state.siteProtectionsData)
            .copy(isBrowserDefault: state.isBrowserDefault)
            .copy(isPhoneLandscape: state.isPhoneLandscape)
            .copy(moreCellTapped: state.moreCellTapped)
    }

    private static func handleUpdateAccountHeaderAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction else { return defaultState(from: state) }

        return state.copy(windowUUID: state.windowUUID)
            .copy(menuElements: state.menuElements)
            .copy(currentTabInfo: state.currentTabInfo)
            .copy(accountData: action.accountData)
            .copy(accountProfileImage: state.accountProfileImage)
            .copy(siteProtectionsData: state.siteProtectionsData)
            .copy(isBrowserDefault: state.isBrowserDefault)
            .copy(isPhoneLandscape: state.isPhoneLandscape)
            .copy(moreCellTapped: state.moreCellTapped)
    }

    private static func handleUpdateBannerVisibilityAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction else { return defaultState(from: state) }

        return state.copy(windowUUID: state.windowUUID)
            .copy(menuElements: state.menuElements)
            .copy(currentTabInfo: state.currentTabInfo)
            .copy(accountData: state.accountData)
            .copy(accountProfileImage: state.accountProfileImage)
            .copy(siteProtectionsData: state.siteProtectionsData)
            .copy(isBrowserDefault: action.isBrowserDefault)
            .copy(isPhoneLandscape: state.isPhoneLandscape)
            .copy(moreCellTapped: state.moreCellTapped)
    }

    private static func handleUpdateMenuAppearanceAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction else { return defaultState(from: state) }

        return state.copy(windowUUID: state.windowUUID)
            .copy(menuElements: state.menuElements)
            .copy(currentTabInfo: state.currentTabInfo)
            .copy(accountData: state.accountData)
            .copy(accountProfileImage: state.accountProfileImage)
            .copy(siteProtectionsData: state.siteProtectionsData)
            .copy(isBrowserDefault: state.isBrowserDefault)
            .copy(isPhoneLandscape: action.isPhoneLandscape)
            .copy(moreCellTapped: state.moreCellTapped)
    }

    private static func handleUpdateSiteProtectionsHeaderAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction else { return defaultState(from: state) }

        return state.copy(windowUUID: state.windowUUID)
            .copy(menuElements: state.menuElements)
            .copy(currentTabInfo: state.currentTabInfo)
            .copy(accountData: state.accountData)
            .copy(accountProfileImage: state.accountProfileImage)
            .copy(siteProtectionsData: action.siteProtectionsData)
            .copy(isBrowserDefault: state.isBrowserDefault)
            .copy(isPhoneLandscape: state.isPhoneLandscape)
            .copy(moreCellTapped: state.moreCellTapped)
    }

    @MainActor
    private static func handleUpdateCurrentTabInfoAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction,
              let currentTabInfo = action.currentTabInfo
        else { return defaultState(from: state) }

        return state.copy(windowUUID: state.windowUUID)
            .copy(menuElements: state.menuConfigurator.generateMenuElements(
                with: currentTabInfo,
                and: state.windowUUID,
                isExpanded: state.moreCellTapped
            ))
            .copy(currentTabInfo: currentTabInfo)
            .copy(accountData: state.accountData)
            .copy(accountProfileImage: state.accountProfileImage)
            .copy(siteProtectionsData: state.siteProtectionsData)
            .copy(isBrowserDefault: state.isBrowserDefault)
            .copy(isPhoneLandscape: state.isPhoneLandscape)
            .copy(moreCellTapped: state.moreCellTapped)
    }

    @MainActor
    private static func handleUpdateProfileImageAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction,
              let accountProfileImage = action.accountProfileImage,
              let currentTabInfo = state.currentTabInfo
        else { return defaultState(from: state) }

        return state.copy(windowUUID: state.windowUUID)
            .copy(menuElements: state.menuConfigurator.generateMenuElements(
                with: currentTabInfo,
                and: state.windowUUID,
                isExpanded: state.moreCellTapped,
                profileImage: accountProfileImage
            ))
            .copy(currentTabInfo: state.currentTabInfo)
            .copy(accountData: state.accountData)
            .copy(accountProfileImage: accountProfileImage)
            .copy(siteProtectionsData: state.siteProtectionsData)
            .copy(isBrowserDefault: state.isBrowserDefault)
            .copy(isPhoneLandscape: state.isPhoneLandscape)
            .copy(moreCellTapped: state.moreCellTapped)
    }

    @MainActor
    private static func handleShowMoreOptions(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction,
              let currentTabInfo = state.currentTabInfo,
              let isExpanded = action.isExpanded
        else { return defaultState(from: state) }

        return state.copy(windowUUID: state.windowUUID)
            .copy(menuElements: state.menuConfigurator.generateMenuElements(
                with: currentTabInfo,
                and: state.windowUUID,
                isExpanded: !isExpanded,
                profileImage: state.accountProfileImage
            ))
            .copy(currentTabInfo: state.currentTabInfo)
            .copy(accountData: state.accountData)
            .copy(accountProfileImage: state.accountProfileImage)
            .copy(siteProtectionsData: state.siteProtectionsData)
            .copy(isBrowserDefault: state.isBrowserDefault)
            .copy(isPhoneLandscape: state.isPhoneLandscape)
            .copy(moreCellTapped: true)
    }

    private static func handleTapNavigateToDestinationAction(state: MainMenuState, action: Action) -> MainMenuState {
        guard let action = action as? MainMenuAction else { return defaultState(from: state) }

        return state.copy(windowUUID: state.windowUUID)
            .copy(menuElements: state.menuElements)
            .copy(currentTabInfo: state.currentTabInfo)
            .copy(navigationDestination: action.navigationDestination)
            .copy(accountData: state.accountData)
            .copy(accountProfileImage: state.accountProfileImage)
            .copy(siteProtectionsData: state.siteProtectionsData)
            .copy(isBrowserDefault: state.isBrowserDefault)
            .copy(isPhoneLandscape: state.isPhoneLandscape)
            .copy(moreCellTapped: state.moreCellTapped)
    }

    private static func handleTapToggleUserAgentAndTapCloseMenuAction(state: MainMenuState) -> MainMenuState {
        return state.copy(windowUUID: state.windowUUID)
            .copy(menuElements: state.menuElements)
            .copy(currentTabInfo: state.currentTabInfo)
            .copy(shouldDismiss: true)
            .copy(accountData: state.accountData)
            .copy(accountProfileImage: state.accountProfileImage)
            .copy(siteProtectionsData: state.siteProtectionsData)
            .copy(isBrowserDefault: state.isBrowserDefault)
            .copy(isPhoneLandscape: state.isPhoneLandscape)
            .copy(moreCellTapped: state.moreCellTapped)
    }

    private static func handleDismissMenuAction(state: MainMenuState) -> MainMenuState {
        return state.copy(windowUUID: state.windowUUID)
            .copy(menuElements: state.menuElements)
            .copy(currentTabInfo: state.currentTabInfo)
            .copy(shouldDismiss: true)
            .copy(accountData: state.accountData)
            .copy(accountProfileImage: state.accountProfileImage)
            .copy(siteProtectionsData: state.siteProtectionsData)
            .copy(isBrowserDefault: state.isBrowserDefault)
            .copy(isPhoneLandscape: state.isPhoneLandscape)
            .copy(moreCellTapped: state.moreCellTapped)
    }

    private static func handleTapEditBookmarkAction(state: MainMenuState, action: Action) -> MainMenuState {
        return state.copy(windowUUID: state.windowUUID)
            .copy(menuElements: state.menuElements)
            .copy(currentTabInfo: state.currentTabInfo)
            .copy(navigationDestination: MenuNavigationDestination(.editBookmark))
            .copy(accountData: state.accountData)
            .copy(accountProfileImage: state.accountProfileImage)
            .copy(siteProtectionsData: state.siteProtectionsData)
            .copy(isBrowserDefault: state.isBrowserDefault)
            .copy(isPhoneLandscape: state.isPhoneLandscape)
            .copy(moreCellTapped: state.moreCellTapped)
    }

    private static func handleTapZoomAction(state: MainMenuState) -> MainMenuState {
        return state.copy(windowUUID: state.windowUUID)
            .copy(menuElements: state.menuElements)
            .copy(currentTabInfo: state.currentTabInfo)
            .copy(navigationDestination: MenuNavigationDestination(.zoom))
            .copy(accountData: state.accountData)
            .copy(accountProfileImage: state.accountProfileImage)
            .copy(siteProtectionsData: state.siteProtectionsData)
            .copy(isBrowserDefault: state.isBrowserDefault)
            .copy(isPhoneLandscape: state.isPhoneLandscape)
            .copy(moreCellTapped: state.moreCellTapped)
    }
}
