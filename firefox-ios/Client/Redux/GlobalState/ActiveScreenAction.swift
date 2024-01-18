// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

class ScreenActionContext: ActionContext {
    let screen: AppScreen
    init(screen: AppScreen, windowUUID: WindowUUID) {
        self.screen = screen
        super.init(windowUUID: windowUUID)
    }
}

enum AppScreen {
    case browserViewController
    case themeSettings
    case tabsTray
    case tabsPanel
    case remoteTabsPanel
    case tabPeek
}

enum ActiveScreensStateAction: Action {
    case showScreen(ScreenActionContext)
    case closeScreen(ScreenActionContext)
}
