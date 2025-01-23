// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import UIKit
import Storage
import SiteImageView

public protocol GoogleTopSiteManagerProvider {
    var pinnedSiteData: Site? { get }
    func shouldAddGoogleTopSite(hasSpace: Bool) -> Bool
    func removeGoogleTopSite(site: Site)
}
// Manage the specific Google top site case
class GoogleTopSiteManager: GoogleTopSiteManagerProvider {
    struct Constants {
        // US and rest of the world google urls
        static let usUrl = "https://www.google.com/webhp?client=firefox-b-1-m&channel=ts"
        static let rowUrl = "https://www.google.com/webhp?client=firefox-b-m&channel=ts"

        // Google favicon
        private static let faviconUrl = URL(string: "https://www.google.com/images/branding/product_ios/3x/gsa_ios_60dp.png")!
        static let faviconResource: SiteResource = .bundleAsset(name: "google", forRemoteResource: faviconUrl)

        // The number of tiles taken by Google top site manager
        static let reservedSpaceCount = 1
    }

    // No Google Top Site, it should be removed, if it already exists for invalid region
    private let invalidRegion = ["CN", "RU", "TR", "KZ", "BY"]
    private var prefs: Prefs
    private var url: String? {
        // Couldn't find a valid region hence returning a nil value for url
        guard let regionCode = Locale.current.regionCode, !invalidRegion.contains(regionCode) else { return nil }

        // Special case for US
        if regionCode == "US" {
            return Constants.usUrl
        } else {
            return Constants.rowUrl
        }
    }

    var hasAdded: Bool {
        get {
            guard let value = prefs.boolForKey(PrefsKeys.GoogleTopSiteAddedKey) else {
                return false
            }
            return value
        }
        set(value) {
            prefs.setBool(value, forKey: PrefsKeys.GoogleTopSiteAddedKey)
        }
    }

    var isHidden: Bool {
        get {
            guard let value = prefs.boolForKey(PrefsKeys.GoogleTopSiteHideKey) else {
                return false
            }
            return value
        }
        set(value) {
            prefs.setBool(value, forKey: PrefsKeys.GoogleTopSiteHideKey)
        }
    }

    init(prefs: Prefs) {
        self.prefs = prefs
    }

    var pinnedSiteData: Site? {
        guard let url = self.url else { return nil }

        let pinnedSite = Site.createPinnedSite(
            url: url,
            title: "Google",
            isGooglePinnedTile: true,
            faviconResource: Constants.faviconResource
        )

        return pinnedSite
    }

    // Once Google top site is added, we don't remove unless it's explicitly unpinned
    // Add it when pinned websites are less than max pinned sites
    func shouldAddGoogleTopSite(hasSpace: Bool) -> Bool {
        let shouldShow = !isHidden && pinnedSiteData != nil
        return shouldShow && (hasAdded || hasSpace)
    }

    func removeGoogleTopSite(site: Site) {
        guard case SiteType.pinnedSite(let siteInfo) = site.type,
              siteInfo.isGooglePinnedTile else {
            return
        }

        isHidden = true
    }

    func addGoogleTopSite(sites: inout [Site]) {
        guard let googleSite = pinnedSiteData else { return }
        sites.insert(googleSite, at: 0)
        hasAdded = true
    }
}
