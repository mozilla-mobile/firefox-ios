/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct ReadingListClientRecord: Equatable {
    let clientMetadata: ReadingListClientMetadata
    let serverMetadata: ReadingListServerMetadata?

    let url: String
    let title: String
    let addedBy: String
    let unread: Bool
    let archived: Bool
    let favorite: Bool

    /// Initializer for when a record is loaded from a database row
    init?(row: AnyObject) {
        let clientMetadata = ReadingListClientMetadata(row: row)
        if clientMetadata == nil {
            return nil
        }

        let serverMetadata = ReadingListServerMetadata(row: row)

        let id = row.valueForKeyPath("id") as? String
        let lastModified = row.valueForKeyPath("last_modified") as? NSNumber

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

    var json: AnyObject {
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

func ==(lhs: ReadingListClientRecord, rhs: ReadingListClientRecord) -> Bool {
    return lhs.clientMetadata == rhs.clientMetadata
        && lhs.serverMetadata == rhs.serverMetadata
        && lhs.url == rhs.url
        && lhs.title == rhs.title
        && lhs.addedBy == rhs.addedBy
        && lhs.unread == rhs.unread
        && lhs.archived == rhs.archived
        && lhs.favorite == rhs.favorite
}
