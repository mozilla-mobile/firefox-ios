// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

open class DefaultSuggestedSites {
    private static let urlMap = [
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

    private static let sites = [
        SuggestedSite(
            url: "https://m.facebook.com/",
            title: .DefaultSuggestedFacebook,
            faviconResource: .bundleAsset(
                name: "facebook",
                forRemoteResource: URL(string: "https://static.xx.fbcdn.net/rsrc.php/v3/yi/r/4Kv5U5b1o3f.png")!
            )
        ),
        SuggestedSite(
            url: "https://m.youtube.com/",
            title: .DefaultSuggestedYouTube,
            faviconResource: .bundleAsset(
                name: "youtube",
                forRemoteResource: URL(string: "https://m.youtube.com/static/apple-touch-icon-180x180-precomposed.png")!
            )
        ),
        SuggestedSite(
            url: "https://www.amazon.com/",
            title: .DefaultSuggestedAmazon,
            // NOTE: Amazon does not host a high quality favicon. We are falling back to the one hosted in our
            // ContileProvider.contileProdResourceEndpoint (https://ads.mozilla.org/v1/tiles).
            faviconResource: .bundleAsset(
                name: "amazon",
                forRemoteResource: URL(string: "https://tiles-cdn.prod.ads.prod.webservices.mozgcp.net/CAP5k4gWqcBGwir7bEEmBWveLMtvldFu-y_kyO3txFA=.9991.jpg")!
            )
        ),
        SuggestedSite(
            url: "https://www.wikipedia.org/",
            title: .DefaultSuggestedWikipedia,
            faviconResource: .bundleAsset(
                name: "wikipedia",
                forRemoteResource: URL(string: "https://www.wikipedia.org/static/apple-touch/wikipedia.png")!
            )
        ),
        SuggestedSite(
            url: "https://x.com/",
            title: .DefaultSuggestedX,
            faviconResource: .bundleAsset(
                name: "x",
                forRemoteResource: URL(string: "https://abs.twimg.com/responsive-web/client-web/icon-ios.77d25eba.png")!
            )
        )
    ]

    public static func defaultSites() -> [Site] {
        let locale = Locale.current
        return sites.map { data -> SuggestedSite in
            if let domainMap = DefaultSuggestedSites.urlMap[data.url], let localizedURL = domainMap[locale.identifier] {
                return SuggestedSite(url: localizedURL,
                                     title: data.title,
                                     faviconResource: data.faviconResource)
            }
            return data
        }
    }
}
