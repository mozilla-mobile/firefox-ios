// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

open class DefaultSuggestedSites {
    public static let sites = [
        "default": [
            SuggestedSiteData(
                url: Environment.current.urlProvider.financialReports.absoluteString,
                bgColor: "0x000000",
                imageUrl: "asset://suggestedsites_ecosia-org",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 0,
                title: NSLocalizedString("Financial reports", tableName: "Ecosia", comment: "")
            ),
            SuggestedSiteData(
                url: Environment.current.urlProvider.privacy.absoluteString,
                bgColor: "0x000000",
                imageUrl: "asset://suggestedsites_ecosia-org",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 0,
                title: NSLocalizedString("Privacy", tableName: "Ecosia", comment: "")
            ),
            SuggestedSiteData(
                url: Environment.current.urlProvider.blog.absoluteString,
                bgColor: "0x000000",
                imageUrl: "asset://suggestedsites_ecosia-org",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 0,
                title: NSLocalizedString("Trees update", tableName: "Ecosia", comment: "")
            )
        ]
    ]
}
