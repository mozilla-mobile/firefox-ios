// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import SiteImageView

open class PinnedSite: Site {
    let isPinnedSite = true
    let faviconResource: SiteResource?

    init(site: Site, faviconResource: SiteResource?) {
        self.faviconResource = faviconResource
        super.init(url: site.url, title: site.title, bookmarked: site.bookmarked)
        self.metadata = site.metadata
    }
}
