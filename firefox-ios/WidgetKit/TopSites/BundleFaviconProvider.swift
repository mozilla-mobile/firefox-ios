// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SiteImageView

struct BundleFaviconProvider {
    private struct Favicon {
        let title: String
        let resource: SiteResource
    }

    private let bundleDefaultFavicons: [Favicon] = [
        Favicon(
            title: .DefaultSuggestedFacebook,
            resource: .bundleAsset(
                name: "facebook-com",
                forRemoteResource: URL(string: "https://static.xx.fbcdn.net/rsrc.php/v3/yi/r/4Kv5U5b1o3f.png")!
            )
        ),
        Favicon(
            title: .DefaultSuggestedYouTube,
            resource: .bundleAsset(
                name: "youtube-com",
                forRemoteResource: URL(string: "https://m.youtube.com/static/apple-touch-icon-180x180-precomposed.png")!
            )
        ),
        Favicon(
            title: .DefaultSuggestedAmazon,
            resource: .bundleAsset(
                name: "amazon-com",
                forRemoteResource: URL(string: "https://tiles-cdn.prod.ads.prod.webservices.mozgcp.net/CAP5k4gWqcBGwir7bEEmBWveLMtvldFu-y_kyO3txFA=.9991.jpg")!
            )
        ),
        Favicon(
            title: .DefaultSuggestedWikipedia,
            resource: .bundleAsset(
                name: "wikipedia-org",
                forRemoteResource: URL(string: "https://www.wikipedia.org/static/apple-touch/wikipedia.png")!
            )
        ),
        Favicon(
            title: .DefaultSuggestedX,
            resource: .bundleAsset(
                name: "x-com",
                forRemoteResource: URL(string: "https://abs.twimg.com/responsive-web/client-web/icon-ios.77d25eba.png")!
            )
        ),
        Favicon(
            title: "Google",
            resource: .bundleAsset(
                name: "google-com",
                forRemoteResource: URL(string: "https://www.google.com/images/branding/product_ios/3x/gsa_ios_60dp.png")!)
        )
    ]

    func resource(for topSiteTitle: String) -> SiteResource? {
        return bundleDefaultFavicons.first { icon in
            icon.title == topSiteTitle
        }?.resource
    }
}
