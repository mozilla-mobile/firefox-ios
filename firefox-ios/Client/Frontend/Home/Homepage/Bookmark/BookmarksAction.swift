// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

struct BookmarksAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let bookmarks: [BookmarkConfiguration]?
    var isEnabled: Bool?

    init(bookmarks: [BookmarkConfiguration]? = nil,
         isEnabled: Bool? = nil,
         windowUUID: WindowUUID,
         actionType: any ActionType
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.bookmarks = bookmarks
        self.isEnabled = isEnabled
    }
}

enum BookmarksActionType: ActionType {
    case toggleShowSectionSetting
}

enum BookmarksMiddlewareActionType: ActionType {
    case initialize
}

enum BookmarkAction {
    case add
    case remove
}
