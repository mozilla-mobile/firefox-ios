// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A internal model for projects with wallpapers that are timed.
private struct WallpaperCollection {
    /// The names of the wallpaper assets to be included in the collection.
    let wallpaperFileNames: [String]
    let type: WallpaperType
    let expiryDate: Date?
    /// The locales that the wallpapers will show up in. If empty,
    /// they will not show up anywhere.
    let locales: [String]?

    /// Created a collection of wallpapers offered, with the option for it to be
    /// region or time limited.
    ///
    /// - Parameters:
    ///   - names: An array of the names of the wallpapers included in the collection.
    ///   - type: The collection type.
    ///   - expiryDate: An optional expiry date, as a string in format `yyyyMMdd`, after
    ///         which the wallpapers in the array are no longer shown.
    ///   - locales: An optional set of locales used to limit the regions to which
    ///         wallpapers in the collection are shown.
    init(wallpaperFileNames: [String],
         type: WallpaperType,
         expiryDate: Date? = nil,
         locales: [String]? = nil) {
        self.wallpaperFileNames = wallpaperFileNames
        self.type = type
        self.expiryDate = expiryDate
        self.locales = locales
    }
}

struct WallpaperDataManager {

    /// Returns an array of wallpapers available to the user given their region,
    /// and various seasonal or expiration date requirements.
    var availableWallpapers: [Wallpaper] {
        var wallpapers: [Wallpaper] = []
        // Default wallpaper should always be first in the array.
        wallpapers.append(Wallpaper(named: "defaultBackground", ofType: .defaultBackground))
        wallpapers.append(contentsOf: themedWallpapers())

        return wallpapers
    }

    // MARK: - Wallpaper data
    private func themedWallpapers() -> [Wallpaper] {
        var wallpapers = [Wallpaper]()

        buildAllWallpaperCollections().forEach { collection in
            wallpapers.append(contentsOf: collection.wallpaperFileNames.compactMap { wallpaperName in

                let wallpaper = Wallpaper(named: wallpaperName,
                                          ofType: collection.type,
                                          expiringOn: collection.expiryDate,
                                          limitedToLocale: collection.locales)

                return wallpaper.isEligibleForDisplay ? wallpaper : nil
            })
        }

        return wallpapers
    }

    private func buildAllWallpaperCollections() -> [WallpaperCollection] {

        // It's preferred to create dates for the collections using
        // `Calendar.current.date(from: DateComponents(year: 2018, month: 1, day: 15))`
        return [WallpaperCollection(wallpaperFileNames: ["fxCerulean",
                                                         "fxAmethyst",
                                                         "fxSunrise"],
                                    type: .themed(type: .firefox)),
                ]
    }
}
