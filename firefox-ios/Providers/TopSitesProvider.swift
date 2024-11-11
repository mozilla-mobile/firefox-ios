// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import UIKit
import Storage

import enum MozillaAppServices.FrecencyThresholdOption

/// A provider for frecency and pinned top sites, used for the home page and widgets
protocol TopSitesProvider {
    /// Get top sites from frecency and pinned tiles
    func getTopSites(numberOfMaxItems: Int,
                     completion: @escaping ([Site]?) -> Void)

    /// Fetches the default top sites
    func defaultTopSites(_ prefs: Prefs) -> [Site]

    /// Default maximum number of items fetched for frecency
    static var numberOfMaxItems: Int { get }

    /// Default key for suggested sites
    var defaultSuggestedSitesKey: String { get }
}

extension TopSitesProvider {
    func getTopSites(numberOfMaxItems: Int = Self.numberOfMaxItems,
                     completion: @escaping ([Site]?) -> Void) {
        getTopSites(numberOfMaxItems: numberOfMaxItems, completion: completion)
    }

    static var numberOfMaxItems: Int {
        return UIDevice.current.userInterfaceIdiom == .pad ? 32 : 16
    }

    var defaultSuggestedSitesKey: String {
        return "topSites.deletedSuggestedSites"
    }
}

class TopSitesProviderImplementation: TopSitesProvider {
    private let pinnedSiteFetcher: PinnedSites
    private let placesFetcher: RustPlaces
    private let prefs: Prefs

    private var frecencySites = [Site]()
    private var pinnedSites = [Site]()

    init(
        placesFetcher: RustPlaces,
        pinnedSiteFetcher: PinnedSites,
        prefs: Prefs
    ) {
        self.placesFetcher = placesFetcher
        self.pinnedSiteFetcher = pinnedSiteFetcher
        self.prefs = prefs
    }

    func getTopSites(numberOfMaxItems: Int,
                     completion: @escaping ([Site]?) -> Void) {
        let group = DispatchGroup()
        getFrecencySites(group: group, numberOfMaxItems: numberOfMaxItems)
        getPinnedSites(group: group)

        group.notify(queue: .global()) { [weak self] in
            guard let self = self else { return }
            self.calculateTopSites(completion: completion)
        }
    }

    func defaultTopSites(_ prefs: Prefs) -> [Site] {
        let suggested = DefaultSuggestedSites.defaultSites()
        let deleted = prefs.arrayForKey(defaultSuggestedSitesKey) as? [String] ?? []
        return suggested.filter({ deleted.firstIndex(of: $0.url) == .none })
    }
}

// MARK: Private
private extension TopSitesProviderImplementation {
    func getFrecencySites(group: DispatchGroup, numberOfMaxItems: Int) {
        group.enter()
        DispatchQueue.global().async { [weak self] in
            // It's possible that the top sites fetch is the
            // very first use of places, lets make sure that
            // our connection is open
            guard let placesFetcher = self?.placesFetcher else {
                group.leave()
                return
            }
            if !placesFetcher.isOpen {
                _ = placesFetcher.reopenIfClosed()
            }
            placesFetcher.getTopFrecentSiteInfos(limit: numberOfMaxItems, thresholdOption: FrecencyThresholdOption.none)
                .uponQueue(.global()) { [weak self] result in
                    if let sites = result.successValue {
                        self?.frecencySites = sites
                    }

                    group.leave()
                }
        }
    }

    func getPinnedSites(group: DispatchGroup) {
        group.enter()
        pinnedSiteFetcher
            .getPinnedTopSites()
            .uponQueue(.global()) { [weak self] result in
                if let sites = result.successValue?.asArray() {
                    self?.pinnedSites = sites
                }

                group.leave()
            }
    }

    func calculateTopSites(completion: ([Site]?) -> Void) {
        // Filter out frecency history which resulted from sponsored tiles clicks
        let sites = SponsoredContentFilterUtility().filterSponsoredSites(from: frecencySites)

        // How sites are merged together. We compare against the url's base domain.
        // Example m.youtube.com is compared against `youtube.com`
        let unionOnURL = { (site: Site) -> String in
            return URL(string: site.url, invalidCharacters: false)?.normalizedHost ?? ""
        }

        // Fetch the default sites
        let defaultSites = defaultTopSites(prefs)
        // Create PinnedSite objects. Used by the view layer to tell topsites apart
        let pinnedSites: [Site] = pinnedSites.map({ PinnedSite(site: $0, faviconResource: nil) })
        // Merge default topsites with a user's topsites.
        let mergedSites = sites.union(defaultSites, f: unionOnURL)
        // Filter out duplicates in merged sites, but do not remove duplicates within pinned sites
        let duplicateFreeList = pinnedSites.union(mergedSites, f: unionOnURL).filter { $0 as? PinnedSite == nil }
        let allSites = pinnedSites + duplicateFreeList

        // Favour topsites from defaultSites as they have better favicons. But keep PinnedSites
        let newSites = allSites.map { site -> Site in
            if let site = site as? PinnedSite {
                return site
            }
            let domain = URL(string: site.url, invalidCharacters: false)?.shortDisplayString
            return defaultSites.first(where: { $0.title.lowercased() == domain }) ?? site
        }

        completion(newSites)
    }
}
