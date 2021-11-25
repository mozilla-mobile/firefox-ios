// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

/// Protocol to help get the hero image for the UI
/// The hero image is first retrieved from the cache, and if it's not there we fetch it from the Site
protocol CanGetHeroImage {
    var siteImageHelper: SiteImageHelper { get }
    func getHeroImage(forSite site: Site, completion: @escaping (UIImage?) -> Void)
}

extension CanGetHeroImage {
    func getHeroImage(forSite site: Site, completion: @escaping (UIImage?) -> Void) {
        let heroImageCacheKey = NSString(string: site.url)
        if let cachedImage = SiteImageHelper.cache.object(forKey: heroImageCacheKey) {
            completion(cachedImage)
        } else {
            siteImageHelper.fetchImageFor(site: site, imageType: .heroImage, shouldFallback: true) { image in
                completion(image)
            }
        }
    }
}
