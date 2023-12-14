// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

actor ProductAdsCache {
    static let shared = ProductAdsCache()
    private let cache = NSCache<NSString, CachedAds>()

    private init() {}

    func cacheAds(_ ads: [ProductAdsResponse], forKey key: String) {
        let cachedAds = CachedAds(ads)
        cache.setObject(cachedAds, forKey: key as NSString)
    }

    func getCachedAds(forKey key: String) -> [ProductAdsResponse]? {
        cache.object(forKey: key as NSString)?.ads
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}

class CachedAds: NSObject {
    let ads: [ProductAdsResponse]

    init(_ ads: [ProductAdsResponse]) {
        self.ads = ads
    }
}
