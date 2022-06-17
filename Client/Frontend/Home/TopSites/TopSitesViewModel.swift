// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage

protocol TopSitesViewModelDelegate: AnyObject {
    func reloadTopSites()
}

struct UITopSitesInterface {
    var isLandscape: Bool
    var isIphone: Bool
    var horizontalSizeClass: UIUserInterfaceSizeClass
}

class TopSitesViewModel {
    
    struct UX {
        static let numberOfItemsPerRowForSizeClassIpad = UXSizeClasses(compact: 3, regular: 4, other: 2)
        static let cellEstimatedSize: CGSize = CGSize(width: 100, height: 120)
    }
    
    struct SectionDimension {
        var numberOfRows: Int
        var numberOfTilesPerRow: Int
    }
    
    private let profile: Profile
    private let isZeroSearch: Bool
    private var sentImpressionTelemetry = [String: Bool]()
    
    var sectionDimension: SectionDimension = TopSitesViewModel.defaultDimension
    static var defaultDimension = SectionDimension(numberOfRows: 2, numberOfTilesPerRow: 6)
    
    var tilePressedHandler: ((Site, Bool) -> Void)?
    var tileLongPressedHandler: ((Site, UIView?) -> Void)?
    weak var delegate: TopSitesViewModelDelegate?
    
    lazy var tileManager: TopSitesManager = {
        return TopSitesManager(profile: profile)
    }()
    
    init(profile: Profile, isZeroSearch: Bool) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch
        tileManager.delegate = self
    }
    
    func getSectionDimension(for trait: UITraitCollection,
                             isLandscape: Bool = UIWindow.isLandscape,
                             isIphone: Bool = UIDevice.current.userInterfaceIdiom == .phone
    ) -> SectionDimension {
        let topSitesInterface = UITopSitesInterface(isLandscape: isLandscape,
                                                    isIphone: isIphone,
                                                    horizontalSizeClass: trait.horizontalSizeClass)
        
        let numberOfTilesPerRow = getNumberOfTilesPerRow(for: topSitesInterface)
        let numberOfRows = getNumberOfRows(numberOfTilesPerRow: numberOfTilesPerRow)
        return SectionDimension(numberOfRows: numberOfRows, numberOfTilesPerRow: numberOfTilesPerRow)
    }
    
    // The width dimension of a cell
    static func widthDimension(for numberOfHorizontalItems: Int) -> NSCollectionLayoutDimension {
        return .fractionalWidth(CGFloat(1 / numberOfHorizontalItems))
    }
    
    // Adjust number of rows depending on the what the users want, and how many sites we actually have.
    // We hide rows that are only composed of empty cells
    /// - Parameter numberOfTilesPerRow: The number of tiles per row the user will see
    /// - Returns: The number of rows the user will see on screen
    private func getNumberOfRows(numberOfTilesPerRow: Int) -> Int {
        let totalCellCount = numberOfTilesPerRow * tileManager.numberOfRows
        let emptyCellCount = totalCellCount - tileManager.siteCount
        
        // If there's no empty cell, no clean up is necessary
        guard emptyCellCount > 0 else { return tileManager.numberOfRows }
        
        let numberOfEmptyCellRows = Double(emptyCellCount / numberOfTilesPerRow)
        return tileManager.numberOfRows - Int(numberOfEmptyCellRows.rounded(.down))
    }
    
    /// Get the number of tiles per row the user will see. This depends on the UI interface the user has.
    /// - Parameter interface: Tile number is based on layout, this param contains the parameters needed to computer the tile number
    /// - Returns: The number of tiles per row the user will see
    private func getNumberOfTilesPerRow(for interface: UITopSitesInterface) -> Int {
        if interface.isIphone {
            return interface.isLandscape ? 8 : 4
            
        } else {
            // The number of items in a row is equal to the number of top sites in a row * 2
            var numItems = Int(UX.numberOfItemsPerRowForSizeClassIpad[interface.horizontalSizeClass])
            if !interface.isLandscape || (interface.horizontalSizeClass == .compact && interface.isLandscape) {
                numItems = numItems - 1
            }
            return numItems * 2
        }
    }
    
    func tilePressed(site: TopSite, position: Int) {
        topSitePressTracking(homeTopSite: site, position: position)
        tilePressedHandler?(site.site, site.isGoogleURL)
    }
    
    // MARK: - Telemetry
    
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
    
    func topSiteImpressionTelemetry(_ homeTopSite: TopSite, position: Int) {
        guard !hasSentImpressionForTile(homeTopSite) else { return }
        homeTopSite.impressionTracking(position: position)
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
        
        let url = site.tileURL.absoluteString
        // if the default top sites contains the siteurl. also wipe it from default suggested sites.
        if !TopSitesHelper.defaultTopSites(profile).filter({ $0.url == url }).isEmpty {
            deleteTileForSuggestedSite(url)
        }
        
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
    
    private func deleteTileForSuggestedSite(_ siteURL: String) {
        var deletedSuggestedSites = profile.prefs.arrayForKey(TopSitesHelper.DefaultSuggestedSitesKey) as? [String] ?? []
        deletedSuggestedSites.append(siteURL)
        profile.prefs.setObject(deletedSuggestedSites, forKey: TopSitesHelper.DefaultSuggestedSitesKey)
    }
}

// MARK: HomeViewModelProtocol
extension TopSitesViewModel: HomepageViewModelProtocol, FeatureFlaggable {
    
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
        
        let sectionDimension = getSectionDimension(for: traitCollection)
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
        
        let sectionDimension = getSectionDimension(for: traitCollection)
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
        sectionDimension = getSectionDimension(for: traitCollection)
        tileManager.calculateTopSiteData(numberOfTilesPerRow: sectionDimension.numberOfTilesPerRow)
    }
}

// MARK: - FxHomeTopSitesManagerDelegate
extension TopSitesViewModel: TopSitesManagerDelegate {
    func reloadTopSites() {
        delegate?.reloadTopSites()
    }
}

// MARK: - FxHomeSectionHandler
extension TopSitesViewModel: HomepageSectionHandler {
    
    func configure(_ collectionView: UICollectionView,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(cellType: TopSiteItemCell.self, for: indexPath),
           let contentItem = tileManager.getSite(index: indexPath.row) {
            cell.configure(contentItem, position: indexPath.row)
            topSiteImpressionTelemetry(contentItem, position: indexPath.row)
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
