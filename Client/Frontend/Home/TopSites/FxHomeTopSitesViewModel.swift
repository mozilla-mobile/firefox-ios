// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage

protocol FxHomeTopSitesViewModelDelegate: AnyObject {
    func reloadTopSites()
}

struct UITopSitesInterface {
    var isLandscape: Bool
    var isIphone: Bool
    var horizontalSizeClass: UIUserInterfaceSizeClass
}

class FxHomeTopSitesViewModel {

    struct UX {
        static let numberOfItemsPerRowForSizeClassIpad = UXSizeClasses(compact: 3, regular: 4, other: 2)
        // This needs to be removed once we have self sizing sections
        static let parentInterItemSpacing: CGFloat = 12
    }

    struct SectionDimension {
        var numberOfRows: Int
        var numberOfTilesPerRow: Int
    }

    private let profile: Profile
    private let isZeroSearch: Bool

    var sectionDimension: SectionDimension = FxHomeTopSitesViewModel.defaultDimension
    static var defaultDimension = SectionDimension(numberOfRows: 2, numberOfTilesPerRow: 6)

    var tilePressedHandler: ((Site, Bool) -> Void)?
    var tileLongPressedHandler: ((Site, UIView?) -> Void)?
    weak var delegate: FxHomeTopSitesViewModelDelegate?

    lazy var tileManager: FxHomeTopSitesManager = {
        return FxHomeTopSitesManager(profile: profile)
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

    func reloadData(for trait: UITraitCollection) {
        sectionDimension = getSectionDimension(for: trait)
        tileManager.calculateTopSiteData(numberOfTilesPerRow: sectionDimension.numberOfTilesPerRow)
    }

    func tilePressed(site: HomeTopSite, position: Int) {
        topSiteTracking(site: site, position: position)
        tilePressedHandler?(site.site, site.isGoogleURL)
    }

    func topSiteTracking(site: HomeTopSite, position: Int) {
        // Top site extra
        let topSitePositionKey = TelemetryWrapper.EventExtraKey.topSitePosition.rawValue
        let topSiteTileTypeKey = TelemetryWrapper.EventExtraKey.topSiteTileType.rawValue
        let isPinnedAndGoogle = site.isPinned && site.isGoogleGUID
        let type = isPinnedAndGoogle ? "google" : site.isPinned ? "user-added" : site.isSuggested ? "suggested" : "history-based"
        let topSiteExtra = [topSitePositionKey: "\(position)", topSiteTileTypeKey: type]

        // Origin extra
        let originExtra = TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
        let extras = originExtra.merge(with: topSiteExtra)

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .topSiteTile,
                                     value: nil,
                                     extras: extras)
    }

    // MARK: Context actions

    func getTopSitesAction(site: Site) -> [PhotonRowActions]{
        let removeTopSiteAction = SingleActionViewModel(title: .RemoveContextMenuTitle,
                                                        iconString: ImageIdentifiers.actionRemove,
                                                        tapHandler: { _ in
            self.hideURLFromTopSites(site)
        }).items

        let pinTopSite = SingleActionViewModel(title: .AddToShortcutsActionTitle,
                                               iconString: ImageIdentifiers.addShortcut,
                                               tapHandler: { _ in
            self.pinTopSite(site)
        }).items

        let removePinTopSite = SingleActionViewModel(title: .RemoveFromShortcutsActionTitle,
                                                     iconString: ImageIdentifiers.removeFromShortcut,
                                                     tapHandler: { _ in
            self.removePinTopSite(site)
        }).items

        let topSiteActions: [PhotonRowActions]
        if let _ = site as? PinnedSite {
            topSiteActions = [removePinTopSite]
        } else {
            topSiteActions = [pinTopSite, removeTopSiteAction]
        }
        return topSiteActions
    }

    func hideURLFromTopSites(_ site: Site) {
        guard let host = site.tileURL.normalizedHost else { return }

        let url = site.tileURL.absoluteString
        // if the default top sites contains the siteurl. also wipe it from default suggested sites.
        if !TopSitesHelper.defaultTopSites(profile).filter({ $0.url == url }).isEmpty {
            deleteTileForSuggestedSite(url)
        }

        profile.history.removeHostFromTopSites(host).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.tileManager.refreshIfNeeded(forceTopSites: true)
        }
    }

    private func removePinTopSite(_ site: Site) {
        tileManager.removePinTopSite(site: site)
    }

    private func pinTopSite(_ site: Site) {
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

// MARK: FXHomeViewModelProtocol
extension FxHomeTopSitesViewModel: FXHomeViewModelProtocol, FeatureFlagsProtocol {

    var sectionType: FirefoxHomeSectionType {
        return .topSites
    }

    var isEnabled: Bool {
        return featureFlags.isFeatureActiveForNimbus(.topSites)
    }

    var hasData: Bool {
        return tileManager.hasData
    }

    var shouldReloadSection: Bool {
        return true
    }

    func updateData(completion: @escaping () -> Void) {
        tileManager.loadTopSitesData(dataLoadingCompletion: completion)
    }
}

// MARK: FxHomeTopSitesManagerDelegate
extension FxHomeTopSitesViewModel: FxHomeTopSitesManagerDelegate {
    func reloadTopSites() {
        delegate?.reloadTopSites()
    }
}
