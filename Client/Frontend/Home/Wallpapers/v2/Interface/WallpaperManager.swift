// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol WallpaperManagerInterface {
    var currentWallpaper: Wallpaper { get }
    var availableCollections: [WallpaperCollection] { get }

    func setCurrentWallpaper(to wallpaper: Wallpaper, completion: @escaping (Result<Bool, Error>) -> Void)
    func checkForUpdates()
}

/// The primary interface for the wallpaper feature.
class WallpaperManager: WallpaperManagerInterface {

    // MARK: Public Interface

    // TODO: The return values here will have to be properly updated once the plumbing
    // for wallpapers is put in place. For now, these have been added simply for
    // convenience to aid in UI development.

    /// Returns the currently selected wallpaper.
    var currentWallpaper: Wallpaper {
        return Wallpaper(id: "fxAmethyst", textColour: UIColor.red)
    }

    /// Returns all available collections and their wallpaper data. Availability is
    /// determined on locale and date ranges from the collection's metadata.
    var availableCollections: [WallpaperCollection] {
        var wallpapersForClassic: [Wallpaper] {
            var wallpapers = [Wallpaper]()
            for _ in 0..<5 {
                wallpapers.append(Wallpaper(id: "fxAmethyst", textColour: UIColor.red))
            }

            return wallpapers
        }

        var wallpapersForOther: [Wallpaper] {
            var wallpapers = [Wallpaper]()
            let rangeEnd = Int.random(in: 3...6)
            for _ in 0..<rangeEnd {
                wallpapers.append(Wallpaper(id: "fxCerulean", textColour: UIColor.purple))
            }

            return wallpapers
        }

        return [
            WallpaperCollection(
                id: "classicFirefox",
                learnMoreURL: nil,
                availableLocales: nil,
                availability: nil,
                wallpapers: wallpapersForClassic),
            WallpaperCollection(
                id: "otherCollection",
                learnMoreURL: "https://www.mozilla.com",
                availableLocales: nil,
                availability: nil,
                wallpapers: wallpapersForOther),
        ]
    }

    /// Sets and saves a selected wallpaper as currently selected wallpaper.
    ///
    /// - Parameter wallpaper: A `Wallpaper` the user has selected.
    func setCurrentWallpaper(
        to wallpaper: Wallpaper,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        completion(.success(true))
    }

    func removeDownloadedAssets() {

    }

    /// Reaches out to the server and fetches the latest metadata. This is then compared
    /// to existing metadata, and, if there are changes, performs the necessary operations
    /// to ensure parity between server data and what the user sees locally.
    func checkForUpdates() {
    }
}
