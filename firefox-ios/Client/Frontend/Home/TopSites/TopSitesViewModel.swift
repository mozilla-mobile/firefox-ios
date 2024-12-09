// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Storage

class TopSitesViewModel {
    struct UX {
        static let cellEstimatedSize = CGSize(width: 85, height: 94)
        static let cardSpacing: CGFloat = 16
        static let minCards: Int = 4
    }

    weak var delegate: HomepageDataModelDelegate?
    var isZeroSearch: Bool
    var theme: Theme
    var tilePressedHandler: ((Site, Bool) -> Void)?
    var tileLongPressedHandler: ((Site, UIView?) -> Void)?

    private let profile: Profile
    private var sentImpressionTelemetry = [String: Bool]()
    private var unfilteredTopSites: [TopSite] = []
    private var topSites: [TopSite] = []
    private let dimensionManager: TopSitesDimension
    private var numberOfItems: Int = 0
    private var numberOfRows: Int = 0

    private let topSitesDataAdaptor: TopSitesDataAdaptor
    private let topSiteHistoryManager: TopSiteHistoryManager
    private let googleTopSiteManager: GoogleTopSiteManager
    private var wallpaperManager: WallpaperManager

    init(profile: Profile,
         isZeroSearch: Bool = false,
         theme: Theme,
         wallpaperManager: WallpaperManager) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch
        self.theme = theme
        self.dimensionManager = TopSitesDimensionImplementation()

        self.topSiteHistoryManager = TopSiteHistoryManager(profile: profile)
        self.googleTopSiteManager = GoogleTopSiteManager(prefs: profile.prefs)
        let adaptor = TopSitesDataAdaptorImplementation(profile: profile,
                                                        topSiteHistoryManager: topSiteHistoryManager,
                                                        googleTopSiteManager: googleTopSiteManager)
        topSitesDataAdaptor = adaptor
        self.wallpaperManager = wallpaperManager
        adaptor.delegate = self
    }

    func tilePressed(site: TopSite, position: Int) {
        topSitePressTracking(homeTopSite: site, position: position)
        tilePressedHandler?(site.site, site.isGoogleURL)
    }

    // MARK: - Telemetry

    func sendImpressionTelemetry(_ homeTopSite: TopSite, position: Int) {
        guard !hasSentImpressionForTile(homeTopSite) else { return }
        homeTopSite.impressionTracking(position: position)
    }

    private func topSitePressTracking(homeTopSite: TopSite, position: Int) {
        // Top site extra
        let type = homeTopSite.getTelemetrySiteType()
        let topSiteExtra = [TelemetryWrapper.EventExtraKey.topSitePosition.rawValue: "\(position)",
                            TelemetryWrapper.EventExtraKey.topSiteTileType.rawValue: type]

        // Origin extra
        let originExtra = TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
        let extras = originExtra.merge(with: topSiteExtra)

        // Bookmarks from topSites
        let isBookmarkedSite = profile.places.isBookmarked(url: homeTopSite.site.url).value.successValue ?? false
        if isBookmarkedSite {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .open,
                                         object: .bookmark,
                                         value: .openBookmarksFromTopSites)
        }

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .topSiteTile,
                                     value: nil,
                                     extras: extras)

        // Sponsored tile specific telemetry
        if let tile = homeTopSite.site as? SponsoredTile {
            SponsoredTileTelemetry.sendClickTelemetry(tile: tile, position: position)
        }
    }

    private func hasSentImpressionForTile(_ homeTopSite: TopSite) -> Bool {
        guard sentImpressionTelemetry[homeTopSite.site.url] != nil else {
            sentImpressionTelemetry[homeTopSite.site.url] = true
            return false
        }
        return true
    }

    // MARK: - Context actions

    func hideURLFromTopSites(_ site: Site) {
        topSiteHistoryManager.removeDefaultTopSitesTile(site: site)
        // We make sure to remove all history for URL so it doesn't show anymore in the
        // top sites, this is the approach that Android takes too.
        self.profile.places.deleteVisitsFor(url: site.url).uponQueue(.main) { _ in
            NotificationCenter.default.post(name: .TopSitesUpdated, object: self)
        }
    }

    func pinTopSite(_ site: Site) {
        _ = profile.pinnedSites.addPinnedTopSite(site)
    }

    func removePinTopSite(_ site: Site) {
        googleTopSiteManager.removeGoogleTopSite(site: site)
        topSiteHistoryManager.removeTopSite(site: site)
    }
}

