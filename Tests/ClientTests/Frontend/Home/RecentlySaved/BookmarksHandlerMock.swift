// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

class BookmarksHandlerMock: BookmarksHandler {
    var getRecentBookmarksCallCount = 0
    var getRecentBookmarksCompletion: (([BookmarkItemData]) -> Void)?

    func getRecentBookmarks(limit: UInt, completion: @escaping ([BookmarkItemData]) -> Void) {
        getRecentBookmarksCallCount += 1
        getRecentBookmarksCompletion = completion
    }

    func callGetRecentBookmarksCompletion(with results: [BookmarkItemData]) {
        getRecentBookmarksCompletion?(results)
    }
}
