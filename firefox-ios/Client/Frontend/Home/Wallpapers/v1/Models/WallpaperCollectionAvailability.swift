// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Describes the start and end date of a collection's availability. Either case being
/// `nil` implies forever availability in that time direction.
struct WallpaperCollectionAvailability: Codable, Equatable {
    static func == (lhs: WallpaperCollectionAvailability, rhs: WallpaperCollectionAvailability) -> Bool {
        return lhs.start == rhs.start
                && lhs.end == rhs.end
    }

    let start: Date?
    let end: Date?

    var isAvailable: Bool {
        let now = Date()
        let start = start ?? now - 1
        let end = end ?? now + 1
        return start < now && end > now
    }
}
