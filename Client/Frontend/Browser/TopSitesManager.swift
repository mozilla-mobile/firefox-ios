/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import UIKit
import Storage
import SyncTelemetry

struct TopSitesHandler {
    static func getTopSites(profile: Profile) -> Deferred<[Site]> {      
        let maxItems = UIDevice.current.userInterfaceIdiom == .pad ? 32 : 16
        return profile.history.getTopSitesWithLimit(maxItems).both(profile.history.getPinnedTopSites()).bindQueue(.main) { (topsites, pinnedSites) in
            
            let deferred = Deferred<[Site]>()
                        
            guard let mySites = topsites.successValue?.asArray(), let pinned = pinnedSites.successValue?.asArray() else {
                return deferred
            }
            
            // How sites are merged together. We compare against the url's base domain. example m.youtube.com is compared against `youtube.com`
            let unionOnURL = { (site: Site) -> String in
                return URL(string: site.url)?.normalizedHost ?? ""
            }

            // Fetch the default sites
            let defaultSites = defaultTopSites(profile)
            // create PinnedSite objects. used by the view layer to tell topsites apart
            let pinnedSites: [Site] = pinned.map({ PinnedSite(site: $0) })

            // Merge default topsites with a user's topsites.
            let mergedSites = mySites.union(defaultSites, f: unionOnURL)
            // Merge pinnedSites with sites from the previous step
            let allSites = pinnedSites.union(mergedSites, f: unionOnURL)

            // Favour topsites from defaultSites as they have better favicons. But keep PinnedSites
            let newSites = allSites.map { site -> Site in
                if let _ = site as? PinnedSite {
                    return site
                }
                let domain = URL(string: site.url)?.shortDisplayString
                return defaultSites.find { $0.title.lowercased() == domain } ?? site
            }
            
            deferred.fill(newSites)
            
            return deferred
        }
    }
    
    static func defaultTopSites(_ profile: Profile) -> [Site] {
        let suggested = SuggestedSites.asArray()
        let deleted = profile.prefs.arrayForKey(DefaultSuggestedSitesKey) as? [String] ?? []
        return suggested.filter({deleted.firstIndex(of: $0.url) == .none})
    }
    
    static let DefaultSuggestedSitesKey = "topSites.deletedSuggestedSites"
}

open class PinnedSite: Site {
    let isPinnedSite = true

    init(site: Site) {
        super.init(url: site.url, title: site.title, bookmarked: site.bookmarked)
        self.icon = site.icon
        self.metadata = site.metadata
    }
}
