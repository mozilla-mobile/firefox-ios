// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

class ScreenAction: Action {
    let screen: AppScreen

    init(windowUUID: WindowUUID,
         actionType: ActionType,
         screen: AppScreen) {
        self.screen = screen
        super.init(windowUUID: windowUUID,
                   actionType: actionType)
    }
}

enum AppScreen {
    case browserViewController
    case onboardingViewController
    case homepage
    case themeSettings
    case tabsTray
    case tabsPanel
    case remoteTabsPanel
    case tabPeek
    case mainMenu
    case mainMenuDetails
    case microsurvey
    case trackingProtection
    case toolbar
}

enum ScreenActionType: ActionType {
    case showScreen
    case closeScreen
}
