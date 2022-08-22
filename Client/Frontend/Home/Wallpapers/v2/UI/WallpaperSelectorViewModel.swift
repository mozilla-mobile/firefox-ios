// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

private struct WallpaperSelectorItem {
    let wallpaper: Wallpaper
    let collection: WallpaperCollection
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

        let extra = telemetryMetadata(for: wallpaperItem)
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .onboardingWallpaperSelector,
                                     value: .wallpaperSelected,
                                     extras: extra)
    }

    func cellViewModel(for indexPath: IndexPath) -> WallpaperCellViewModel? {
        guard let wallpaperItem = wallpaperItems[safe: indexPath.row] else {
            return nil
        }
        return cellViewModel(for: wallpaperItem.wallpaper,
                             collectionType: wallpaperItem.collection.type,
                             number: indexPath.row)
    }

    func downloadAndSetWallpaper(at indexPath: IndexPath, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let wallpaperItem = wallpaperItems[safe: indexPath.row] else {
            completion(.success(false))
            return
        }

        let wallpaper = wallpaperItem.wallpaper
        let needsDownload = wallpaper.type == .other && wallpaper.landscape == nil

        let setWallpaperBlock = { [weak self] in
            self?.updateCurrentWallpaper(at: indexPath) { result in
                completion(result)
            }
        }

        if needsDownload {
            wallpaperManager.fetch(wallpaper) { result in
                switch result {
                case .success(let success):
                    if success {
                        setWallpaperBlock()
                    } else {
                        completion(result)
                    }
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
}

private extension WallpaperSelectorViewModel {

    func setupWallpapers() {
        wallpaperItems = []
        let classicCollection = wallpaperManager.availableCollections.first { $0.type == .classic }
        let seasonalCollection = wallpaperManager.availableCollections.first { $0.type == .limitedEdition }

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
