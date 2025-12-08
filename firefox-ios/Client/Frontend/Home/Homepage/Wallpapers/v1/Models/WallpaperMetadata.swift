// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Metadata, fetched from the server, to update wallpaper availability.
struct WallpaperMetadata: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case lastUpdated = "last-updated-date"
        case collections
    }

    let lastUpdated: Date
    let collections: [WallpaperCollection]
}
