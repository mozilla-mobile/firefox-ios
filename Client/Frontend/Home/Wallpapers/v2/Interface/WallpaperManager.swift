// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol WallpaperManagerInterface {
    var currentWallpaper: Wallpaper { get }
    var availableCollections: [WallpaperCollection] { get }
    var canOnboardingBeShown: Bool { get }

    func setCurrentWallpaper(to wallpaper: Wallpaper, completion: @escaping (Result<Void, Error>) -> Void)
    func fetch(_ wallpaper: Wallpaper, completion: @escaping (Result<Void, Error>) -> Void)
    func removeDownloadedAssets()
    func checkForUpdates()
}

/// The primary interface for the wallpaper feature.
class WallpaperManager: WallpaperManagerInterface, FeatureFlaggable {

    // MARK: Public Interface

    // TODO: The return values here will have to be properly updated once the plumbing
    // for wallpapers is put in place. For now, these have been added simply for
    // convenience to aid in UI development.

    /// Returns the currently selected wallpaper.
    var currentWallpaper: Wallpaper {
        return Wallpaper(id: "fxDefault", textColour: UIColor.green)
    }

    /// Returns all available collections and their wallpaper data. Availability is
    /// determined on locale and date ranges from the collection's metadata.
    var availableCollections: [WallpaperCollection] {
        var wallpapersForClassic: [Wallpaper] {
            var wallpapers = [Wallpaper]()
            wallpapers.append(Wallpaper(id: "fxDefault", textColour: UIColor.green))

            for _ in 0..<4 {
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

    /// Determines whether the wallpaper onboarding can be shown
    var canOnboardingBeShown: Bool {
        let wallpaperThumbnailsDownloaded = true
        guard let wallpaperVersion: WallpaperVersion = featureFlags.getCustomState(for: .wallpaperVersion),
              wallpaperVersion == .v2,
              featureFlags.isFeatureEnabled(.wallpaperOnboardingSheet, checking: .buildOnly),
              wallpaperThumbnailsDownloaded // check if wallpaper thumbnails are downloaded here
        else { return false }

        // Roux: add private var for thumbnails downloaded
        return true
    }

    /// Sets and saves a selected wallpaper as currently selected wallpaper.
    ///
    /// - Parameter wallpaper: A `Wallpaper` the user has selected.
    func setCurrentWallpaper(
        to wallpaper: Wallpaper,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        completion(.success(()))
    }

    /// Fetches the images for a specific wallpaper.
    ///
    /// - Parameter wallpaper: A `Wallpaper` for which images should be downloaded.
    /// - Parameter completion: The block that is called when the image download completes.
    ///                      If the images is loaded successfully, the block is called with
    ///                      a `.success` with the data associated. Otherwise, it is called
    ///                      with a `.failure` and passed an error.
    func fetch(_ wallpaper: Wallpaper, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.1) {
            completion(.success(()))
        }
    }

    func removeDownloadedAssets() {

    }

    /// Reaches out to the server and fetches the latest metadata. This is then compared
    /// to existing metadata, and, if there are changes, performs the necessary operations
    /// to ensure parity between server data and what the user sees locally.
    func checkForUpdates() {
    }
}
