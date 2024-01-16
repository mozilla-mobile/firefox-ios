// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Storage

enum TabPanelAction: Action {
    case tabPanelDidLoad(Bool)
    case tabPanelDidAppear(Bool)
    case addNewTab(URLRequest?, Bool)
    case closeTab(String)
    case undoClose
    case closeAllTabs
    case undoCloseAllTabs
    case moveTab(Int, Int)
    case toggleInactiveTabs
    case closeInactiveTabs(String)
    case undoCloseInactiveTab
    case closeAllInactiveTabs
    case undoCloseAllInactiveTabs
    case learnMorePrivateMode(URLRequest)
    case selectTab(String)
    case showToast(ToastType)
    case hideUndoToast
    case showShareSheet(URL)

    // Middleware actions
    case didLoadTabPanel(TabDisplayModel)
    case refreshTab([TabModel]) // Response to all user actions involving tabs ex: add, close and close all tabs
    case refreshInactiveTabs([InactiveTabsModel])
}
