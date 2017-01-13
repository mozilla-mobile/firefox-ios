/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct ReadingListServerMetadata: Equatable {
    public var guid: String
    public var lastModified: ReadingListTimestamp

    init(guid: String, lastModified: ReadingListTimestamp) {
        self.guid = guid
        self.lastModified = lastModified
    }

    /// Initialize from server record.
    init?(json: AnyObject) {
        let guid = json.value(forKeyPath: "id") as? String
        let lastModified = json.value(forKeyPath: "last_modified") as? NSNumber
        if guid == nil || lastModified == nil {
            return nil
        }
        self.guid = guid!
        self.lastModified = lastModified!.int64Value
    }

    init?(row: AnyObject) {
        let guid = row.value(forKeyPath: "id") as? String
        let lastModified = row.value(forKeyPath: "last_modified") as? NSNumber
        if guid == nil || lastModified == nil {
            return nil
        }
        self.guid = guid!
        self.lastModified = lastModified!.int64Value
    }
}

public func ==(lhs: ReadingListServerMetadata, rhs: ReadingListServerMetadata) -> Bool {
    return lhs.guid == rhs.guid && lhs.lastModified == rhs.lastModified
}
