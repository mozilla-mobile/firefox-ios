// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage

extension Site {
    /// A helper to instantiate a Site from the Storage target using the Client target `UnifiedTile` type.
    static func createSponsoredSite(fromUnifiedTile unifiedTile: UnifiedTile) -> Site {
        let siteInfo = SponsoredSiteInfo(
            impressionURL: unifiedTile.callbacks.impression,
            clickURL: unifiedTile.callbacks.click,
            imageURL: unifiedTile.imageUrl
        )

        return Site.createSponsoredSite(url: unifiedTile.url, title: unifiedTile.name, siteInfo: siteInfo)
    }
}
