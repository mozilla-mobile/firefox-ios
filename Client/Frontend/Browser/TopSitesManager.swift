//
//  TopSitesHandler.swift
//  Client
//
//  Created by Sawyer Blatz on 8/24/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import Foundation
import Shared
import UIKit
import Storage
import SyncTelemetry

struct TopSitesManager {
    // TODO: Look at this getTopSites function
    static func getTopSites(profile: Profile) -> Success {
        let numRows = max(profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows) ?? TopSitesRowCountSettingsController.defaultNumberOfRows, 1)
        let maxItems = UIDevice.current.userInterfaceIdiom == .pad ? 32 : 16
        return profile.history.getTopSitesWithLimit(maxItems).both(profile.history.getPinnedTopSites()).bindQueue(.main) { (topsites, pinnedSites) in
            guard let mySites = topsites.successValue?.asArray(), let pinned = pinnedSites.successValue?.asArray() else {
                return succeed()
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

            self.topSitesManager.currentTraits = self.view.traitCollection
            let maxItems = Int(numRows) * self.topSitesManager.numberOfHorizontalItems()
            if newSites.count > Int(ActivityStreamTopSiteCacheSize) {
                self.topSitesManager.content = Array(newSites[0..<Int(ActivityStreamTopSiteCacheSize)])
            } else {
                self.topSitesManager.content = newSites
            }

            if newSites.count > maxItems {
                self.topSitesManager.content =  Array(newSites[0..<maxItems])
            }

            self.topSitesManager.urlPressedHandler = { [unowned self] url, indexPath in
                self.longPressRecognizer.isEnabled = false
                self.showSiteWithURLHandler(url as URL)
            }

            return succeed()
        }
    }
    
    static func defaultTopSites(_ profile: Profile) -> [Site] {
        let suggested = SuggestedSites.asArray()
        let deleted = profile.prefs.arrayForKey(DefaultSuggestedSitesKey) as? [String] ?? []
        return suggested.filter({deleted.firstIndex(of: $0.url) == .none})
    }
}
