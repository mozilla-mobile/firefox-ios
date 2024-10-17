// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MenuKit
import Redux

final class MainMenuAction: Action {
    var tabID: TabUUID?
    var navigationDestination: MenuNavigationDestination?
    var currentTabInfo: MainMenuTabInfo?
    var detailsViewToShow: MainMenuDetailsViewType?

    init(
        windowUUID: WindowUUID,
        actionType: any ActionType,
        navigationDestination: MenuNavigationDestination? = nil,
        changeMenuViewTo: MainMenuDetailsViewType? = nil,
        currentTabInfo: MainMenuTabInfo? = nil,
        tabID: TabUUID? = nil
    ) {
        self.navigationDestination = navigationDestination
        self.detailsViewToShow = changeMenuViewTo
        self.currentTabInfo = currentTabInfo
        self.tabID = tabID
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum MainMenuActionType: ActionType {
    case closeMenuAndNavigateToDestination
    case closeMenu
    case showDetailsView
    case toggleUserAgent
    case updateCurrentTabInfo
    case viewDidLoad
}

enum MainMenuMiddlewareActionType: ActionType {
    case requestTabInfo
}

enum MainMenuDetailsActionType: ActionType {
    case addToBookmarks
    case addToReadingList
    case addToShortcuts
    case backToMainMenu
    case dismissView
    case editBookmark
    case removeFromShortcuts
    case removeFromReadingList
}
