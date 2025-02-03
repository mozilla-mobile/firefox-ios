// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared

import class MozillaAppServices.BookmarkFolderData
import class MozillaAppServices.BookmarkItemData
import class MozillaAppServices.BookmarkNodeData

final class BookmarksHandlerMock: BookmarksHandler {
    private let bookmarkFolderData = BookmarkFolderData(
        guid: "1",
        dateAdded: Int64(Date().toTimestamp()),
        lastModified: Int64(Date().toTimestamp()),
        parentGUID: "123",
        position: 0,
        title: "bookmarkfolder",
        childGUIDs: [],
        children: nil)

    var getRecentBookmarksCallCount = 0
    var getRecentBookmarksCompletion: (([BookmarkItemData]) -> Void)?

    func getRecentBookmarks(limit: UInt, completion: @escaping ([BookmarkItemData]) -> Void) {
        getRecentBookmarksCallCount += 1
        getRecentBookmarksCompletion = completion
    }

    func callGetRecentBookmarksCompletion(with results: [BookmarkItemData]) {
        getRecentBookmarksCompletion?(results)
    }

    func getBookmarksTree(rootGUID: Shared.GUID, recursive: Bool) -> Deferred<Maybe<BookmarkNodeData?>> {
        let deferred = Deferred<Maybe<BookmarkNodeData?>>()
        deferred.fill(Maybe(success: bookmarkFolderData))
        return deferred
    }

    func getBookmarksTree(
        rootGUID: GUID,
        recursive: Bool,
        completion: @escaping (Result<BookmarkNodeData?, any Error>) -> Void
    ) {
        completion(.success(bookmarkFolderData))
    }

    func updateBookmarkNode(guid: Shared.GUID,
                            parentGUID: Shared.GUID?,
                            position: UInt32?,
                            title: String?,
                            url: String?) -> Success {
        succeed()
    }

    func updateBookmarkNode(
        guid: GUID,
        parentGUID: GUID?,
        position: UInt32?,
        title: String?,
        url: String?,
        completion: @escaping (Result<Void, any Error>) -> Void
    ) {
        completion(.success(()))
    }

    func countBookmarksInTrees(folderGuids: [GUID], completion: @escaping (Result<Int, Error>) -> Void) {
        completion(.success(0))
    }
}
