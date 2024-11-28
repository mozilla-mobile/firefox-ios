// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

private struct WallpaperSelectorItem {
    let wallpaper: Wallpaper
    let collection: WallpaperCollection
}

public enum WallpaperSelectorError: Error {
    case itemNotFound
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
    private var availableCollections: [WallpaperCollection]
    private var wallpaperItems = [WallpaperSelectorItem]()
    var sectionLayout: WallpaperSelectorLayout = .compact // We use the compact layout as default
    var selectedIndexPath: IndexPath?

    var numberOfWallpapers: Int {
        return wallpaperItems.count
    }

    init(wallpaperManager: WallpaperManagerInterface = WallpaperManager()) {
        self.wallpaperManager = wallpaperManager
        self.availableCollections = wallpaperManager.availableCollections
        setupWallpapers()
        selectedIndexPath = initialSelectedIndexPath
    }

    func updateSectionLayout(for traitCollection: UITraitCollection) {
        if traitCollection.horizontalSizeClass == .compact {
            sectionLayout = .compact
        } else {
            sectionLayout = .regular
        }
        setupWallpapers()
    }

    func cellViewModel(for indexPath: IndexPath) -> WallpaperCellViewModel? {
        guard let wallpaperItem = wallpaperItems[safe: indexPath.row] else {
            return nil
        }
        return cellViewModel(for: wallpaperItem.wallpaper,
                             collectionType: wallpaperItem.collection.type,
                             number: indexPath.row)
    }

    func downloadAndSetWallpaper(at indexPath: IndexPath, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let wallpaperItem = wallpaperItems[safe: indexPath.row] else {
            completion(.failure(WallpaperSelectorError.itemNotFound))
            return
        }

        let wallpaper = wallpaperItem.wallpaper

        let setWallpaperBlock = { [weak self] in
            self?.updateCurrentWallpaper(for: wallpaperItem) { result in
                if case .success = result {
                    self?.selectedIndexPath = indexPath
                }
                completion(result)
            }
        }

        if wallpaper.needsToFetchResources {
            wallpaperManager.fetchAssetsFor(wallpaper) { result in
                switch result {
                case .success:
                    setWallpaperBlock()
                case .failure:
                    completion(result)
                }
            }
        } else {
            setWallpaperBlock()
        }
    }

    func sendImpressionTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .onboardingWallpaperSelector,
                                     value: nil,
                                     extras: nil)
    }

    func sendDismissImpressionTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .close,
                                     object: .onboardingWallpaperSelector,
                                     value: nil,
                                     extras: nil)
    }

    func removeAssetsOnDismiss() {
        wallpaperManager.removeUnusedAssets()
    }
}

private extension WallpaperSelectorViewModel {
    var initialSelectedIndexPath: IndexPath? {
        if let index = wallpaperItems.firstIndex(where: { $0.wallpaper == wallpaperManager.currentWallpaper }) {
            return IndexPath(row: index, section: 0)
        }
        return nil
    }

    func setupWallpapers() {
        wallpaperItems = []
        let classicCollection = availableCollections.first { $0.type == .classic }
        let seasonalCollection = availableCollections.first { $0.type == .limitedEdition }

        let seasonalItems = collectWallpaperItems(for: seasonalCollection,
                                                  maxNumber: sectionLayout.maxNumberOfSeasonalItems)

        let maxNumberOfClassic = sectionLayout.maxItemsToDisplay - seasonalItems.count
        let classicItems = collectWallpaperItems(for: classicCollection,
                                                 maxNumber: maxNumberOfClassic)

        wallpaperItems.append(contentsOf: classicItems)
        wallpaperItems.append(contentsOf: seasonalItems)
    }

    func collectWallpaperItems(for collection: WallpaperCollection?, maxNumber: Int) -> [WallpaperSelectorItem] {
        guard let collection = collection else { return [] }

        var wallpapers = [WallpaperSelectorItem]()
        for wallpaper in collection.wallpapers {
            if wallpapers.count < maxNumber {
                wallpapers.append(WallpaperSelectorItem(wallpaper: wallpaper,
                                                        collection: collection))
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
            a11yLabel = "\(String.Onboarding.Wallpaper.ClassicWallpaper) \(number + 1)"
        case .limitedEdition:
            a11yLabel = "\(String.Onboarding.Wallpaper.LimitedEditionWallpaper) \(number + 1)"
        }

        let cellViewModel = WallpaperCellViewModel(image: wallpaper.thumbnail,
                                                   a11yId: a11yId,
                                                   a11yLabel: a11yLabel)
        return cellViewModel
    }

    func updateCurrentWallpaper(for wallpaperItem: WallpaperSelectorItem,
                                completion: @escaping (Result<Void, Error>) -> Void) {
        wallpaperManager.setCurrentWallpaper(to: wallpaperItem.wallpaper) { [weak self] result in
            guard let extra = self?.telemetryMetadata(for: wallpaperItem) else {
                completion(result)
                return
            }
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .onboardingWallpaperSelector,
                                         value: .wallpaperSelected,
                                         extras: extra)

           completion(result)
        }
    }

    func telemetryMetadata(for item: WallpaperSelectorItem) -> [String: String] {
        var metadata = [String: String]()

        metadata[TelemetryWrapper.EventExtraKey.wallpaperName.rawValue] = item.wallpaper.id

        let wallpaperTypeKey = TelemetryWrapper.EventExtraKey.wallpaperType.rawValue
        switch item.wallpaper.type {
        case .defaultWallpaper:
            metadata[wallpaperTypeKey] = "default"
        case .other:
            switch item.collection.type {
            case .classic:
                metadata[wallpaperTypeKey] = item.collection.type.rawValue
            case .limitedEdition:
                metadata[wallpaperTypeKey] = item.collection.id
            }
        }

        return metadata
    }
}
