// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

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
                url: "https://m.facebook.com/",
                faviconResource: .bundleAsset(
                    name: "facebook-com",
                    forRemoteResource: URL(string: "https://static.xx.fbcdn.net/rsrc.php/v3/yi/r/4Kv5U5b1o3f.png")!
                ),
                trackingId: 632,
                title: .DefaultSuggestedFacebook
            ),
            SuggestedSiteData(
                url: "https://m.youtube.com/",
                faviconResource: .bundleAsset(
                    name: "youtube-com",
                    forRemoteResource: URL(string: "https://m.youtube.com/static/apple-touch-icon-180x180-precomposed.png")!
                ),
                trackingId: 631,
                title: .DefaultSuggestedYouTube
            ),
            SuggestedSiteData(
                url: "https://www.amazon.com/",
                // NOTE: Amazon does not host a high quality favicon. We are falling back to the one hosted in our
                // ContileProvider.contileProdResourceEndpoint (https://ads.mozilla.org/v1/tiles).
                faviconResource: .bundleAsset(
                    name: "amazon-com",
                    forRemoteResource: URL(string: "https://tiles-cdn.prod.ads.prod.webservices.mozgcp.net/CAP5k4gWqcBGwir7bEEmBWveLMtvldFu-y_kyO3txFA=.9991.jpg")!
                ),
                trackingId: 630,
                title: .DefaultSuggestedAmazon
            ),
            SuggestedSiteData(
                url: "https://www.wikipedia.org/",
                faviconResource: .bundleAsset(
                    name: "wikipedia-org",
                    forRemoteResource: URL(string: "https://www.wikipedia.org/static/apple-touch/wikipedia.png")!
                ),
                trackingId: 629,
                title: .DefaultSuggestedWikipedia
            ),
            SuggestedSiteData(
                url: "https://x.com/",
                faviconResource: .bundleAsset(
                    name: "x-com",
                    forRemoteResource: URL(string: "https://abs.twimg.com/responsive-web/client-web/icon-ios.77d25eba.png")!
                ),
                trackingId: 628,
                title: "x.com"
            )
        ],
        "zh_CN": [ // FIXME Do we still want this as a special case localization? Android doesn't compile this vers. anymore
            SuggestedSiteData(
                url: "http://mozilla.com.cn",
                // FIXME We need a higher quality favicon link
                faviconResource: .remoteURL(url: URL(string: "http://mozilla.com.cn/favicon.ico")!),
                trackingId: 700,
                title: "火狐社区"
            ),
            SuggestedSiteData(
                url: "https://m.baidu.com/",
                faviconResource: .remoteURL(url: URL(string: "https://psstatic.cdn.bcebos.com/video/wiseindex/aa6eef91f8b5b1a33b454c401_1660835115000.png")!),
                trackingId: 701,
                title: "百度"
            ),
            SuggestedSiteData(
                url: "http://sina.cn",
                faviconResource: .remoteURL(url: URL(string: "https://mjs.sinaimg.cn/wap/online/public/images/addToHome/sina_114x114_v1.png")!),
                trackingId: 702,
                title: "新浪"
            ),
            SuggestedSiteData(
                url: "http://info.3g.qq.com/g/s?aid=index&g_f=23946&g_ut=3",
                faviconResource: .remoteURL(url: URL(string: "https://mat1.gtimg.com/qqcdn/qqindex2021/favicon.ico")!),
                trackingId: 703,
                title: "腾讯"
            ),
            SuggestedSiteData(
                url: "http://m.taobao.com",
                faviconResource: .remoteURL(url: URL(string: "https://gw.alicdn.com/tps/i2/TB1nmqyFFXXXXcQbFXXE5jB3XXX-114-114.png")!),
                trackingId: 704,
                title: "淘宝"
            ),
            SuggestedSiteData(
                url: """
                https://union-click.jd.com/jdc?e=618%7Cpc%7C&p=JF8BAKgJK1olXDYDZBoCUBV\
                IMzZNXhpXVhgcCEEGXVRFXTMWFQtAM1hXWFttFkhAaihBfRN1XE5ZMipYVQ1uYwxAa1cZb\
                QIHUV9bCUkQAF8LGFoRXgcAXVttOEsSMyRmGmsXXAcAXFdaAEwVM28PH10TVAMHVVpbDE8\
                nBG8BKydLFl5fCQ5eCUsSM184GGsSXQ8WUiwcWl8RcV84G1slXTZdEAMAOEkWAmsBK2s
                """,
                // FIXME We need a higher quality favicon link
                faviconResource: .remoteURL(url: URL(string: "https://corporate.jd.com/favicon.ico")!),
                trackingId: 705,
                title: "京东"
            )
        ]
    ]
}
