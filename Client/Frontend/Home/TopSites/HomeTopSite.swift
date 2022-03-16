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

    var isPinned: Bool
    var isSuggested: Bool
    var isGoogleGUID: Bool
    var isGoogleURL: Bool

    var imageLoaded: ((UIImage?) -> Void)?
    var identifier = UUID().uuidString

    init(site: Site, profile: Profile) {
        self.site = site
        if let provider = site.metadata?.providerName {
            title = provider.lowercased()
        } else {
            title = site.tileURL.shortDisplayString
        }

        isPinned = ((site as? PinnedSite) != nil)
        isSuggested = ((site as? SuggestedSite) != nil)
        isGoogleGUID = site.guid == GoogleTopSiteManager.Constants.googleGUID
        isGoogleURL = site.url == GoogleTopSiteManager.Constants.usUrl || site.url == GoogleTopSiteManager.Constants.rowUrl

        let imageHelper = SiteImageHelper(profile: profile)
        imageHelper.fetchImageFor(site: site,
                                  imageType: .favicon,
                                  shouldFallback: false) { image in
            self.image = image
            self.imageLoaded?(image)
        }
    }
}
