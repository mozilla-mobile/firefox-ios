// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

func ReadingListNow() -> Timestamp {
    return Timestamp(Date.timeIntervalSinceReferenceDate * 1000.0)
}

let ReadingListDefaultUnread = true
let ReadingListDefaultArchived = false
let ReadingListDefaultFavorite = false

public protocol ReadingList {
    func getAvailableRecords() -> Deferred<Maybe<[ReadingListItem]>>
    func getAvailableRecords(completion: @escaping ([ReadingListItem]) -> Void)
    func deleteRecord(_ record: ReadingListItem, completion: ((Bool) -> Void)?)
    @discardableResult
    func createRecordWithURL(_ url: String, title: String, addedBy: String) -> Deferred<Maybe<ReadingListItem>>
    func getRecordWithURL(_ url: String) -> Deferred<Maybe<ReadingListItem>>
    @discardableResult
    func updateRecord(_ record: ReadingListItem, unread: Bool) -> Deferred<Maybe<ReadingListItem>>
}

public struct ReadingListItem: Equatable {
    public let id: Int
    public let lastModified: Timestamp
    public let url: String
    public let title: String
    public let addedBy: String
    public let unread: Bool
    public let archived: Bool
    public let favorite: Bool

    /// Initializer for when a record is loaded from a database row
    public init(
        id: Int,
        lastModified: Timestamp,
        url: String,
        title: String,
        addedBy: String,
        unread: Bool = true,
        archived: Bool = false,
        favorite: Bool = false
    ) {
        self.id = id
        self.lastModified = lastModified
        self.url = url
        self.title = title
        self.addedBy = addedBy
        self.unread = unread
        self.archived = archived
        self.favorite = favorite
    }
}

public func == (lhs: ReadingListItem, rhs: ReadingListItem) -> Bool {
    return lhs.id == rhs.id
        && lhs.lastModified == rhs.lastModified
        && lhs.url == rhs.url
        && lhs.title == rhs.title
        && lhs.addedBy == rhs.addedBy
        && lhs.unread == rhs.unread
        && lhs.archived == rhs.archived
        && lhs.favorite == rhs.favorite
}
