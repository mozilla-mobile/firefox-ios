// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Describes a wallpaper collection.
struct WallpaperCollection: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case id
        case availableLocales = "available-locales"
        case availability = "availability-range"
        case wallpapers
    }

    let id: String
    let availableLocales: [String]?
    let availability: WallpaperCollectionAvailability?
    let wallpapers: [Wallpaper]
}
