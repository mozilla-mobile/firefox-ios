// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum WallpaperSettingsError: Error {
    case itemNotFound
}

class WallpaperSettingsViewModel {
    typealias a11yIds = AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.Wallpaper
    typealias stringIds = String.Settings.Homepage.Wallpaper

    enum WallpaperSettingsLayout: Equatable {
        case compact
        case regular

        // The maximum number of items to display per row
        var itemsPerRow: Int {
            switch self {
            case .compact: return 3
            case .regular: return 4
            }
        }
    }

    struct Constants {
        struct Strings {
            struct Toast {
                static let label: String = stringIds.WallpaperUpdatedToastLabel
                static let button: String = stringIds.WallpaperUpdatedToastButton
            }
        }
    }

    private var wallpaperManager: WallpaperManagerInterface
    private var wallpaperCollections = [WallpaperCollection]()
    var tabManager: TabManagerProtocol
    var sectionLayout: WallpaperSettingsLayout = .compact // We use the compact layout as default
    var selectedIndexPath: IndexPath = IndexPath(row: 0, section: 0)

    var numberOfSections: Int {
        return wallpaperCollections.count
    }

    init(wallpaperManager: WallpaperManagerInterface = WallpaperManager(), tabManager: TabManagerProtocol) {
        self.wallpaperManager = wallpaperManager
        self.tabManager = tabManager
        setupWallpapers()
    }

    func numberOfWallpapers(in section: Int) -> Int {
        return wallpaperCollections[safe: section]?.wallpapers.count ?? 0
    }

    func sectionHeaderViewModel(for sectionIndex: Int,
                                dismissView: @escaping (() -> Void)
    ) -> WallpaperSettingsHeaderViewModel? {
        guard let collection = wallpaperCollections[safe: sectionIndex] else { return nil }

        let isClassic = collection.type == .classic
        let title: String = isClassic ? stringIds.ClassicWallpaper : stringIds.LimitedEditionWallpaper
        var description: String? = isClassic ? nil : stringIds.IndependentVoicesDescription
        let buttonTitle: String? = isClassic ? nil : stringIds.LearnMoreButton

        // the first limited edition collection has a different description, any other collection uses the default
        if sectionIndex > 1 {
            description = stringIds.LimitedEditionDefaultDescription
        }

        let buttonAction = { [weak self] in
            guard let strongSelf = self, let learnMoreUrl = collection.learnMoreUrl else { return }

            dismissView()
            let tab = strongSelf.tabManager.addTab(URLRequest(url: learnMoreUrl),
                                                   afterTab: strongSelf.tabManager.selectedTab,
                                                   isPrivate: false)
            strongSelf.tabManager.selectTab(tab, previous: nil)
        }

        return WallpaperSettingsHeaderViewModel(
            title: title,
            titleA11yIdentifier: "\(a11yIds.collectionTitle)_\(sectionIndex)",
            description: description,
            descriptionA11yIdentifier: "\(a11yIds.collectionDescription)_\(sectionIndex)",
            buttonTitle: buttonTitle,
            buttonA11yIdentifier: "\(a11yIds.collectionButton)_\(sectionIndex)",
            buttonAction: buttonAction)
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
        guard let collection = wallpaperCollections[safe: indexPath.section],
              let wallpaper = collection.wallpapers[safe: indexPath.row]
        else { return nil }
        return cellViewModel(for: wallpaper,
                             collectionType: collection.type,
                             indexPath: indexPath)
    }

    func downloadAndSetWallpaper(at indexPath: IndexPath, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let collection = wallpaperCollections[safe: indexPath.section],
              let wallpaper = collection.wallpapers[safe: indexPath.row]
        else {
            completion(.failure(WallpaperSelectorError.itemNotFound))
            return
        }

        let setWallpaperBlock = { [weak self] in
            self?.updateCurrentWallpaper(for: wallpaper, in: collection) { result in
                self?.selectedIndexPath = indexPath
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
}

private extension WallpaperSettingsViewModel {

    func setupWallpapers() {
        wallpaperCollections = wallpaperManager.availableCollections
    }

    func cellViewModel(for wallpaper: Wallpaper,
                       collectionType: WallpaperCollectionType,
                       indexPath: IndexPath
    ) -> WallpaperCellViewModel {
        let a11yId = "\(a11yIds.card)_\(indexPath.section)_\(indexPath.row)"
        var a11yLabel: String

        switch collectionType {
        case .classic:
            a11yLabel = "\(stringIds.ClassicWallpaper) \(indexPath.row + 1)"
        case .limitedEdition:
            a11yLabel = "\(stringIds.LimitedEditionWallpaper) \(indexPath.row + 1)"
        }

        if wallpaperManager.currentWallpaper == wallpaper {
            selectedIndexPath = indexPath
        }

        let cellViewModel = WallpaperCellViewModel(image: wallpaper.thumbnail,
                                                   a11yId: a11yId,
                                                   a11yLabel: a11yLabel)
        return cellViewModel
    }

    func updateCurrentWallpaper(for wallpaper: Wallpaper,
                                in collection: WallpaperCollection,
                                completion: @escaping (Result<Void, Error>) -> Void) {
        wallpaperManager.setCurrentWallpaper(to: wallpaper) { [weak self] result in
            self?.setupWallpapers()

            guard let extra = self?.telemetryMetadata(for: wallpaper, in: collection) else {
                completion(result)
                return
            }
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .wallpaperSettings,
                                         value: .wallpaperSelected,
                                         extras: extra)

           completion(result)
        }
    }

    func telemetryMetadata(for wallpaper: Wallpaper, in collection: WallpaperCollection) -> [String: String] {
        var metadata = [String: String]()

        metadata[TelemetryWrapper.EventExtraKey.wallpaperName.rawValue] = wallpaper.id

        let wallpaperTypeKey = TelemetryWrapper.EventExtraKey.wallpaperType.rawValue
        switch (wallpaper.type, collection.type) {
        case (.defaultWallpaper, _):
            metadata[wallpaperTypeKey] = "default"
        case (.other, .classic):
            metadata[wallpaperTypeKey] = collection.type.rawValue
        case (.other, .limitedEdition):
            metadata[wallpaperTypeKey] = collection.id
        }

        return metadata
    }
}
