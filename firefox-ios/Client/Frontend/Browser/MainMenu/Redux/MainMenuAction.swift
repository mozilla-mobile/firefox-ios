// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MenuKit
import Redux

struct MenuNavigationDestination: Equatable {
    let destination: MainMenuNavigationDestination
    let urlToVisit: URL?

    init(
        _ destination: MainMenuNavigationDestination,
        urlToVisit: URL? = nil
    ) {
        self.destination = destination
        self.urlToVisit = urlToVisit
    }
}

final class MainMenuAction: Action {
    var navigationDestination: MenuNavigationDestination?
    var currentTabInfo: MainMenuTabInfo?

    init(
        windowUUID: WindowUUID,
        actionType: any ActionType,
        navigationDestination: MenuNavigationDestination? = nil,
        urlToVisit: URL? = nil,
        currentTabInfo: MainMenuTabInfo? = nil
    ) {
        self.navigationDestination = navigationDestination
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum MainMenuDetailsViewType {
    case tools
    case save
}

enum MainMenuActionType: ActionType {
    case closeMenu
    case mainMenuDidAppear
    case show
    case openDetailsViewTo(MainMenuDetailsViewType, title: String)
    case toggleNightMode
    case toggleUserAgent
    case updateCurrentTabInfo
    case viewDidLoad
    case viewWillDisappear
}

enum MainMenuNavigationDestination: Equatable {
    case bookmarks
    case customizeHomepage
    case downloads
    case findInPage
    case goToURL
    case history
    case newTab
    case newPrivateTab
    case passwords
    case settings
}

enum MainMenuMiddlewareActionType: ActionType {
    case requestTabInfo
}

enum MainMenuDetailsActionType: ActionType {
    case dismissView
    case updateSubmenuType(MainMenuDetailsViewType)
    case viewDidLoad
    case viewDidDisappear
}
