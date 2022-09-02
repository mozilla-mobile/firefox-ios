// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Describes a wallpaper collection.
struct WallpaperCollection: Codable, Equatable {
    static func == (lhs: WallpaperCollection, rhs: WallpaperCollection) -> Bool {
        return lhs.id == rhs.id
                && lhs.learnMoreURLString == rhs.learnMoreURLString
                && lhs.availableLocales == rhs.availableLocales
                && lhs.availability == rhs.availability
                && lhs.wallpapers == rhs.wallpapers
                && lhs.description == rhs.description
                && lhs.heading == rhs.heading
    }

    enum CodingKeys: String, CodingKey {
        case id
        case learnMoreURLString = "learn-more-url"
        case availableLocales = "available-locales"
        case availability = "availability-range"
        case wallpapers
        case description
        case heading
    }

    let id: String
    private let learnMoreURLString: String?
    let availableLocales: [String]?
    let availability: WallpaperCollectionAvailability?
    let wallpapers: [Wallpaper]
    let description: String?
    let heading: String?

    var type: WallpaperCollectionType {
        return id == "classic-firefox" ? .classic : .limitedEdition
    }

    var learnMoreUrl: URL? {
        guard let urlString = learnMoreURLString else { return nil }
        return URL(string: urlString)
    }

    init(
        id: String,
        learnMoreURL: String?,
        availableLocales: [String]?,
        availability: WallpaperCollectionAvailability?,
        wallpapers: [Wallpaper],
        description: String?,
        heading: String?
    ) {
        self.id = id
        self.learnMoreURLString = learnMoreURL
        self.availableLocales = availableLocales
        self.availability = availability
        self.wallpapers = wallpapers
        self.description = description
        self.heading = heading
    }
}
