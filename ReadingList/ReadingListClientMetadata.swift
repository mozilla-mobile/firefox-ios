/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct ReadingListClientMetadata: Equatable {
    /// The id of the record in the database
    public var id: Int64
    /// A client timestamp
    public var lastModified: ReadingListTimestamp

    public init?(row: [String: Any]) {
        guard let id = row["client_id"] as? Int64,
            let lastModified = row["client_last_modified"] as? Int64 else {
            return nil
        }
        self.id = id
        self.lastModified = lastModified
    }
}

public func ==(lhs: ReadingListClientMetadata, rhs: ReadingListClientMetadata) -> Bool {
    return lhs.id == rhs.id && lhs.lastModified == rhs.lastModified
}
