/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct ReadingListServerRecord {
    let serverMetadata: ReadingListServerMetadata?

    let url: String
    let title: String
    let addedBy: String
    let unread: Bool
    let archived: Bool
    let favorite: Bool

    /// Initializer for when a record is loaded from server-sent json
    init?(json: AnyObject) {
        let serverMetadata = ReadingListServerMetadata(json: json)

        let url = json.value(forKeyPath: "url") as? String
        let title = json.value(forKeyPath: "title") as? String
        let addedBy = json.value(forKeyPath: "added_by") as? String
        let unread = json.value(forKeyPath: "unread") as? Bool
        let archived = json.value(forKeyPath: "archived") as? Bool
        let favorite = json.value(forKeyPath: "favorite") as? Bool

        if serverMetadata == nil || url == nil || title == nil || addedBy == nil || unread == nil {
            return nil
        }

        self.serverMetadata = serverMetadata

        self.url = url!
        self.title = title!
        self.addedBy = addedBy!

        self.unread = unread!
        self.archived = archived!
        self.favorite = favorite!
    }

}
