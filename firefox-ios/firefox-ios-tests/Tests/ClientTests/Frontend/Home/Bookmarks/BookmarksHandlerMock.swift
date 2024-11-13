// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared

import class MozillaAppServices.BookmarkFolderData
import class MozillaAppServices.BookmarkItemData
import class MozillaAppServices.BookmarkNodeData

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

    var responseForBookmarksTree: Maybe<BookmarkNodeData?> = Maybe(success: BookmarkFolderData(
        guid: "1",
        dateAdded: Int64(Date().toTimestamp()),
        lastModified: Int64(Date().toTimestamp()),
        parentGUID: "123",
        position: 0,
        title: "bookmarkfolder",
        childGUIDs: [],
        children: nil))
    func getBookmarksTree(rootGUID: Shared.GUID, recursive: Bool) -> Deferred<Maybe<BookmarkNodeData?>> {
        let deferred = Deferred<Maybe<BookmarkNodeData?>>()
        deferred.fill(responseForBookmarksTree)
        return deferred
    }

    func updateBookmarkNode(guid: Shared.GUID,
                            parentGUID: Shared.GUID?,
                            position: UInt32?,
                            title: String?,
                            url: String?) -> Success {
        succeed()
    }

    func countBookmarksInTrees(folderGuids: [GUID]) -> Deferred<Maybe<Int>> {
        let deferred = Deferred<Maybe<Int>>()
        deferred.fill(Maybe(success: 0))
        return deferred
    }
}
