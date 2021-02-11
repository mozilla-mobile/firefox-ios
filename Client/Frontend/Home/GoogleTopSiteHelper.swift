/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit
import Storage

class GoogleTopSiteHelper {
    // A guid is required in the case the site might become a pinned site
    public static let googleGUID = "DefaultGoogleGUID"
    // No Google Top Site, we should be removed, if it already exists for invalid region
    private let invalidRegion = ["CN", "RU", "TR", "KZ", "BY"]
    private var prefs: Prefs
    private var url: String? {
        // Couldn't find a valid region hence returning a nil value for url
        guard let regionCode = Locale.current.regionCode, !invalidRegion.contains(regionCode) else {
            return nil
        }
        let usRegionDefaultUrl = "https://www.google.com/webhp?client=firefox-b-1-m&channel=ts"
        let otherRegionDefaultUrl = "https://www.google.com/webhp?client=firefox-b-m&channel=ts"
        // Special case for US
        if regionCode == "US" {
            return usRegionDefaultUrl
        }
        return otherRegionDefaultUrl
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
    
    func suggestedSiteData() -> PinnedSite? {
        guard let url = self.url else {
            return nil
        }
        let pinnedSite = PinnedSite(site: Site(url: url, title: "Google"))
        pinnedSite.guid = GoogleTopSiteHelper.googleGUID
        return pinnedSite
    }
    
    init(prefs: Prefs) {
        self.prefs = prefs
    }
}
