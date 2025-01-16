// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import SiteImageView

public struct PinnedSite: SitePr {
    public var id: Int
    public var url: String
    public var title: String
    public var faviconResource: SiteImageView.SiteResource? // FIXME if these aren't used, can we move to BasicSite only?
    public var metadata: PageMetadata?
    public var latestVisit: Visit?
    public var isBookmarked: Bool?

    //    public let isPinnedSite = true
    /// Is the default Google Pinned tile (e.g. `GoogleTopSiteManager.Constants.googleGUID`)
    public let isGoogleTile: Bool

    init(site: BasicSite, isGoogleTile: Bool, faviconResource: SiteResource?) {
        self.id = UUID().hashValue
        self.url = site.url
        self.title = site.title
        self.faviconResource = faviconResource
        self.metadata = site.metadata
        self.isGoogleTile = isGoogleTile
    }
}
