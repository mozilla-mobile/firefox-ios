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
        return URL(string: urlString, encodingInvalidCharacters: false)
    }

    /// Wallpaper collections availability:
    /// - Date
    /// 1. If the date is `nil`, the assumption is that it's available at all times
    /// 2. Start date determines the day on which the collection shows up
    /// 3. End date determines the last day on which the collection shows up
    /// - Locales
    /// 1. If the locale variable is `nil` OR the locale array is empty, it's available everywhere
    /// 2. Locale is restricted to locales specified in the array, if not empty
    var isAvailable: Bool {
        let isDateAvailable = availability?.isAvailable ?? true
        var isLocaleAvailable = false

        if let availableLocales = availableLocales {
            isLocaleAvailable = availableLocales.isEmpty || availableLocales.contains(Locale.current.identifier)
        } else {
            isLocaleAvailable = true
        }

        return isDateAvailable && isLocaleAvailable
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
