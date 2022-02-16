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
    private let storageManager: WallpaperStorageUtility

    var numberOfWallpapers: Int {
        return dataManager.availableWallpapers.count
    }
    
    var currentWallpaperImage: UIImage? {
        return storageManager.getCurrentWallpaperImage()
    }

    var currentWallpaper: Wallpaper {
        guard let currentWallpaper = storageManager.getCurrentWallpaperObject() else {
            // Returning the default wallpaper if nothing else is currently set,
            // as default will always exist. The reason this is returned is this manner
            // is that, on fresh app installation, no wallpaper will be set. Thus,
            // if this variable is accessed, it would return nil, when a wallpaper
            // actually be required.
            return dataManager.availableWallpapers[0]
        }

        return currentWallpaper
    }

    var currentlySelectedWallpaperIndex: Int? {
        // If no wallpaper was ever set, then we must be at index 0
        guard let currentWallpaper = storageManager.getCurrentWallpaperObject() else { return 0 }

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
        get { return !userDefaults.bool(forKey: PrefsKeys.WallpaperManagerLogoSwitchPreference) }
        set { userDefaults.set(!newValue, forKey: PrefsKeys.WallpaperManagerLogoSwitchPreference) }
    }

    // MARK: - Initializer
    init(with userDefaults: UserDefaults = UserDefaults.standard,
         wallpaperDataManager: WallpaperDataManager = WallpaperDataManager(),
         wallpaperStorageManager: WallpaperStorageUtility = WallpaperStorageUtility()
    ) {
        self.userDefaults = userDefaults
        self.dataManager = wallpaperDataManager
        self.storageManager = wallpaperStorageManager
    }

    // MARK: - Public methods
    public func updateSelectedWallpaperIndex(to index: Int) {
        let wallpapers = dataManager.availableWallpapers
        guard index <= (wallpapers.count - 1) else { return }
        storageManager.store(dataManager.availableWallpapers[index],
                             and: dataManager.getImageSet(at: index))
    }

    public func cycleWallpaper() {
        let newIndex = calculateNextIndex(using: currentlySelectedWallpaperIndex,
                                          and: dataManager.availableWallpapers)
        updateSelectedWallpaperIndex(to: newIndex)
    }
    
    public func getImageAt(index: Int, inLandscape: Bool) -> UIImage? {
        let image = dataManager.getImageSet(at: index)
        return inLandscape ? image.landscape : image.portrait
    }
    
    public func getAccessibilityLabelForWallpaper(at index: Int) -> String {
        return dataManager.availableWallpapers[index].accessibilityLabel
    }
    
    public func runResourceVerification() {
        dataManager.verifyResources()
    }

    // MARK: - Private functions
    private func calculateNextIndex(
        using currentIndex: Int?,
        and wallpaperArray: [Wallpaper]
    ) -> Int {
        
        guard let currentIndex = currentIndex else { return 0 }

        let newIndex = currentIndex + 1
        let maxIndex = wallpaperArray.count - 1

        if newIndex > maxIndex {
            return 0
        }
        
        return newIndex
    }
}
