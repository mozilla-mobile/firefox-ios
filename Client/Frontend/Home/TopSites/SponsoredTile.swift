// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

final class SponsoredTile: Site {

    init(contile: Contile) {
        super.init(url: contile.url, title: contile.name, bookmarked: nil)
        // A guid is required in case the site might become a pinned site
        self.guid = "default" + contile.name

        icon = Favicon(url: contile.imageUrl)
    }
}
