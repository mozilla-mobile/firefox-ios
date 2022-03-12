// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

// Top site UI class, used in the home top site section
class HomeTopSite {
    var site: Site
    var title: String
    var image: UIImage?
    var pinned: Bool
    var imageLoaded: ((UIImage?) -> Void)?

    init(site: Site, profile: Profile) {
        self.site = site
        if let provider = site.metadata?.providerName {
            // TODO: laurie - lowercased?
            title = provider.lowercased()
        } else {
            title = site.tileURL.shortDisplayString
        }

        pinned = ((site as? PinnedSite) != nil)

        let imageHelper = SiteImageHelper(profile: profile)
        imageHelper.fetchImageFor(site: site,
                                  imageType: .favicon,
                                  shouldFallback: false) { image in
            self.image = image
            self.imageLoaded?(image)
        }
    }
}
