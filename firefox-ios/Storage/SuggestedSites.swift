// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import SiteImageView

public struct SuggestedSite: SitePr {
    public var id: Int
    public var url: String
    public var title: String
    public var faviconResource: SiteImageView.SiteResource?
    public var metadata: PageMetadata?
    public var latestVisit: Visit?
    public var isBookmarked: Bool?

    let trackingId: Int

    public var tileURL: URL {
        return URL(string: url as String, invalidCharacters: false) ?? URL(string: "about:blank")!
    }

    public init(url: String, title: String, trackingId: Int, faviconResource: SiteImageView.SiteResource? = nil) {
        self.trackingId = trackingId
        self.id = UUID().hashValue
        self.url = url
        self.title = title
        self.faviconResource = faviconResource

        // FIXME Is this needed?
//        self.guid = "default" + title // A guid is required in the case the site might become a pinned site
    }
}
