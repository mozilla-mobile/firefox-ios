// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage

extension Site {
    /// A helper to instantiate a Site from the Storage target using the Client target `Contile` type.
    static func createSponsoredSite(fromContile contile: Contile) -> Site {
        let siteInfo = SponsoredSiteInfo(
            tileId: contile.id,
            impressionURL: contile.impressionUrl,
            clickURL: contile.clickUrl,
            imageURL: contile.imageUrl
        )

        return Site.createSponsoredSite(url: contile.url, title: contile.name, siteInfo: siteInfo)
    }
}
