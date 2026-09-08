// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Storage

extension Site {
    static func createSponsoredSite(from tile: MozAdsTile) -> Site {
        let siteInfo = SponsoredSiteInfo(
            impressionURL: tile.callbacks.impression,
            clickURL: tile.callbacks.click,
            imageURL: tile.imageUrl
        )
        return Site.createSponsoredSite(url: tile.url, title: tile.name, siteInfo: siteInfo)
    }
}
