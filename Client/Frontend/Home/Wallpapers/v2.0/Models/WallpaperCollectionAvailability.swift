// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Describes the start and end date of a collection's availability. Either case being
/// `nil` implies forever availability in that time direction.
struct WallpaperCollectionAvailability: Codable {
    let start: String?
    let end: String?
}
