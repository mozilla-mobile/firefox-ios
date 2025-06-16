// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

final class MainMenuAction: Action {
    var tabID: TabUUID?
    var navigationDestination: MenuNavigationDestination?
    var currentTabInfo: MainMenuTabInfo?
    var detailsViewToShow: MainMenuDetailsViewType?
    var accountData: AccountData?
    var accountIcon: UIImage?
    var siteProtectionsData: SiteProtectionsData?
    var telemetryInfo: TelemetryInfo?
    var isExpanded: Bool?

    init(
        windowUUID: WindowUUID,
        actionType: any ActionType,
        navigationDestination: MenuNavigationDestination? = nil,
        changeMenuViewTo: MainMenuDetailsViewType? = nil,
        currentTabInfo: MainMenuTabInfo? = nil,
        tabID: TabUUID? = nil,
        accountData: AccountData? = nil,
        accountIcon: UIImage? = nil,
        siteProtectionsData: SiteProtectionsData? = nil,
        telemetryInfo: TelemetryInfo? = nil,
        isExpanded: Bool? = nil
    ) {
        self.navigationDestination = navigationDestination
        self.detailsViewToShow = changeMenuViewTo
        self.currentTabInfo = currentTabInfo
        self.tabID = tabID
        self.accountData = accountData
        self.accountIcon = accountIcon
        self.siteProtectionsData = siteProtectionsData
        self.telemetryInfo = telemetryInfo
        self.isExpanded = isExpanded
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum MainMenuActionType: ActionType {
    case tapNavigateToDestination
    case tapCloseMenu
    case tapShowDetailsView
    case tapToggleUserAgent
    case updateCurrentTabInfo
    case tapMoreOptions
    case didInstantiateView
    case viewDidLoad
    case menuDismissed
    case tapAddToBookmarks
    case tapEditBookmark
    case tapZoom
    case tapToggleNightMode
    case tapAddToShortcuts
    case tapRemoveFromShortcuts
    case updateSiteProtectionsHeader
}

enum MainMenuMiddlewareActionType: ActionType {
    case requestTabInfo
    case requestTabInfoForSiteProtectionsHeader
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
