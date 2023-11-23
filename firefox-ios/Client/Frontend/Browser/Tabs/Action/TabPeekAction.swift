// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

enum TabPeekAction: Action {
    // MARK: - View Actions
    case didLoadTabPeek(tabID: String)
    case addToBookmarks(tabID: String)
    case sendToDevice(tabID: String)
    case copyURL(tabID: String)
    case closeTab(tabID: String)

    // MARK: - Middleware Actions
    case loadTabPeek(tabPeekModel: TabPeekModel)
}
