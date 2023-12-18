// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

actor ProductAdsCache {
    static let shared = ProductAdsCache()
    private let cache = NSCache<NSString, CachedAds>()
    private var prefs: Prefs

    private init(
        profile: Profile = AppContainer.shared.resolve()
    ) {
        prefs = profile.prefs
    }

    func cacheAds(_ ads: [ProductAdsResponse], forKey key: String) {
        let cachedAds = CachedAds(ads)
        cache.setObject(cachedAds, forKey: key as NSString)
    }

    func getCachedAds(forKey key: String) -> [ProductAdsResponse]? {
        guard let cachedAds = cache.object(forKey: key as NSString)?.ads else { return nil }
        prefs.setBool(true, forKey: PrefsKeys.Shopping2023AdsCached)
        return cachedAds
    }

    func clearCache() {
        cache.removeAllObjects()
        prefs.setBool(false, forKey: PrefsKeys.Shopping2023AdsCached)
        prefs.setBool(false, forKey: PrefsKeys.Shopping2023AdsSeen)
    }
}

class CachedAds: NSObject {
    let ads: [ProductAdsResponse]

    init(_ ads: [ProductAdsResponse]) {
        self.ads = ads
    }
}
