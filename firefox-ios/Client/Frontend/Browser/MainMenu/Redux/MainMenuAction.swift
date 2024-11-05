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
    var accountData: AccountData?
    var accountIcon: UIImage?

    init(
        windowUUID: WindowUUID,
        actionType: any ActionType,
        navigationDestination: MenuNavigationDestination? = nil,
        changeMenuViewTo: MainMenuDetailsViewType? = nil,
        currentTabInfo: MainMenuTabInfo? = nil,
        tabID: TabUUID? = nil,
        accountData: AccountData? = nil,
        accountIcon: UIImage? = nil
    ) {
        self.navigationDestination = navigationDestination
        self.detailsViewToShow = changeMenuViewTo
        self.currentTabInfo = currentTabInfo
        self.tabID = tabID
        self.accountData = accountData
        self.accountIcon = accountIcon
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum MainMenuActionType: ActionType {
    case tapNavigateToDestination
    case tapCloseMenu
    case tapShowDetailsView
    case tapToggleUserAgent
    case updateCurrentTabInfo
    case viewDidLoad
}

enum MainMenuMiddlewareActionType: ActionType {
    case requestTabInfo
    case updateAccountHeader
}

enum MainMenuDetailsActionType: ActionType {
    // Tools submenu actions
    case tapZoom
    case tapToggleNightMode
    case tapReportBrokenSite

    // Save submenu actions
    case tapAddToBookmarks
    case tapAddToReadingList
    case tapAddToShortcuts
    case tapBackToMainMenu
    case tapDismissView
    case tapEditBookmark
    case tapRemoveFromShortcuts
    case tapRemoveFromReadingList
}
