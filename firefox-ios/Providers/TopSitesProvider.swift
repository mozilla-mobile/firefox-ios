// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import UIKit
import Storage

import enum MozillaAppServices.FrecencyThresholdOption

/// A provider for frecency and pinned top sites, used for the home page and widgets
protocol TopSitesProvider: Sendable {
    /// Get top sites from frecency and pinned tiles
    func getTopSites(numberOfMaxItems: Int,
                     completion: @escaping @Sendable ([Site]?) -> Void)

    /// Fetches the default top sites
    func defaultTopSites(_ prefs: Prefs) -> [Site]

    /// Default maximum number of items fetched for frecency
    static var numberOfMaxItems: Int { get }

    /// Default key for suggested sites
    var defaultSuggestedSitesKey: String { get }
}

extension TopSitesProvider {
    static var numberOfMaxItems: Int {
        return UIDeviceDetails.userInterfaceIdiom == .pad ? 32 : 16
    }

    func getTopSites(numberOfMaxItems: Int = Self.numberOfMaxItems,
                     completion: @escaping @Sendable ([Site]?) -> Void) {
        getTopSites(numberOfMaxItems: numberOfMaxItems, completion: completion)
    }
}

final class TopSitesProviderImplementation: TopSitesProvider, FeatureFlaggable {
    private let pinnedSiteFetcher: PinnedSites
    private let placesFetcher: RustPlaces
    private let prefs: Prefs

    @MainActor
    private var frecencySites = [Site]()

    @MainActor
    private var pinnedSites = [Site]()

    var defaultSuggestedSitesKey: String {
        return "topSites.suggestedSites"
    }

    private var shouldExcludeFirefoxJpGuide: Bool {
        let isFirefoxJpGuideDefaultSiteEnabled = featureFlags.isFeatureEnabled(.firefoxJpGuideDefaultSite,
                                                                               checking: .buildOnly)
        let locale = Locale.current
        return locale.identifier == "ja_JP" && !isFirefoxJpGuideDefaultSiteEnabled
    }

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
                     completion: @escaping @Sendable ([Site]?) -> Void) {
        let group = DispatchGroup()
        getFrecencySites(group: group, numberOfMaxItems: numberOfMaxItems)
        getPinnedSites(group: group)

        group.notify(queue: .main) {
            MainActor.assumeIsolated { [weak self] in
                self?.calculateTopSites(completion: completion)
            }
        }
    }

    func defaultTopSites(_ prefs: Prefs) -> [Site] {
        var suggested = DefaultSuggestedSites.defaultSites()

        if shouldExcludeFirefoxJpGuide {
            // Remove the Firefox Japanese Guide from the list of default sites
            suggested.removeAll {
                $0.url == DefaultSuggestedSites.firefoxJpGuideURL
            }
        }

        let deleted = prefs.arrayForKey(defaultSuggestedSitesKey) as? [String] ?? []
        return suggested.filter({ deleted.firstIndex(of: $0.url) == .none })
    }

    private func getFrecencySites(group: DispatchGroup, numberOfMaxItems: Int) {
        group.enter()
        let placesFetcher = self.placesFetcher
        DispatchQueue.global().async {
            // It's possible that the top sites fetch is the
            // very first use of places, lets make sure that
            // our connection is open
            if !placesFetcher.isOpen {
                _ = placesFetcher.reopenIfClosed()
            }

            placesFetcher.getTopFrecentSiteInfos(limit: numberOfMaxItems,
                                                 thresholdOption: FrecencyThresholdOption.none)
                .uponQueue(.main) { [weak self] result in
                    MainActor.assumeIsolated {
                        if let sites = result.successValue {
                            self?.frecencySites = sites
                        }

                        group.leave()
                    }
                }
        }
    }

    private func getPinnedSites(group: DispatchGroup) {
        group.enter()
        pinnedSiteFetcher
            .getPinnedTopSites()
            .uponQueue(.main) { [weak self] result in
                MainActor.assumeIsolated {
                    if let sites = result.successValue?.asArray() {
                        self?.pinnedSites = sites
                    }

                    group.leave()
                }
            }
    }

    @MainActor
    func calculateTopSites(completion: ([Site]?) -> Void) {
        // Filter out frecency history which resulted from sponsored tiles clicks
        let sites = SponsoredContentFilterUtility().filterSponsoredSites(from: frecencySites)

        // How sites are merged together. We compare against the url's base domain.
        // Example m.youtube.com is compared against `youtube.com`
        let unionOnURL = { (site: Site) -> String in
            return URL(string: site.url)?.normalizedHost ?? ""
        }

        // Fetch the default sites
        let defaultSites = defaultTopSites(prefs)
        // Create PinnedSite objects. Used by the view layer to tell top sites apart
        let pinnedSites: [Site] = pinnedSites.map({ Site.createPinnedSite(fromSite: $0) })
        // Merge default top sites with a user's top sites.
        let mergedSites = sites.union(defaultSites, f: unionOnURL)
        // Filter out duplicates in merged sites, but do not remove duplicates within pinned sites
        let duplicateFreeList = pinnedSites.union(mergedSites, f: unionOnURL).filter { !$0.isPinnedSite }
        let allSites = pinnedSites + duplicateFreeList

        // Favour top sites from defaultSites as they have better favicons. But keep PinnedSites
        let newSites = allSites.map { site -> Site in
            if case SiteType.pinnedSite = site.type {
                return site
            }
            let domain = URL(string: site.url)?.shortDisplayString
            return defaultSites.first(where: { $0.title.lowercased() == domain }) ?? site
        }

        completion(newSites)
    }
}
