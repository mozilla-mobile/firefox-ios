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
    public init?(row: [String: Any]) {
        guard let clientMetadata = ReadingListClientMetadata(row: row) else {
            return nil
        }

        guard let url = row["url"] as? String,
            let title = row["title"] as? String,
            let addedBy = row["added_by"] as? String,
            let unread = row["unread"] as? Bool else {
            return nil
        }

        self.clientMetadata = clientMetadata
        self.serverMetadata = ReadingListServerMetadata(row: row)

        self.url = url
        self.title = title
        self.addedBy = addedBy

        self.unread = unread

        self.archived = row["archived"] as? Bool ?? false
        self.favorite = row["favorite"] as? Bool ?? false
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
