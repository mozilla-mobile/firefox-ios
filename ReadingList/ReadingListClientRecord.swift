/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct ReadingListClientRecord: Equatable {
    public let clientMetadata: ReadingListClientMetadata
    public let serverMetadata: ReadingListServerMetadata?

    public let url: String
    public let title: String
    public let addedBy: String
    public let unread: Bool
    public let archived: Bool
    public let favorite: Bool

    /// Initializer for when a record is loaded from a database row
    public init?(row: AnyObject) {
        let clientMetadata = ReadingListClientMetadata(row: row)
        if clientMetadata == nil {
            return nil
        }

        let serverMetadata = ReadingListServerMetadata(row: row)
        let url = row.valueForKeyPath("url") as? String
        let title = row.valueForKeyPath("title") as? String
        let addedBy = row.valueForKeyPath("added_by") as? String
        let unread = row.valueForKeyPath("unread") as? Bool
        let archived = row.valueForKeyPath("archived") as? Bool
        let favorite = row.valueForKeyPath("favorite") as? Bool

        if clientMetadata == nil || url == nil || title == nil || addedBy == nil || unread == nil {
            return nil
        }

        self.clientMetadata = clientMetadata!
        self.serverMetadata = serverMetadata

        self.url = url!
        self.title = title!
        self.addedBy = addedBy!

        self.unread = unread!
        self.archived = archived!
        self.favorite = favorite!
    }

    public var json: AnyObject {
        get {
            let json = NSMutableDictionary()
            json["url"] = url
            json["title"] = title
            json["added_by"] = addedBy
            json["unread"] = unread
            json["archived"] = archived
            json["favorite"] = favorite
            return json
        }
    }
}

public func ==(lhs: ReadingListClientRecord, rhs: ReadingListClientRecord) -> Bool {
    return lhs.clientMetadata == rhs.clientMetadata
        && lhs.serverMetadata == rhs.serverMetadata
        && lhs.url == rhs.url
        && lhs.title == rhs.title
        && lhs.addedBy == rhs.addedBy
        && lhs.unread == rhs.unread
        && lhs.archived == rhs.archived
        && lhs.favorite == rhs.favorite
}
