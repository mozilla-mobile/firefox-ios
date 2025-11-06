// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Common

struct TabPeekAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let tabUUID: TabUUID?
    let tabPeekModel: TabPeekModel?

    init(tabUUID: TabUUID? = nil,
         tabPeekModel: TabPeekModel? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.tabUUID = tabUUID
        self.tabPeekModel = tabPeekModel
    }
}

enum TabPeekActionType: ActionType {
    // MARK: - View Actions
    case didLoadTabPeek
    case addToBookmarks
    case removeBookmark
    case copyURL
    case closeTab

    // MARK: - Middleware Actions
    case loadTabPeek
}
