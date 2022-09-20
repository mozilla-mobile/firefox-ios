// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Core

open class DefaultSuggestedSites {
    public static let urlMap = [
        "https://www.amazon.com/": [
            "as": "https://www.amazon.in",
            "cy": "https://www.amazon.co.uk",
            "da": "https://www.amazon.co.uk",
            "de": "https://www.amazon.de",
            "dsb": "https://www.amazon.de",
            "en_GB": "https://www.amazon.co.uk",
            "et": "https://www.amazon.co.uk",
            "ff": "https://www.amazon.fr",
            "ga_IE": "https://www.amazon.co.uk",
            "gu_IN": "https://www.amazon.in",
            "hi_IN": "https://www.amazon.in",
            "hr": "https://www.amazon.co.uk",
            "hsb": "https://www.amazon.de",
            "ja": "https://www.amazon.co.jp",
            "kn": "https://www.amazon.in",
            "mr": "https://www.amazon.in",
            "or": "https://www.amazon.in",
            "sq": "https://www.amazon.co.uk",
            "ta": "https://www.amazon.in",
            "te": "https://www.amazon.in",
            "ur": "https://www.amazon.in",
            "en_CA": "https://www.amazon.ca",
            "fr_CA": "https://www.amazon.ca"
        ]
    ]

    public static let sites = [
        "default": [
            SuggestedSiteData(
                url: Environment.current.financialReports.absoluteString,
                bgColor: "0x000000",
                imageUrl: "asset://suggestedsites_ecosia-org",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 0,
                title: NSLocalizedString("Financial reports", tableName: "Ecosia", comment: "")
            ),
            SuggestedSiteData(
                url: Environment.current.shop.absoluteString,
                bgColor: "0x000000",
                imageUrl: "asset://suggestedsites_ecosia-org",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 0,
                title: NSLocalizedString("Ecosia shop", tableName: "Ecosia", comment: "")
            ),
            SuggestedSiteData(
                url: Environment.current.privacy.absoluteString,
                bgColor: "0x000000",
                imageUrl: "asset://suggestedsites_ecosia-org",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 0,
                title: NSLocalizedString("Privacy", tableName: "Ecosia", comment: "")
            ),
            SuggestedSiteData(
                url: Environment.current.blog.absoluteString,
                bgColor: "0x000000",
                imageUrl: "asset://suggestedsites_ecosia-org",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 0,
                title: NSLocalizedString("Trees update", tableName: "Ecosia", comment: "")
            )
        ]
    ]
}
