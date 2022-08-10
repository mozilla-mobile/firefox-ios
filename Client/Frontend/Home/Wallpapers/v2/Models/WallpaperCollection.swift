// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Describes a wallpaper collection.
struct WallpaperCollection: Equatable {
    enum CodingKeys: String, CodingKey {
        case id
        case learnMoreURL = "learn-more-url"
        case availableLocales = "available-locales"
        case availability = "availability-range"
        case wallpapers
    }

    let id: String
    let learnMoreUrl: URL?
    let availableLocales: [String]?
    let availability: WallpaperCollectionAvailability?
    let wallpapers: [Wallpaper]
}

extension WallpaperCollection: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = try values.decode(String.self, forKey: .id)
        availableLocales = try values.decode([String].self, forKey: .availableLocales)
        availability = try values.decode(WallpaperCollectionAvailability.self, forKey: .availability)
        wallpapers = try values.decode([Wallpaper].self, forKey: .wallpapers)

        let learnMoreString = try values.decode(String.self, forKey: .learnMoreURL)
        learnMoreUrl = URL(string: learnMoreString)
    }
}

extension WallpaperCollection: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let urlString = learnMoreUrl?.absoluteString
        try container.encode(id, forKey: .id)
        try container.encode(urlString, forKey: .learnMoreURL)
        try container.encode(availableLocales, forKey: .availableLocales)
        try container.encode(availability, forKey: .availability)
        try container.encode(wallpapers, forKey: .wallpapers)
    }
}
