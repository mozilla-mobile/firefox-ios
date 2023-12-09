// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

enum TabPanelAction: Action {
    case tabPanelDidLoad(Bool)
    case tabPanelDidAppear(Bool)
    case addNewTab(URLRequest?, Bool)
    case closeTab(String)
    case closeAllTabs
    case moveTab(Int, Int)
    case toggleInactiveTabs
    case closeInactiveTabs(String)
    case closeAllInactiveTabs
    case learnMorePrivateMode(URLRequest)
    case selectTab(String)

    // Middleware actions
    case didLoadTabPanel(TabDisplayModel)
    // Response to all user actions involving tabs ex: add, close and close all tabs
    case refreshTab([TabModel])
    case refreshInactiveTabs([InactiveTabsModel])
}
