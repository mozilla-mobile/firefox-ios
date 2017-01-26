/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct ReadingListClientMetadata: Equatable {
    /// The id of the record in the database
    public var id: Int64
    /// A client timestamp
    public var lastModified: ReadingListTimestamp

    public init?(row: AnyObject) {
        let id = row.value(forKeyPath: "client_id") as? NSNumber
        let lastModified = row.value(forKeyPath: "client_last_modified") as? NSNumber
        if id == nil || lastModified == nil {
            return nil
        }
        self.id = id!.int64Value
        self.lastModified = lastModified!.int64Value
    }
}

public func ==(lhs: ReadingListClientMetadata, rhs: ReadingListClientMetadata) -> Bool {
    return lhs.id == rhs.id && lhs.lastModified == rhs.lastModified
}
