// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage

protocol TopSitesViewModelDelegate: AnyObject {
    func reloadTopSites()
}

protocol TopSitesViewModel where Self: HomepageViewModelProtocol {
    var delegate: TopSitesViewModelDelegate? { get set }
    var isZeroSearch: Bool { get set }
    var tilePressedHandler: ((Site, Bool) -> Void)? { get set }
    var tileLongPressedHandler: ((Site, UIView?) -> Void)? { get set }

    // Tile actions
    func tilePressed(site: TopSite, position: Int)
    func hideURLFromTopSites(_ site: Site)
    func removePinTopSite(_ site: Site)
    func pinTopSite(_ site: Site)

    // Data
    func refreshIfNeeded(forceTopSites: Bool)

    // Telemetry
    func sendImpressionTelemetry(_ homeTopSite: TopSite, position: Int)
}

class TopSitesViewModelImplementation: TopSitesViewModel {

    struct UX {
        static let numberOfItemsPerRowForSizeClassIpad = UXSizeClasses(compact: 3, regular: 4, other: 2)
        static let cellEstimatedSize: CGSize = CGSize(width: 100, height: 120)
    }

    weak var delegate: TopSitesViewModelDelegate?
    var isZeroSearch: Bool
    var tilePressedHandler: ((Site, Bool) -> Void)?
    var tileLongPressedHandler: ((Site, UIView?) -> Void)?

    private let profile: Profile
    private var sentImpressionTelemetry = [String: Bool]()
    private var topSites: [TopSite] = []
    private var dimensionManager: DimensionManager
    private var tileManager: TopSitesManager

    init(profile: Profile, isZeroSearch: Bool = false) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch

        self.dimensionManager = DimensionManagerImplementation()
        self.tileManager = TopSitesManager(profile: profile)
        tileManager.delegate = self
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
        guard let host = site.tileURL.normalizedHost else { return }
        tileManager.topSiteHistoryManager.removeDefaultTopSitesTile(site: site)

        profile.history.removeHostFromTopSites(host).uponQueue(.main) { [weak self] result in
            guard result.isSuccess, let self = self else { return }
            self.tileManager.refreshIfNeeded(forceTopSites: true)
        }
    }

    func removePinTopSite(_ site: Site) {
        tileManager.removePinTopSite(site: site)
    }

    func pinTopSite(_ site: Site) {
        profile.history.addPinnedTopSite(site).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.tileManager.refreshIfNeeded(forceTopSites: true)
        }
    }

    func refreshIfNeeded(forceTopSites: Bool) {
        tileManager.refreshIfNeeded(forceTopSites: forceTopSites)
    }
}

// MARK: HomeViewModelProtocol
extension TopSitesViewModelImplementation: HomepageViewModelProtocol, FeatureFlaggable {

    var sectionType: HomepageSectionType {
        return .topSites
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        // Only show a header if the firefox browser logo isn't showing
        let shouldShow = !featureFlags.isFeatureEnabled(.wallpapers, checking: .buildOnly)
        return LabelButtonHeaderViewModel(title: shouldShow ? HomepageSectionType.topSites.title: nil,
                                          titleA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.topSites,
                                          isButtonHidden: true)
    }

    var isEnabled: Bool {
        return featureFlags.isFeatureEnabled(.topSites, checking: .buildAndUser)
    }

    func numberOfItemsInSection(for traitCollection: UITraitCollection) -> Int {
        refreshData(for: traitCollection)

        let interface = TopSitesUIInterface(trait: traitCollection)
        let sectionDimension = dimensionManager.getSectionDimension(for: topSites,
                                                                    numberOfRows: tileManager.numberOfRows,
                                                                    interface: interface)
        let items = sectionDimension.numberOfRows * sectionDimension.numberOfTilesPerRow
        return items
    }

    func section(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.cellEstimatedSize.height)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.cellEstimatedSize.height)
        )

        let interface = TopSitesUIInterface(trait: traitCollection)
        let sectionDimension = dimensionManager.getSectionDimension(for: topSites,
                                                                    numberOfRows: tileManager.numberOfRows,
                                                                    interface: interface)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: sectionDimension.numberOfTilesPerRow)
        let section = NSCollectionLayoutSection(group: group)

        let leadingInset = HomepageViewModel.UX.topSiteLeadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                        leading: leadingInset,
                                                        bottom: HomepageViewModel.UX.spacingBetweenSections - TopSiteItemCell.UX.bottomSpace,
                                                        trailing: 0)

        return section
    }

    var hasData: Bool {
        return tileManager.hasData
    }

    func updateData(completion: @escaping () -> Void) {
        tileManager.loadTopSitesData(dataLoadingCompletion: completion)
    }

    func refreshData(for traitCollection: UITraitCollection) {
        let interface = TopSitesUIInterface(trait: traitCollection)
        let sectionDimension = dimensionManager.getSectionDimension(for: topSites,
                                                                    numberOfRows: tileManager.numberOfRows,
                                                                    interface: interface)
        tileManager.calculateTopSiteData(numberOfTilesPerRow: sectionDimension.numberOfTilesPerRow)
    }
}

// MARK: - FxHomeTopSitesManagerDelegate
extension TopSitesViewModelImplementation: TopSitesManagerDelegate {
    func reloadTopSites() {
        // Laurie - still needed?
        guard shouldShow else { return }
        delegate?.reloadTopSites()
    }
}

// MARK: - FxHomeSectionHandler
extension TopSitesViewModelImplementation: HomepageSectionHandler {

    func configure(_ collectionView: UICollectionView,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(cellType: TopSiteItemCell.self, for: indexPath),
           let contentItem = tileManager.getSite(index: indexPath.row) {
            cell.configure(contentItem, position: indexPath.row)
            sendImpressionTelemetry(contentItem, position: indexPath.row)
            return cell

        } else if let cell = collectionView.dequeueReusableCell(cellType: EmptyTopSiteCell.self, for: indexPath) {
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

        guard let site = tileManager.getSite(index: indexPath.row) else { return }

        tilePressed(site: site, position: indexPath.row)
    }

    func handleLongPress(with collectionView: UICollectionView, indexPath: IndexPath) {
        guard let tileLongPressedHandler = tileLongPressedHandler,
              let site = tileManager.getSiteDetail(index: indexPath.row)
        else { return }

        let sourceView = collectionView.cellForItem(at: indexPath)
        tileLongPressedHandler(site, sourceView)
    }
}
