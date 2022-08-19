// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

private struct WallpaperSelectorItem {
    let wallpaper: Wallpaper
    let collectionType: WallpaperCollectionType
}

class WallpaperSelectorViewModel {

    enum WallpaperSelectorLayout: Equatable {
        case compact
        case regular

        // The maximum number of items to display in the whole section
        var maxItemsToDisplay: Int {
            switch self {
            case .compact: return 6
            case .regular: return 8
            }
        }

        // The maximum number of items to display per row
        var itemsPerRow: Int {
            switch self {
            case .compact: return 3
            case .regular: return 4
            }
        }

        // The maximum number of seasonal items to display
        var maxNumberOfSeasonalItems: Int {
            switch self {
            case .compact: return 3
            case .regular: return 5
            }
        }
    }

    private var wallpaperManager: WallpaperManagerInterface
    private var wallpaperItems = [WallpaperSelectorItem]()
    var openSettingsAction: (() -> Void)
    var sectionLayout: WallpaperSelectorLayout = .compact // We use the compact layout as default

    var numberOfWallpapers: Int {
        return wallpaperItems.count
    }

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

    func updateCurrentWallpaper(at indexPath: IndexPath, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let wallpaperItem = wallpaperItems[safe: indexPath.row] else {
            completion(.success(false))
            return
        }
        wallpaperManager.setCurrentWallpaper(to: wallpaperItem.wallpaper, completion: completion)
        setupWallpapers()
    }

    func cellViewModel(for indexPath: IndexPath) -> WallpaperCellViewModel? {
        guard let wallpaperItem = wallpaperItems[safe: indexPath.row] else {
            return nil
        }
        return cellViewModel(for: wallpaperItem.wallpaper,
                             collectionType: wallpaperItem.collectionType,
                             number: indexPath.row)
    }
}

private extension WallpaperSelectorViewModel {

    func setupWallpapers() {
        wallpaperItems = []
        let classicCollection = wallpaperManager.availableCollections.first { $0.type == .classic }
        let seasonalCollection = wallpaperManager.availableCollections.first { $0.type == .limitedEdition }

        let seasonalWallpapers = collectWallpapers(for: seasonalCollection,
                                                   maxNumber: sectionLayout.maxNumberOfSeasonalItems)

        let maxNumberOfClassic = sectionLayout.maxItemsToDisplay - seasonalWallpapers.count
        let classicWallpapers = collectWallpapers(for: classicCollection,
                                                  maxNumber: maxNumberOfClassic)

        wallpaperItems.append(contentsOf: classicWallpapers.map { WallpaperSelectorItem(wallpaper: $0,
                                                                                    collectionType: .classic) })
        wallpaperItems.append(contentsOf: seasonalWallpapers.map { WallpaperSelectorItem(wallpaper: $0,
                                                                                     collectionType: .limitedEdition) })
    }

    func collectWallpapers(for collection: WallpaperCollection?, maxNumber: Int) -> [Wallpaper] {
        guard let collection = collection else { return [] }

        var wallpapers = [Wallpaper]()
        for wallpaper in collection.wallpapers {
            if wallpapers.count < maxNumber {
                wallpapers.append(wallpaper)
            } else {
                break
            }
        }
        return wallpapers
    }

    func cellViewModel(for wallpaper: Wallpaper,
                       collectionType: WallpaperCollectionType,
                       number: Int
    ) -> WallpaperCellViewModel {
        let a11yId = "\(AccessibilityIdentifiers.Onboarding.Wallpaper.card)_\(number)"
        var a11yLabel: String

        switch collectionType {
        case .classic:
            a11yLabel = "\(String.Onboarding.ClassicWallpaper) \(number)"
        case .limitedEdition:
            a11yLabel = "\(String.Onboarding.LimitedEditionWallpaper) \(number)"
        }

        let needsDownload = wallpaper.type == .other && wallpaper.landscape == nil
        let cellViewModel = WallpaperCellViewModel(image: wallpaper.thumbnail,
                                                   a11yId: a11yId,
                                                   a11yLabel: a11yLabel,
                                                   isSelected: wallpaperManager.currentWallpaper == wallpaper,
                                                   needsDownload: needsDownload)
        return cellViewModel
    }
}
