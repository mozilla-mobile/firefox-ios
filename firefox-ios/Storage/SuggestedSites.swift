// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import SiteImageView

open class SuggestedSite: Site {
    override open var tileURL: URL {
        return URL(string: url as String, invalidCharacters: false) ?? URL(string: "about:blank")!
    }
    let trackingId: Int
    public init(url: String,
                title: String,
                trackingId: Int,
                faviconResource: SiteResource? = nil) {
        self.trackingId = trackingId
        super.init(url: url, title: title, bookmarked: nil, faviconResource: faviconResource)
        self.guid = "default" + title // A guid is required in the case the site might become a pinned site
    }
}
