// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class WallpaperSelectorViewModel {

    private let maxWallpapers = 6
    private var wallpaperManager: WallpaperManager
    var wallpapers: [Wallpaper] = []

    init(wallpaperManager: WallpaperManager = WallpaperManager()) {
        self.wallpaperManager = wallpaperManager
        setupWallpapers()
    }

    private func setupWallpapers() {
        wallpaperManager.availableCollections.forEach { collection in
            guard collection.isAvailableNow, wallpapers.count < maxWallpapers else { return }

            var numberOfWallpapers = collection.wallpapers.count > 2 ? 3 : collection.wallpapers.count
            if numberOfWallpapers + wallpapers.count > maxWallpapers {
                numberOfWallpapers = maxWallpapers - wallpapers.count
            }
            wallpapers.append(contentsOf: collection.wallpapers[0...(numberOfWallpapers - 1)])
        }
    }

}
