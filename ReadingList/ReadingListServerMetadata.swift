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
    init?(json: [String: Any]) {
        self.init(data: json)
    }

    init?(row: [String: Any]) {
        self.init(data: row)
    }

    private init?(data: [String: Any]) {
        guard let guid = data["id"] as? String,
            let lastModified = data["last_modified"] as? Int64 else {
                return nil
        }
        self.guid = guid
        self.lastModified = lastModified
    }
}

public func ==(lhs: ReadingListServerMetadata, rhs: ReadingListServerMetadata) -> Bool {
    return lhs.guid == rhs.guid && lhs.lastModified == rhs.lastModified
}
