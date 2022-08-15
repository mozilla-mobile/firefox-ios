// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class WallpaperSelectorViewModel {

    private let maxWallpapers = UIDevice.current.userInterfaceIdiom == .pad ? 8 : 6
    private var wallpaperManager: WallpaperManager
    var wallpapers: [Wallpaper] = []

    init(wallpaperManager: WallpaperManager = WallpaperManager()) {
        self.wallpaperManager = wallpaperManager
        setupWallpapers()
    }

    private func setupWallpapers() {
        let wallPaperPerCollection = maxWallpapers / 2

        wallpaperManager.availableCollections.forEach { collection in
            guard wallpapers.count < maxWallpapers else { return }

            var numberOfWallpapers = collection.wallpapers.count > (wallPaperPerCollection - 1) ?
                wallPaperPerCollection : collection.wallpapers.count
            if numberOfWallpapers + wallpapers.count > maxWallpapers {
                numberOfWallpapers = maxWallpapers - wallpapers.count
            }
            wallpapers.append(contentsOf: collection.wallpapers[0...(numberOfWallpapers - 1)])
        }
    }

}
