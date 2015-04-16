/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct ReadingListServerMetadata: Equatable {
    var guid: String
    var lastModified: ReadingListTimestamp

    init(guid: String, lastModified: ReadingListTimestamp) {
        self.guid = guid
        self.lastModified = lastModified
    }

    /// Initialize from server record.
    init?(json: AnyObject) {
        var guid = json.valueForKeyPath("id") as? String
        var lastModified = json.valueForKeyPath("last_modified") as? NSNumber
        if guid == nil || lastModified == nil {
            return nil
        }
        self.guid = guid!
        self.lastModified = lastModified!.longLongValue
    }

    init?(row: AnyObject) {
        var guid = row.valueForKeyPath("id") as? String
        var lastModified = row.valueForKeyPath("last_modified") as? NSNumber
        if guid == nil || lastModified == nil {
            return nil
        }
        self.guid = guid!
        self.lastModified = lastModified!.longLongValue
    }
}

func ==(lhs: ReadingListServerMetadata, rhs: ReadingListServerMetadata) -> Bool {
    return lhs.guid == rhs.guid && lhs.lastModified == rhs.lastModified
}
