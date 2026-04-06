// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared

import class MozillaAppServices.BookmarkFolderData
import class MozillaAppServices.BookmarkItemData
import class MozillaAppServices.BookmarkNodeData

final class MockBookmarksHandler: BookmarksHandler, @unchecked Sendable {
    private var folderData = BookmarkFolderData(
        guid: "1",
        dateAdded: Int64(Date().toTimestamp()),
        lastModified: Int64(Date().toTimestamp()),
        parentGUID: "123",
        position: 0,
        title: "bookmarkfolder",
        childGUIDs: [],
        children: nil)

    var getBookmarksTreeCalled = 0
    var countBookmarksTreeCalled = 0
    var getRecentBookmarksCallCount = 0
    var getRecentBookmarksResult: [BookmarkItemData]?
    var bookmarksInTreeValue = 0

    init() {}

    init(folderData: BookmarkFolderData) {
        self.folderData = folderData
    }

    func getRecentBookmarks(limit: UInt, completion: @escaping ([BookmarkItemData]) -> Void) {
        getRecentBookmarksCallCount += 1
        guard let results = getRecentBookmarksResult else {
            completion([])
            return
        }

        completion(results)
    }

    func getBookmarksTree(rootGUID: Shared.GUID, recursive: Bool) -> Deferred<Maybe<BookmarkNodeData?>> {
        getBookmarksTreeCalled += 1

        let deferred = Deferred<Maybe<BookmarkNodeData?>>()
        deferred.fill(Maybe(success: folderData))
        return deferred
    }

    func getBookmarksTree(
        rootGUID: GUID,
        recursive: Bool,
        completion: @escaping (Result<BookmarkNodeData?, any Error>) -> Void
    ) {
        completion(.success(folderData))
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
        countBookmarksTreeCalled += 1
        completion(.success(bookmarksInTreeValue))
    }

    func isBookmarked(url: String, completion: @escaping @Sendable (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }

    func deleteBookmarkNode(guid: GUID) -> Success {
        // This mock implements only a trivial search to the first level children for removal, not a recursive search
        // at all depths.
        var newChildrenGuids = folderData.childGUIDs
        newChildrenGuids.removeAll(where: { $0 == guid })

        var newChildren = folderData.children
        newChildren?.removeAll(where: { $0.guid == guid })

        folderData = BookmarkFolderData(
            guid: folderData.guid,
            dateAdded: folderData.dateAdded,
            lastModified: folderData.lastModified,
            parentGUID: folderData.parentGUID,
            position: folderData.position,
            title: folderData.title,
            childGUIDs: newChildrenGuids,
            children: newChildren
        )

        let result = Deferred<Maybe<Void>>()
        result.fill(Maybe(success: ()))
        return result
    }
}
