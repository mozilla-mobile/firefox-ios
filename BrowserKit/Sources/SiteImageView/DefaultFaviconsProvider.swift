// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Provides the favicons registered in the module asset bundle
protocol BundleFaviconProvider {
    func resource(for siteURL: URL) -> SiteResource?
}

struct DefaultBundleFaviconProvider: BundleFaviconProvider {
    struct BundleFavicon {
        let url: URL?
        let resource: SiteResource
    }

    let favicons: [BundleFavicon] = [
        BundleFavicon(
            url: URL(string: "https://www.facebook.com"),
            resource: .bundleAsset(
                name: "facebook-com",
                forRemoteResource: URL(string: "https://static.xx.fbcdn.net/rsrc.php/v3/yi/r/4Kv5U5b1o3f.png")!
            )
        ),
        BundleFavicon(
            url: URL(string: "https://www.youtube.com"),
            resource: .bundleAsset(
                name: "youtube-com",
                forRemoteResource: URL(string: "https://m.youtube.com/static/apple-touch-icon-180x180-precomposed.png")!
            )
        ),
        BundleFavicon(
            url: URL(string: "https://amazon.com"),
            resource: .bundleAsset(
                name: "amazon-com",
                forRemoteResource: URL(string: "https://tiles-cdn.prod.ads.prod.webservices.mozgcp.net/CAP5k4gWqcBGwir7bEEmBWveLMtvldFu-y_kyO3txFA=.9991.jpg")!
            )
        ),
        BundleFavicon(
            url: URL(string: "https://www.wikipedia.org"),
            resource: .bundleAsset(
                name: "wikipedia-org",
                forRemoteResource: URL(string: "https://www.wikipedia.org/static/apple-touch/wikipedia.png")!
            )
        ),
        BundleFavicon(
            url: URL(string: "https://x.com"),
            resource: .bundleAsset(
                name: "x-com",
                forRemoteResource: URL(string: "https://abs.twimg.com/responsive-web/client-web/icon-ios.77d25eba.png")!
            )
        ),
        BundleFavicon(
            url: URL(string: "https://twitter.com"),
            resource: .bundleAsset(
                name: "x-com",
                forRemoteResource: URL(string: "https://abs.twimg.com/responsive-web/client-web/icon-ios.77d25eba.png")!
            )
        ),
        BundleFavicon(
            url: URL(string: "https://google.com"),
            resource: .bundleAsset(
                name: "google-com",
                forRemoteResource: URL(string: "https://www.google.com/images/branding/product_ios/3x/gsa_ios_60dp.png")!)
        )
    ]

    func resource(for siteURL: URL) -> SiteResource? {
        return favicons.first { favicon in
            return favicon.url?.shortDisplayString == siteURL.shortDisplayString
        }?.resource
    }
}
