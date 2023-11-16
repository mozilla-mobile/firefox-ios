// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

enum TabTrayAction: Action {
    case tabTrayDidLoad(TabTrayPanelType)
    case changePanel(TabTrayPanelType)
    case openExistingTab
    case addNewTab(Bool) // isPrivate
    case closeTab(Int)
    case closeAllTabs
    case moveTab(Int, Int)

    // Private tabs action
    case learnMorePrivateMode

    // Middleware actions
    case didLoadTabData(TabTrayState)
    // Response to all user actions involving tabs ex: add, close and close all tabs
    case refreshTab([TabCellState])
}
