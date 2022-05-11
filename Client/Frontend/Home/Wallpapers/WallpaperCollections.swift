// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - Wallpaper Collections
// These collections should remain in code for as long as possible.
// They are required for not just downloading wallpapers, but also
// deleting them from the disk once they expire.
extension WallpaperDataManager {
    private func projectHouseCollection() -> WallpaperCollection {
        let houseExpiryDate = Calendar.current.date(
            from: DateComponents(year: 2022, month: 5, day: 1))

        return WallpaperCollection(
            wallpaperFileNames: [WallpaperID(name: "trRed",
                                             accessibilityLabel: "Turning Red wallpaper, giant red panda"),
                                 WallpaperID(name: "trGroup",
                                             accessibilityLabel: "Turning Red wallpaper, Mei and friends")],
            ofType: .themed(type: .projectHouse),
            expiringOn: houseExpiryDate,
            limitedToLocales: ["en_US", "es_US"])
    }

    private func v100CelebrationCollection() -> WallpaperCollection {
        return WallpaperCollection(
            wallpaperFileNames: [WallpaperID(name: "beachVibes",
                                             accessibilityLabel: accessibilityIDs.FxBeachHillsWallpaper),
                                 WallpaperID(name: "twilightHills",
                                             accessibilityLabel: accessibilityIDs.FxTwilightHillsWallpaper)],
            ofType: .themed(type: .v100Celebration))
    }
}
