// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import SiteImageView

open class SuggestedSite: Site {
    public init(url: String,
                title: String,
                faviconResource: SiteResource? = nil) {
        super.init(url: url, title: title, bookmarked: nil, faviconResource: faviconResource)
        self.guid = "default" + title // A guid is required in the case the site might become a pinned site
    }
}
