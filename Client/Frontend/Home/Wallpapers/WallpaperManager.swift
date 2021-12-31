// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Shared

struct Wallpaper {
    private let name: String
    let image: UIImage?

    init(named name: String) {
        self.name = name
        self.image = UIImage(named: name)
    }
}

struct WallpaperManager {

    // MARK: - Variables
    private let defaultWallpaper = Wallpaper(named: "defaultWallpaper")
    private let wallpaper01 = Wallpaper(named: "wallpaper1")
    private let wallpaper02 = Wallpaper(named: "wallpaper2")
    private let wallpaper03 = Wallpaper(named: "wallpaper3")
    private let wallpaper04 = Wallpaper(named: "wallpaper4")
    private let wallpaper05 = Wallpaper(named: "wallpaper5")
    var wallpaperArray: [Wallpaper]

    private let userDefaults: UserDefaults

    // Computed properties
    var currentIndex: Int {
        let index = userDefaults.integer(forKey: PrefsKeys.WallpaperManagerCustomizationKeyIndex)
        return index
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

    var currentWallpaper: Wallpaper {
        return wallpaperArray[currentIndex]
    }

    // MARK: - Initializer
    init(with userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
        self.wallpaperArray = [defaultWallpaper, wallpaper01, wallpaper02, wallpaper03, wallpaper04, wallpaper05]
    }

    // MARK: - Public methods
    public func updateTo(index: Int) {
        userDefaults.set(index, forKey: PrefsKeys.WallpaperManagerCustomizationKeyIndex)
    }

    public func cycleWallpaper() {
        let newIndex = calculateIndex(using: currentIndex, and: wallpaperArray)
        updateTo(index: newIndex)
    }

    // MARK: - Private functions
    private func calculateIndex(using currentIndex: Int, and wallpaperArray: [Wallpaper]) -> Int {

        let newIndex = currentIndex + 1
        let maxIndex = wallpaperArray.count - 1

        if newIndex > maxIndex {
            return 0
        } else {
            return newIndex
        }
    }
}
