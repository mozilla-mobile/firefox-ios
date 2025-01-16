// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import SiteImageView

struct SponsoredTile: SitePr { // FIXME rename to end in `Site`?
    public var id: Int
    public var url: String
    public var title: String
    public var faviconResource: SiteImageView.SiteResource? // FIXME if these aren't used, can we move to BasicSite only?
    public var metadata: PageMetadata?
    public var latestVisit: Visit?
    public var isBookmarked: Bool?

    var tileId: Int
    var impressionURL: String
    var clickURL: String
    var imageURL: String

    init(contile: Contile) {
        self.id = UUID().hashValue
        self.url = contile.url
        self.title = contile.name
        self.faviconResource = nil // FIXME Use contile imageURL?

        // Used for telemetry
        self.tileId = contile.id
        self.impressionURL = contile.impressionUrl
        self.clickURL = contile.clickUrl
        self.imageURL = contile.imageUrl

        // FIXME Is this needed?
        // A guid is required in case the site might become a pinned site
//        self.guid = "default" + contile.name
    }
}
