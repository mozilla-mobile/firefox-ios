// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

/// Protocol to help get the hero image for the UI
/// The hero image is first retrieved from the cache, and if it's not there we fetch it from the Site
protocol CanSetHeroImage {
    var siteImageHelper: SiteImageHelper { get }
    func setHeroImage(_ heroImage: UIImageView, site: Site)
}

extension CanSetHeroImage {
    func setHeroImage(_ heroImage: UIImageView, site: Site) {
        let heroImageCacheKey = NSString(string: site.url)
        if let cachedImage = SiteImageHelper.cache.object(forKey: heroImageCacheKey) {
            heroImage.image = cachedImage
        } else {
            siteImageHelper.fetchImageFor(site: site, imageType: .heroImage, shouldFallback: true) { image in
                heroImage.image = image
            }
        }
    }
}
