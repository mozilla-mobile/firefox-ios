// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared

import class MozillaAppServices.BookmarkItemData

protocol BookmarkItem {
    var title: String { get }
    var url: String { get }
}

// This is an intermediary object to allow us to more easily use this data in a thread safe way.
// Thread safety is difficult to ensure when passing classes around by reference.
struct recentBookmark: BookmarkItem {
    var title: String
    var url: String
    var dateAdded: Timestamp

    init(bookmark: BookmarkItemData) {
        self.title = bookmark.title
        self.url = bookmark.url
        self.dateAdded = Timestamp(bookmark.dateAdded)
    }
}
