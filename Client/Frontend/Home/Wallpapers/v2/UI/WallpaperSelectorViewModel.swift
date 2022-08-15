// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class WallpaperSelectorViewModel {

    enum WallpaperSelectorLayout: Equatable {
        case compact
        case regular

        // The maximum number of items to display in the whole section
        var maxItemsToDisplay: Int {
            switch self {
            case .compact:
                return 6
            case .regular:
                return 8
            }
        }

        // The maximum number of items to display per row
        var itemsPerRow: Int {
            switch self {
            case .compact:
                return 3
            case .regular:
                return 4
            }
        }
    }

    private var wallpaperManager: WallpaperManagerInterface
    var openSettingsAction: (() -> Void)
    var sectionLayout: WallpaperSelectorLayout = .compact // We use the compact layout as default
    var wallpapers: [Wallpaper] = []

    init(wallpaperManager: WallpaperManagerInterface = WallpaperManager(), openSettingsAction: @escaping (() -> Void)) {
        self.wallpaperManager = wallpaperManager
        self.openSettingsAction = openSettingsAction
        setupWallpapers()
    }

    func updateSectionLayout(for traitCollection: UITraitCollection) {
        if traitCollection.horizontalSizeClass == .compact {
            sectionLayout = .compact
        } else {
            sectionLayout = .regular
        }
        setupWallpapers()
    }

    private func setupWallpapers() {
        wallpapers = []
        let wallPaperPerCollection = sectionLayout.maxItemsToDisplay / 2

        wallpaperManager.availableCollections.forEach { collection in
            guard wallpapers.count < sectionLayout.maxItemsToDisplay else { return }

            var numberOfWallpapers = collection.wallpapers.count > (wallPaperPerCollection - 1) ?
                wallPaperPerCollection : collection.wallpapers.count
            if numberOfWallpapers + wallpapers.count > sectionLayout.maxItemsToDisplay {
                numberOfWallpapers = sectionLayout.maxItemsToDisplay - wallpapers.count
            }
            wallpapers.append(contentsOf: collection.wallpapers[0...(numberOfWallpapers - 1)])
        }
    }
}
