/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class ReadingListItem {
    var id: Int? = nil
    var guid: String?
    var contentStatus: Int = 0
    var clientLastModified: Int
    var lastModified: Int?
    var storedOn: Int?
    var addedOn: Int?
    var markedRead_on: Int?
    var isDeleted: Bool = false
    var isArchived: Bool = false
    var isUnread: Bool = true
    var isArticle: Bool = false
    var isFavorite: Bool = false
    var url: String
    var title: String?
    var resolvedUrl: String?
    var resolvedTitle: String?
    var excerpt: String?
    var addedBy: String?
    var markedReadBy: String?
    var wordCount: Int = 0
    var readPosition: Int = 0

    public init(url: String, title: String?, resolvedUrl: String? = nil, resolvedTitle: String? = nil) {
        self.url = url
        self.title = title
        self.resolvedUrl = resolvedUrl
        self.resolvedTitle = resolvedTitle
        self.clientLastModified = Int(NSDate().timeIntervalSince1970 * 1000.0)
    }
}

public protocol ReadingList {
    init(files: FileAccessor)

    func clear(complete: (success: Bool) -> Void)
    func get(complete: (data: Cursor) -> Void)
    func add(#item: ReadingListItem, complete: (success: Bool) -> Void)
}
