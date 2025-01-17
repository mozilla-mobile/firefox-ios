// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Localizations

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
        "default": [
            Site.createSuggestedSite(
                url: "https://m.facebook.com/",
                title: .DefaultSuggestedFacebook,
                trackingId: 632,
                faviconResource: .bundleAsset(
                    name: "facebook",
                    forRemoteResource: URL(string: "https://static.xx.fbcdn.net/rsrc.php/v3/yi/r/4Kv5U5b1o3f.png")!
                )
            ),
            Site.createSuggestedSite(
                url: "https://m.youtube.com/",
                title: .DefaultSuggestedYouTube,
                trackingId: 631,
                faviconResource: .bundleAsset(
                    name: "youtube",
                    forRemoteResource: URL(string: "https://m.youtube.com/static/apple-touch-icon-180x180-precomposed.png")!
                )
            ),
            Site.createSuggestedSite(
                url: "https://www.amazon.com/",
                title: .DefaultSuggestedAmazon,
                trackingId: 630,
                // NOTE: Amazon does not host a high quality favicon. We are falling back to the one hosted in our
                // ContileProvider.contileProdResourceEndpoint (https://ads.mozilla.org/v1/tiles).
                faviconResource: .bundleAsset(
                    name: "amazon",
                    forRemoteResource: URL(string: "https://tiles-cdn.prod.ads.prod.webservices.mozgcp.net/CAP5k4gWqcBGwir7bEEmBWveLMtvldFu-y_kyO3txFA=.9991.jpg")!
                )
            ),
            Site.createSuggestedSite(
                url: "https://www.wikipedia.org/",
                title: .DefaultSuggestedWikipedia,
                trackingId: 629,
                faviconResource: .bundleAsset(
                    name: "wikipedia",
                    forRemoteResource: URL(string: "https://www.wikipedia.org/static/apple-touch/wikipedia.png")!
                )
            ),
            Site.createSuggestedSite(
                url: "https://x.com/",
                title: .DefaultSuggestedX,
                trackingId: 628,
                faviconResource: .bundleAsset(
                    name: "x",
                    forRemoteResource: URL(string: "https://abs.twimg.com/responsive-web/client-web/icon-ios.77d25eba.png")!
                )
            )
        ],
        "zh_CN": [ // FXIOS-11064 Do we still want this as a special case localization? Android doesn't compile this anymore
            Site.createSuggestedSite(
                url: "http://mozilla.com.cn",
                title: "火狐社区",
                trackingId: 700,
                // FXIOS-11064 We need a higher quality favicon link
                faviconResource: .remoteURL(url: URL(string: "http://mozilla.com.cn/favicon.ico")!)
            ),
            Site.createSuggestedSite(
                url: "https://m.baidu.com/",
                title: "百度",
                trackingId: 701,
                faviconResource: .remoteURL(url: URL(string: "https://psstatic.cdn.bcebos.com/video/wiseindex/aa6eef91f8b5b1a33b454c401_1660835115000.png")!)
            ),
            Site.createSuggestedSite(
                url: "http://sina.cn",
                title: "新浪",
                trackingId: 702,
                faviconResource: .remoteURL(url: URL(string: "https://mjs.sinaimg.cn/wap/online/public/images/addToHome/sina_114x114_v1.png")!)
            ),
            Site.createSuggestedSite(
                url: "http://info.3g.qq.com/g/s?aid=index&g_f=23946&g_ut=3",
                title: "腾讯",
                trackingId: 703,
                faviconResource: .remoteURL(url: URL(string: "https://mat1.gtimg.com/qqcdn/qqindex2021/favicon.ico")!)
            ),
            Site.createSuggestedSite(
                url: "http://m.taobao.com",
                title: "淘宝",
                trackingId: 704,
                faviconResource: .remoteURL(url: URL(string: "https://gw.alicdn.com/tps/i2/TB1nmqyFFXXXXcQbFXXE5jB3XXX-114-114.png")!)
            ),
            Site.createSuggestedSite(
                url: """
                https://union-click.jd.com/jdc?e=618%7Cpc%7C&p=JF8BAKgJK1olXDYDZBoCUBV\
                IMzZNXhpXVhgcCEEGXVRFXTMWFQtAM1hXWFttFkhAaihBfRN1XE5ZMipYVQ1uYwxAa1cZb\
                QIHUV9bCUkQAF8LGFoRXgcAXVttOEsSMyRmGmsXXAcAXFdaAEwVM28PH10TVAMHVVpbDE8\
                nBG8BKydLFl5fCQ5eCUsSM184GGsSXQ8WUiwcWl8RcV84G1slXTZdEAMAOEkWAmsBK2s
                """,
                title: "京东",
                trackingId: 705,
                // FXIOS-11064 We need a higher quality favicon link
                faviconResource: .remoteURL(url: URL(string: "https://corporate.jd.com/favicon.ico")!)
            )
         ]
    ]

    public static func defaultSites() -> [Site] {
        let locale = Locale.current
        let defaultSites = sites[locale.identifier] ?? sites["default"]
        return defaultSites?.map { site in
            // Override default suggested site URLs with a localized URL for domains in `urlMap` (e.g. localized Amazon)
            if let domainMap = DefaultSuggestedSites.urlMap[site.url],
               let localizedURL = domainMap[locale.identifier] {
                return Site.copiedFrom(site: site, withLocalizedURLString: localizedURL)
            }
            return site
        } ?? []
    }
}
