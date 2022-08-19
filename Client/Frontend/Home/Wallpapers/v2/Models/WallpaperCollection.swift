// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Describes a wallpaper collection.
struct WallpaperCollection: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case id
        case learnMoreURLString = "learn-more-url"
        case availableLocales = "available-locales"
        case availability = "availability-range"
        case wallpapers
    }

    let id: String
    private let learnMoreURLString: String?
    let availableLocales: [String]?
    let availability: WallpaperCollectionAvailability?
    let wallpapers: [Wallpaper]

    var type: WallpaperCollectionType {
        return id == "classicFirefox" ? .classic : .limitedEdition
    }

    init(
        id: String,
        learnMoreURL: String?,
        availableLocales: [String]?,
        availability: WallpaperCollectionAvailability?,
        wallpapers: [Wallpaper]
    ) {
        self.id = id
        self.learnMoreURLString = learnMoreURL
        self.availableLocales = availableLocales
        self.availability = availability
        self.wallpapers = wallpapers
    }

    var learnMoreUrl: URL? {
        guard let urlString = learnMoreURLString else { return nil }
        return URL(string: urlString)
    }
}
