/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct ReadingListClientMetadata: Equatable {
    /// The id of the record in the database
    var id: Int64
    /// A client timestamp
    var lastModified: ReadingListTimestamp

    init?(row: AnyObject) {
        let id = row.valueForKeyPath("client_id") as? NSNumber
        let lastModified = row.valueForKeyPath("client_last_modified") as? NSNumber
        if id == nil || lastModified == nil {
            return nil
        }
        self.id = id!.longLongValue
        self.lastModified = lastModified!.longLongValue
    }
}

func ==(lhs: ReadingListClientMetadata, rhs: ReadingListClientMetadata) -> Bool {
    return lhs.id == rhs.id && lhs.lastModified == rhs.lastModified
}
