// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

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

    private var theme: Theme
    private var wallpaperManager: WallpaperManagerInterface
    private var wallpaperCollections = [WallpaperCollection]()
    var tabManager: TabManager
    var sectionLayout: WallpaperSettingsLayout = .compact // We use the compact layout as default
    var selectedIndexPath: IndexPath?

    var numberOfSections: Int {
        return wallpaperCollections.count
    }

    init(wallpaperManager: WallpaperManagerInterface = WallpaperManager(),
         tabManager: TabManager,
         theme: Theme) {
        self.wallpaperManager = wallpaperManager
        self.tabManager = tabManager
        self.theme = theme
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
        let classicString = String(format: stringIds.ClassicWallpaper, AppName.shortName.rawValue)
        let title: String = isClassic ? classicString : stringIds.LimitedEditionWallpaper
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
            theme: theme,
            title: title,
            titleA11yIdentifier: "\(a11yIds.collectionTitle)_\(sectionIndex)",
            description: description,
            descriptionA11yIdentifier: "\(a11yIds.collectionDescription)_\(sectionIndex)",
            buttonTitle: buttonTitle,
            buttonA11yIdentifier: "\(a11yIds.collectionButton)_\(sectionIndex)",
            buttonAction: collection.learnMoreUrl != nil ? buttonAction : nil)
    }

    func updateSectionLayout(for traitCollection: UITraitCollection) {
        if traitCollection.horizontalSizeClass == .compact {
            sectionLayout = .compact
        } else {
            sectionLayout = .regular
        }
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

    func removeAssetsOnDismiss() {
        wallpaperManager.removeUnusedAssets()
    }

    func selectHomepageTab() {
        let homepageTab = getHomepageTab(isPrivate: tabManager.selectedTab?.isPrivate ?? false)

        tabManager.selectTab(homepageTab, previous: nil)
    }

    /// Get mostRecentHomePage used if none is available we add and select a new homepage Tab
    /// - Parameter isPrivate: If private mode is selected
    private func getHomepageTab(isPrivate: Bool) -> Tab {
        guard let homepageTab = tabManager.getMostRecentHomepageTab() else {
            return tabManager.addTab(nil, afterTab: nil, isPrivate: isPrivate)
        }

        return homepageTab
    }
}

private extension WallpaperSettingsViewModel {
    var initialSelectedIndexPath: IndexPath? {
        for (sectionIndex, collection) in wallpaperCollections.enumerated() {
            if let rowIndex = collection.wallpapers.firstIndex(where: { $0 == wallpaperManager.currentWallpaper }) {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        return nil
    }

    func setupWallpapers() {
        wallpaperCollections = wallpaperManager.availableCollections
        selectedIndexPath = initialSelectedIndexPath
    }

    func cellViewModel(for wallpaper: Wallpaper,
                       collectionType: WallpaperCollectionType,
                       indexPath: IndexPath
    ) -> WallpaperCellViewModel {
        let a11yId = "\(a11yIds.card)_\(indexPath.section)_\(indexPath.row)"
        var a11yLabel: String

        switch collectionType {
        case .classic:
            a11yLabel = "\(String(format: stringIds.ClassicWallpaper, AppName.shortName.rawValue)) \(indexPath.row + 1)"
        case .limitedEdition:
            a11yLabel = "\(stringIds.LimitedEditionWallpaper) \(indexPath.row + 1)"
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
        case (.none, _):
            metadata[wallpaperTypeKey] = "default"
        case (.other, .classic):
            metadata[wallpaperTypeKey] = collection.type.rawValue
        case (.other, .limitedEdition):
            metadata[wallpaperTypeKey] = collection.id
        }

        return metadata
    }
}
