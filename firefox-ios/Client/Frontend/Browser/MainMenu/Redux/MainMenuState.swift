// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MenuKit
import Shared
import Redux

struct MainMenuTabInfo: Equatable {
    let tabID: TabUUID
    let url: URL?
    let isHomepage: Bool
    let isDefaultUserAgentDesktop: Bool
    let hasChangedUserAgent: Bool
    let readerModeIsAvailable: Bool
    let isBookmarked: Bool
    let isInReadingList: Bool
    let isPinned: Bool
}

struct MainMenuState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var menuElements: [MenuSection]

    var shouldDismiss: Bool

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
            shouldDismiss: mainMenuState.shouldDismiss
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            menuElements: [],
            currentTabInfo: nil,
            submenuDestination: nil,
            navigationDestination: nil,
            shouldDismiss: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        menuElements: [MenuSection],
        currentTabInfo: MainMenuTabInfo?,
        submenuDestination: MainMenuDetailsViewType? = nil,
        navigationDestination: MenuNavigationDestination? = nil,
        shouldDismiss: Bool = false
    ) {
        self.windowUUID = windowUUID
        self.menuElements = menuElements
        self.currentSubmenuView = submenuDestination
        self.currentTabInfo = currentTabInfo
        self.navigationDestination = navigationDestination
        self.shouldDismiss = shouldDismiss
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else {
            return MainMenuState(
                windowUUID: state.windowUUID,
                menuElements: state.menuElements,
                currentTabInfo: state.currentTabInfo
            )
        }

        switch action.actionType {
        case MainMenuActionType.updateCurrentTabInfo:
            guard let action = action as? MainMenuAction,
                  let currentTabInfo = action.currentTabInfo
            else { return state }

            return MainMenuState(
                windowUUID: state.windowUUID,
                menuElements: state.menuConfigurator.generateMenuElements(
                    with: currentTabInfo,
                    for: state.currentSubmenuView,
                    and: state.windowUUID
                ),
                currentTabInfo: currentTabInfo
            )
        case MainMenuActionType.showDetailsView:
            guard let action = action as? MainMenuAction else { return state }
            return MainMenuState(
                windowUUID: state.windowUUID,
                menuElements: state.menuElements,
                currentTabInfo: state.currentTabInfo,
                submenuDestination: action.detailsViewToShow
            )
        case MainMenuActionType.closeMenuAndNavigateToDestination:
            guard let action = action as? MainMenuAction else { return state }
            return MainMenuState(
                windowUUID: state.windowUUID,
                menuElements: state.menuElements,
                currentTabInfo: state.currentTabInfo,
                navigationDestination: action.navigationDestination
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

    // Farcaseanu
    // we should probably add this somewhere in either the screen showing actionType
    // from the VC, or the updateCurrentTabInfo action.
        // private func syncMenuButton() -> PhotonRowActions? {
    //
    //     let rustAccount = RustFirefoxAccounts.shared
    //     let needsReAuth = rustAccount.accountNeedsReauth()
    //
    //     guard let userProfile = rustAccount.userProfile else {
    //         return SingleActionViewModel(title: .LegacyAppMenu.SyncAndSaveData,
    //                                      iconString: StandardImageIdentifiers.Large.sync,
    //                                      tapHandler: action).items
    //     }
    //
    //     let title: String = {
    //         if rustAccount.accountNeedsReauth() {
    //             return .FxAAccountVerifyPassword
    //         }
    //         return userProfile.displayName ?? userProfile.email
    //     }()
    //
    //     let warningImage = StandardImageIdentifiers.Large.warningFill
    //     let avatarImage = StandardImageIdentifiers.Large.avatarCircle
    //     let iconString = needsReAuth ? warningImage : avatarImage
    //
    //     var iconURL: URL?
    //     if let str = rustAccount.userProfile?.avatarUrl,
    //         let url = URL(string: str, invalidCharacters: false) {
    //         iconURL = url
    //     }
    //     let iconType: PhotonActionSheetIconType = needsReAuth ? .Image : .URL
    //     let syncOption = SingleActionViewModel(title: title,
    //                                            iconString: iconString,
    //                                            iconURL: iconURL,
    //                                            iconType: iconType,
    //                                            needsIconActionableTint: needsReAuth,
    //                                            tapHandler: action).items
    //     return syncOption
    // }
}
