// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

final class BookmarksAction: Action {
    let bookmarks: [BookmarkConfiguration]?
    var isEnabled: Bool?

    init(bookmarks: [BookmarkConfiguration]? = nil,
         isEnabled: Bool? = nil,
         windowUUID: WindowUUID,
         actionType: any ActionType
    ) {
        self.bookmarks = bookmarks
        self.isEnabled = isEnabled
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum BookmarksActionType: ActionType {
    case toggleShowSectionSetting
}

enum BookmarksMiddlewareActionType: ActionType {
    case initialize
}
