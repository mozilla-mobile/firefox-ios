// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

final class MainMenuAction: Action {
    override init(windowUUID: WindowUUID, actionType: any ActionType) {
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum MainMenuActionType: ActionType {
    case viewDidLoad
    case updateCurrentTabInfo(MainMenuTabInfo?)
    case mainMenuDidAppear
    case toggleNightMode
    case closeMenu
    case show(MainMenuNavigationDestination)
    case toggleUserAgent
}

enum MainMenuNavigationDestination: Equatable {
    case newTab
    case newPrivateTab
    case bookmarks
    case customizeHomepage
    case downloads
    case findInPage
    case goToURL(URL?)
    case history
    case passwords
    case settings
}
