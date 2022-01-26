// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A internal model for projects with wallpapers that are timed.
fileprivate struct WallpaperCollection {
    /// The names of the wallpaper assets to be included in the collection.
    let names: [String]
    let type: WallpaperType
    let expiryDate: String?
    /// The locales that the wallpapers will show up in. If empty,
    /// they will not show up anywhere.
    let locales: [String]?

    init(names: [String],
         type: WallpaperType,
         expiryDate: String? = nil,
         locales: [String]? = nil) {
        self.names = names
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
        wallpapers.append(Wallpaper(named: "defaultBackground", ofType: .defaultBackground))
        wallpapers.append(contentsOf: themedWallpapers())

        return wallpapers
    }

    // MARK: - Wallpaper data
    private func themedWallpapers() -> [Wallpaper] {
        var wallpapers = [Wallpaper]()

        buildAllWallpaperCollections().forEach { project in
            wallpapers.append(contentsOf: project.names.compactMap { wallpaperName in

                let wallpaper = Wallpaper(named: wallpaperName,
                                          ofType: project.type,
                                          expiringOn: project.expiryDate,
                                          limitedToLocale: project.locales)

                return wallpaper.isElibibleForDisplay ? wallpaper : nil
            })
        }

        return wallpapers
    }

    private func buildAllWallpaperCollections() -> [WallpaperCollection] {
        return [WallpaperCollection(names: ["fxWallpaper1",
                                            "fxWallpaper2"],
                                    type: .themed(type: .firefoxDefault)),
                WallpaperCollection(names: ["themedWallpaper1",
                                            "themedWallpaper2",
                                            "themedWallpaper3"],
                                    type: .themed(type: .projectHouse),
                                    expiryDate: "20220430",
                                    locales: ["en_US", "es_US"]),
                ]
    }
}
