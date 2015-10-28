/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class DefaultSuggestedSites {
    public static let sites = [
        SuggestedSiteData(
            url: "https://www.mozilla.org/about",
            bgColor: "0xce4e41",
            imageUrl: "asset://suggestedsites_mozilla",
            faviconUrl: "asset://fxLogo",
            trackingId: 632,
            title: NSLocalizedString("The Mozilla Project", comment: "Tile title for Mozilla")
        ),
        SuggestedSiteData(
            url: "https://support.mozilla.org/products/ios",
            bgColor: "0xf37c00",
            imageUrl: "asset://suggestedsites_fxsupport",
            faviconUrl: "asset://mozLogo",
            trackingId: 631,
            title: NSLocalizedString("Firefox Help and Support", comment: "Tile title for App Help")
        )
    ]
}


