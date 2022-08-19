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
    var openSettingsAction: (() -> Void)
    var sectionLayout: WallpaperSelectorLayout = .compact // We use the compact layout as default
    var wallpaperCellModels = [WallpaperCellViewModel]()

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
}
private extension WallpaperSelectorViewModel {

    func setupWallpapers() {
        wallpaperCellModels = []
        let classicCollection = wallpaperManager.availableCollections.first { $0.type == .classic }
        let seasonalCollection = wallpaperManager.availableCollections.first { $0.type == .limitedEdition }

        let seasonalCellModels = createCellModels(for: seasonalCollection,
                                                  maxNumber: sectionLayout.maxNumberOfSeasonalItems)

        let maxNumberOfClassic = sectionLayout.maxItemsToDisplay - seasonalCellModels.count
        let classicCellModels = createCellModels(for: classicCollection,
                                                 maxNumber: maxNumberOfClassic)

        wallpaperCellModels.append(contentsOf: classicCellModels)
        wallpaperCellModels.append(contentsOf: seasonalCellModels)
    }

    func createCellModels(for collection: WallpaperCollection?, maxNumber: Int) -> [WallpaperCellViewModel] {
        guard let collection = collection else { return [] }

        var cellModels = [WallpaperCellViewModel]()
        for (index, wallpaper) in collection.wallpapers.enumerated() {
            if cellModels.count < maxNumber {
                cellModels.append(cellViewModel(for: wallpaper,
                                                collectionType: collection.type,
                                                number: index + 1))
            }
        }
        return cellModels
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

        let cellViewModel = WallpaperCellViewModel(image: wallpaper.thumbnail,
                                                   a11yId: a11yId,
                                                   a11yLabel: a11yLabel,
                                                   isSelected: wallpaperManager.currentWallpaper == wallpaper)
        return cellViewModel
    }
}
