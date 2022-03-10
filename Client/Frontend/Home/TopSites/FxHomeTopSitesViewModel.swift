// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage

class FxHomeTopSitesViewModel {

    private struct UX {
        static let numberOfItemsPerRowForSizeClassIpad = UXSizeClasses(compact: 3, regular: 4, other: 2)
    }

    private let profile: Profile
    private let experiments: NimbusApi
    private let isZeroSearch: Bool

    var urlPressedHandler: ((Site, IndexPath) -> Void)?
    var tileManager: FxHomeTopSitesManager

    private lazy var homescreen = experiments.withVariables(featureId: .homescreen, sendExposureEvent: false) {
        Homescreen(variables: $0)
    }

    init(profile: Profile, experiments: NimbusApi, isZeroSearch: Bool) {
        self.profile = profile
        self.experiments = experiments
        self.isZeroSearch = isZeroSearch
        self.tileManager = FxHomeTopSitesManager(profile: profile)
    }

    func numberOfHorizontalItems(for trait: UITraitCollection) -> Int {
        let isLandscape = UIWindow.isLandscape
        if UIDevice.current.userInterfaceIdiom == .phone {
            if isLandscape {
                return 8
            } else {
                return 4
            }
        } else {
            // The number of items in a row is equal to the number of highlights in a row * 2
            var numItems = Int(UX.numberOfItemsPerRowForSizeClassIpad[trait.horizontalSizeClass])
            if UIWindow.isPortrait || (trait.horizontalSizeClass == .compact && isLandscape) {
                numItems = numItems - 1
            }
            return numItems * 2
        }
    }

    // Laurie - position is indexPath
    func longPressedHandler(site: Site, position: Int) {
//        self.longPressRecognizer.isEnabled = false
        guard let url = site.url.asURL else { return }
        let isGoogleTopSiteUrl = url.absoluteString == GoogleTopSiteManager.Constants.usUrl || url.absoluteString == GoogleTopSiteManager.Constants.rowUrl
        self.topSiteTracking(site: site, position: position)

        // Laurie - delegate call
//        self.showSiteWithURLHandler(url as URL, isGoogleTopSite: isGoogleTopSiteUrl)
    }

    func topSiteTracking(site: Site, position: Int) {
        // Top site extra
        let topSitePositionKey = TelemetryWrapper.EventExtraKey.topSitePosition.rawValue
        let topSiteTileTypeKey = TelemetryWrapper.EventExtraKey.topSiteTileType.rawValue
        let isPinnedAndGoogle = site is PinnedSite && site.guid == GoogleTopSiteManager.Constants.googleGUID
        let isPinnedOnly = site is PinnedSite
        let isSuggestedSite = site is SuggestedSite
        let type = isPinnedAndGoogle ? "google" : isPinnedOnly ? "user-added" : isSuggestedSite ? "suggested" : "history-based"
        let topSiteExtra = [topSitePositionKey : "\(position)", topSiteTileTypeKey: type]

        // Origin extra
        let originExtra = TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
        let extras = originExtra.merge(with: topSiteExtra)

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .topSiteTile,
                                     value: nil,
                                     extras: extras)
    }

    var numberOfRows: Int32 {
        let preferredNumberOfRows = profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows)
        return max(preferredNumberOfRows ?? TopSitesRowCountSettingsController.defaultNumberOfRows, 1)
    }

    // MARK: Context actions

    func getTopSitesAction(site: Site) -> [PhotonRowActions]{
        let removeTopSiteAction = SingleActionViewModel(title: .RemoveContextMenuTitle, iconString: "action_remove", tapHandler: { _ in
            self.hideURLFromTopSites(site)
        }).items

        let pinTopSite = SingleActionViewModel(title: .AddToShortcutsActionTitle, iconString: ImageIdentifiers.addShortcut, tapHandler: { _ in
            self.pinTopSite(site)
        }).items

        let removePinTopSite = SingleActionViewModel(title: .RemoveFromShortcutsActionTitle, iconString: ImageIdentifiers.removeFromShortcut, tapHandler: { _ in
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

    private func hideURLFromTopSites(_ site: Site) {
        guard let host = site.tileURL.normalizedHost else { return }

        let url = site.tileURL.absoluteString
        // if the default top sites contains the siteurl. also wipe it from default suggested sites.
        if !defaultTopSites().filter({ $0.url == url }).isEmpty {
            deleteTileForSuggestedSite(url)
        }

        profile.history.removeHostFromTopSites(host).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.tileManager.refreshIfNeeded(forceTopSites: true)
        }
    }

    private func pinTopSite(_ site: Site) {
        profile.history.addPinnedTopSite(site).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.tileManager.refreshIfNeeded(forceTopSites: true)
        }
    }

    func removePinTopSite(_ site: Site) {
        // TODO: Laurie - Handle google case in own manager
        // Special Case: Hide google top site
        if site.guid == GoogleTopSiteManager.Constants.googleGUID {
            let gTopSite = GoogleTopSiteManager(prefs: profile.prefs)
            gTopSite.isHidden = true
        }

        profile.history.removeFromPinnedTopSites(site).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.tileManager.refreshIfNeeded(forceTopSites: true)
        }
    }

    private func deleteTileForSuggestedSite(_ siteURL: String) {
        var deletedSuggestedSites = profile.prefs.arrayForKey(TopSitesHelper.DefaultSuggestedSitesKey) as? [String] ?? []
        deletedSuggestedSites.append(siteURL)
        profile.prefs.setObject(deletedSuggestedSites, forKey: TopSitesHelper.DefaultSuggestedSitesKey)
    }

    private func defaultTopSites() -> [Site] {
        let suggested = SuggestedSites.asArray()
        let deleted = profile.prefs.arrayForKey(TopSitesHelper.DefaultSuggestedSitesKey) as? [String] ?? []
        return suggested.filter({ deleted.firstIndex(of: $0.url) == .none })
    }
}

// MARK: FXHomeViewModelProtocol
extension FxHomeTopSitesViewModel: FXHomeViewModelProtocol, FeatureFlagsProtocol {

    var isComformanceUpdateDataReady: Bool {
        return true
    }

    var sectionType: FirefoxHomeSectionType {
        return .topSites
    }

    var isEnabled: Bool {
        homescreen.sectionsEnabled[.topSites] == true
    }

    var hasData: Bool {
        return !tileManager.content.isEmpty
    }

    func updateData(completion: @escaping () -> Void) {
        tileManager.loadTopSitesData()
    }
}
