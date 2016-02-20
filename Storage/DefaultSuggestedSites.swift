/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class DefaultSuggestedSites {
    public static let sites = [
        "default": [
            SuggestedSiteData(
                url: "https://m.facebook.com/",
                bgColor: "0x385185",
                imageUrl: "asset://suggestedsites_facebook",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 632,
                title: NSLocalizedString("Facebook", comment: "Tile title for Facebook")
            ),
            SuggestedSiteData(
                url: "https://m.youtube.com/",
                bgColor: "0xcd201f",
                imageUrl: "asset://suggestedsites_youtube",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 631,
                title: NSLocalizedString("YouTube", comment: "Tile title for YouTube")
            ),
            SuggestedSiteData(
                url: "https://www.amazon.com/",
                bgColor: "0x000000",
                imageUrl: "asset://suggestedsites_amazon",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 630,
                title: NSLocalizedString("Amazon", comment: "Tile title for Amazon")
            ),
            SuggestedSiteData(
                url: "https://www.wikipedia.org/",
                bgColor: "0x000000",
                imageUrl: "asset://suggestedsites_wikipedia",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 629,
                title: NSLocalizedString("Wikipedia", comment: "Tile title for Wikipedia")
            ),
            SuggestedSiteData(
                url: "https://mobile.twitter.com/",
                bgColor: "0x55acee",
                imageUrl: "asset://suggestedsites_twitter",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 628,
                title: NSLocalizedString("Twitter", comment: "Tile title for Twitter")
            )
        ],
        "zh_CN": [
            SuggestedSiteData(
                url: "http://mozilla.com.cn",
                bgColor: "0xbc3326",
                imageUrl: "asset://suggestedsites_mozchina",
                faviconUrl: "asset://mozChinaLogo",
                trackingId: 700,
                title: "火狐社区"
            ),
            SuggestedSiteData(
                url: "https://m.baidu.com/?from=1000969b",
                bgColor: "0x00479d",
                imageUrl: "asset://suggestedsites_baidu",
                faviconUrl: "asset://baiduLogo",
                trackingId: 701,
                title: "百度"
            ),
            SuggestedSiteData(
                url: "http://sina.cn",
                bgColor: "0xe60012",
                imageUrl: "asset://suggestedsites_sina",
                faviconUrl: "asset://sinaLogo",
                trackingId: 702,
                title: "新浪"
            ),
            SuggestedSiteData(
                url: "http://info.3g.qq.com/g/s?aid=index&g_f=23946&g_ut=3",
                bgColor: "0x028cca",
                imageUrl: "asset://suggestedsites_qq",
                faviconUrl: "asset://qqLogo",
                trackingId: 703,
                title: "腾讯"
            ),
            SuggestedSiteData(
                url: "http://m.taobao.com",
                bgColor: "0xee5900",
                imageUrl: "asset://suggestedsites_taobao",
                faviconUrl: "asset://taobaoLogo",
                trackingId: 704,
                title: "淘宝"
            ),
            SuggestedSiteData(
                url: "http://m.jd.com/?cu=true&utm_source=c.duomai.com&utm_medium=tuiguang&utm_campaign=t_16282_51222087&utm_term=163a0d0b6b124b7b84e6e936be97a1ad",
                bgColor: "0xc71622",
                imageUrl: "asset://suggestedsites_jd",
                faviconUrl: "asset://jdLogo",
                trackingId: 705,
                title: "京东"
            )
        ]
    ]
}
