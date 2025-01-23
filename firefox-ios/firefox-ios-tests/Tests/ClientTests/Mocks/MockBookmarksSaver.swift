// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Shared
import MozillaAppServices

class MockBookmarksSaver: BookmarksSaver {
    var saveCalled = 0
    var createBookmarkCalled = 0
    var restoreBookmarkNodeCalled = 0
    var mockCreateGuid: GUID?

    var savedBookmarkURL: String?
    var savedBookmarkTitle: String?
    var savedBookmarkPosition: UInt32?

    func save(bookmark: any FxBookmarkNode,
              parentFolderGUID: String) async -> Result<GUID?, any Error> {
        saveCalled += 1
        return Result.success(mockCreateGuid)
    }

    func createBookmark(url: String, title: String?, position: UInt32?) async {
        savedBookmarkURL = url
        savedBookmarkTitle = title
        savedBookmarkPosition = position
        createBookmarkCalled += 1
    }

    func restoreBookmarkNode(bookmarkNode: BookmarkNodeData,
                             parentFolderGUID: String,
                             completion: @escaping (Shared.GUID?) -> Void) {
        restoreBookmarkNodeCalled += 1
    }
}
