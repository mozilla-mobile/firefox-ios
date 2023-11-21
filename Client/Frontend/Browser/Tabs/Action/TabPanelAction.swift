// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

enum TabPanelAction: Action {
    case tabPanelDidLoad(Bool)
    case tabPanelDidAppear(Bool)
    case addNewTab(Bool)
    case closeTab(Int)
    case closeAllTabs
    case moveTab(Int, Int)
    case toggleInactiveTabs
    case closeInactiveTabs(Int)
    case closeAllInactiveTabs
    case learnMorePrivateMode

    // Middleware actions
    case didLoadTabPanel(TabDisplayModel)
    // Response to all user actions involving tabs ex: add, close and close all tabs
    case refreshTab([TabModel])
    case refreshInactiveTabs([InactiveTabsModel])
}
