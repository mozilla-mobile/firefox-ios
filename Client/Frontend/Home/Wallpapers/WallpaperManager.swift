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
    private var wallpaperArray: [Wallpaper]
    private let userDefaults: UserDefaults

    private var currentIndex: Int {
        let index = userDefaults.integer(forKey: PrefsKeys.WallpaperManagerCustomizationKey)
        return index
    }

    var currentWallpaper: Wallpaper {
        return wallpaperArray[currentIndex]
    }

    // MARK: - Initializer
    init(with userDefaults: UserDefaults = UserDefaults.standard, and customWallpapers: [Wallpaper]? = nil) {
        if let customWallpapers = customWallpapers {
            self.wallpaperArray = customWallpapers
        } else {
            self.wallpaperArray = [defaultWallpaper, wallpaper01, wallpaper02]
        }
        self.userDefaults = userDefaults
    }

    // MARK: - Public methods
    public func updateTo(index: Int) {
        userDefaults.set(index, forKey: PrefsKeys.WallpaperManagerCustomizationKey)
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
