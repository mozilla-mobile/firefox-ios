/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class ReadingListItem {
    public var id: Int? = nil
    public var guid: String?
    public var contentStatus: Int = 0
    public var clientLastModified: Int64
    public var lastModified: Int64?
    public var storedOn: Int64?
    public var addedOn: Int64?
    public var markedRead_on: Int64?
    public var isDeleted: Bool = false
    public var isArchived: Bool = false
    public var isUnread: Bool = true
    public var isArticle: Bool = false
    public var isFavorite: Bool = false
    public var url: String
    public var title: String?
    public var resolvedUrl: String?
    public var resolvedTitle: String?
    public var excerpt: String?
    public var addedBy: String?
    public var markedReadBy: String?
    public var wordCount: Int = 0
    public var readPosition: Int = 0

    public init(url: String, title: String?, resolvedUrl: String? = nil, resolvedTitle: String? = nil) {
        self.url = url
        self.title = title
        self.resolvedUrl = resolvedUrl
        self.resolvedTitle = resolvedTitle
        self.clientLastModified = Int64(NSDate().timeIntervalSince1970 * 1000.0)
    }
}

public protocol ReadingList {
    func clear(complete: (success: Bool) -> Void)
    func get(complete: (data: Cursor) -> Void)
    func add(#item: ReadingListItem, complete: (success: Bool) -> Void)

    func shareItem(item: ShareItem)
}