// MARK: HomeViewModelProtocol
extension TopSitesViewModel: HomepageViewModelProtocol, FeatureFlaggable {
    var sectionType: HomepageSectionType {
        return .topSites
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return LabelButtonHeaderViewModel(
            title: nil,
            titleA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.topSites,
            isButtonHidden: true,
            textColor: wallpaperManager.currentWallpaper.textColor)
    }

    var isEnabled: Bool {
        return profile.prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.TopSiteSection) ?? true
    }

    func numberOfItemsInSection() -> Int {
        return numberOfItems
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.cellEstimatedSize.height)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.cellEstimatedSize.height)
        )

        let interface = TopSitesUIInterface(trait: traitCollection, availableWidth: size.width)
        let sectionDimension = dimensionManager.getSectionDimension(for: topSites,
                                                                    numberOfRows: numberOfRows,
                                                                    interface: interface)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitem: item,
                                                       count: sectionDimension.numberOfTilesPerRow)
        group.interItemSpacing = NSCollectionLayoutSpacing.fixed(UX.cardSpacing)
        let section = NSCollectionLayoutSection(group: group)

        let leadingInset = HomepageViewModel.UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: leadingInset,
            bottom: HomepageViewModel.UX.spacingBetweenSections - TopSiteItemCell.UX.bottomSpace,
            trailing: leadingInset
        )
        section.interGroupSpacing = UX.cardSpacing

        return section
    }

    var hasData: Bool {
        return !topSites.isEmpty
    }

    func refreshData(for traitCollection: UITraitCollection,
                     size: CGSize,
                     isPortrait: Bool = UIWindow.isPortrait,
                     device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
                     orientation: UIDeviceOrientation = UIDevice.current.orientation) {
        let interface = TopSitesUIInterface(trait: traitCollection,
                                            availableWidth: size.width)
        numberOfRows = topSitesDataAdaptor.numberOfRows
        unfilteredTopSites = topSitesDataAdaptor.getTopSitesData()
        let sectionDimension = dimensionManager.getSectionDimension(for: unfilteredTopSites,
                                                                    numberOfRows: numberOfRows,
                                                                    interface: interface)
        numberOfItems = sectionDimension.numberOfRows * sectionDimension.numberOfTilesPerRow
        topSites = unfilteredTopSites
        if numberOfItems < unfilteredTopSites.count {
            let range = numberOfItems..<unfilteredTopSites.count
            topSites.removeSubrange(range)
        }
    }

    func screenWasShown() {
        sentImpressionTelemetry = [String: Bool]()
    }

    func setTheme(theme: Theme) {
        self.theme = theme
    }
}

// MARK: - FxHomeTopSitesManagerDelegate
extension TopSitesViewModel: TopSitesManagerDelegate {
    func didLoadNewData() {
        ensureMainThread {
            self.unfilteredTopSites = self.topSitesDataAdaptor.getTopSitesData()
            self.topSites = self.unfilteredTopSites
            self.numberOfRows = self.topSitesDataAdaptor.numberOfRows
            guard self.isEnabled else { return }
            self.delegate?.reloadView()
        }
    }
}

// MARK: - FxHomeSectionHandler
extension TopSitesViewModel: HomepageSectionHandler {
    func configure(_ collectionView: UICollectionView,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        if let contentItem = topSites[safe: indexPath.row],
           let cell = collectionView.dequeueReusableCell(cellType: TopSiteItemCell.self, for: indexPath) {
            let textColor = wallpaperManager.currentWallpaper.textColor

            cell.configure(contentItem,
                           position: indexPath.row,
                           theme: theme,
                           textColor: textColor)
            sendImpressionTelemetry(contentItem, position: indexPath.row)
            return cell
        } else if let cell = collectionView.dequeueReusableCell(cellType: EmptyTopSiteCell.self, for: indexPath) {
            cell.applyTheme(theme: theme)
            return cell
        }

        return UICollectionViewCell()
    }

    func configure(_ cell: UICollectionViewCell,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        // Setup is done through configure(collectionView:indexPath:), shouldn't be called
        return UICollectionViewCell()
    }

    func didSelectItem(at indexPath: IndexPath,
                       homePanelDelegate: HomePanelDelegate?,
                       libraryPanelDelegate: LibraryPanelDelegate?) {
        guard let site = topSites[safe: indexPath.row]  else { return }

        tilePressed(site: site, position: indexPath.row)
    }

    func handleLongPress(with collectionView: UICollectionView, indexPath: IndexPath) {
        guard let tileLongPressedHandler = tileLongPressedHandler,
              let site = topSites[safe: indexPath.row]?.site
        else { return }

        let sourceView = collectionView.cellForItem(at: indexPath)
        tileLongPressedHandler(site, sourceView)
    }
}
