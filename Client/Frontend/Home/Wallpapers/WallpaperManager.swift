// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Shared

struct WallpaperManager {

    // MARK: - Variables
    private let userDefaults: UserDefaults
    private let dataManager: WallpaperDataManager
    private let storageManager: WallpaperStorageManager

    var wallpapers: [Wallpaper] {
        return dataManager.availableWallpapers
    }

    var currentWallpaperImage: UIImage? {
        let key = UIDevice.current.orientation.isLandscape ? PrefsKeys.WallpaperManagerCurrentWallpaperImageLandscape : PrefsKeys.WallpaperManagerCurrentWallpaperImage

        return storageManager.retrieveSavedImageWith(key: key)
    }

    var currentWallpaper: Wallpaper {
        guard let currentWallpaper = storageManager.retrieveCurrentWallpaperObject() else {
            // Returning the default wallpaper if nothing else is currently set
            // as default will always exist
            return wallpapers[0]
        }

        return currentWallpaper
    }

    var currentIndex: Int? {
        // If no wallpaper was ever set, then we must be at index 0
        guard let currentWallpaper = storageManager.retrieveCurrentWallpaperObject() else { return 0 }

        for (index, wallpaper) in dataManager.availableWallpapers.enumerated() {
            if wallpaper == currentWallpaper { return index }
        }

        return nil
    }

    /// Returns the user's preference for whether or not to be able to change wallpapers
    /// by tapping on the logo on the homepage.
    ///
    /// Because the default value of this feature is actually `true`, we have to invert
    /// the actual value. Therefore, if the setting is `false`, we treat the setting as
    /// being turned on, as `false` is what UserDefaults returns when a bool does not
    /// exist for a key.
    var switchWallpaperFromLogoEnabled: Bool {
        // ROUX - update button behaviour based on this thing
        get { return !userDefaults.bool(forKey: PrefsKeys.WallpaperManagerLogoSwitchPreference) }
        set { userDefaults.set(!newValue, forKey: PrefsKeys.WallpaperManagerLogoSwitchPreference) }
    }

    // MARK: - Initializer
    init(with userDefaults: UserDefaults = UserDefaults.standard,
         wallpaperData: WallpaperDataManager = WallpaperDataManager(),
         wallpaperStorageManager: WallpaperStorageManager = WallpaperStorageManager()) {
        self.userDefaults = userDefaults
        self.dataManager = wallpaperData
        self.storageManager = wallpaperStorageManager
    }

    // MARK: - Public methods
    public func updateTo(index: Int) {
        let wallpapers = dataManager.availableWallpapers
        guard index <= (wallpapers.count - 1) else { return }
        updateSelectedWallpaper(to: wallpapers[index])
    }

    public func cycleWallpaper() {
        let newIndex = calculateIndex(using: currentIndex,
                                      and: dataManager.availableWallpapers)
        updateTo(index: newIndex)
    }

    // MARK: - Private functions
    private func calculateIndex(using currentIndex: Int?, and wallpaperArray: [Wallpaper]) -> Int {
        guard let currentIndex = currentIndex else { return 0 }

        let newIndex = currentIndex + 1
        let maxIndex = wallpaperArray.count - 1

        if newIndex > maxIndex {
            return 0
        }
        
        return newIndex
    }

    // MARK: - Wallpaper storage
    private func updateSelectedWallpaper(to wallpaper: Wallpaper) {
        storageManager.store(wallpaper)
    }
}
