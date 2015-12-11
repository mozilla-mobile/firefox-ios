/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class DefaultSuggestedSites {
    public static let sites = [
        "default": [
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
        ],
        "zh_CN": [
            SuggestedSiteData(
                url: "https://m.baidu.com/?from=1000969b",
                bgColor: "0x00479d",
                imageUrl: "asset://suggestedsites_baidu",
                faviconUrl: "asset://baiduLogo",
                trackingId: 700,
                title: "百度"
            ),
            SuggestedSiteData(
                url: "http://sina.cn",
                bgColor: "0xe60012",
                imageUrl: "asset://suggestedsites_sina",
                faviconUrl: "asset://sinaLogo",
                trackingId: 701,
                title: "新浪"
            ),
            SuggestedSiteData(
                url: "http://3g.qq.com",
                bgColor: "0x028cca",
                imageUrl: "asset://suggestedsites_qq",
                faviconUrl: "asset://qqLogo",
                trackingId: 702,
                title: "腾讯"
            ),
            SuggestedSiteData(
                url: "http://m.taobao.com",
                bgColor: "0xee5900",
                imageUrl: "asset://suggestedsites_taobao",
                faviconUrl: "asset://taobaoLogo",
                trackingId: 703,
                title: "淘宝"
            ),
            SuggestedSiteData(
                url: "http://m.jd.com/?cu=true&utm_source=c.duomai.com&utm_medium=tuiguang&utm_campaign=t_16282_51222087&utm_term=163a0d0b6b124b7b84e6e936be97a1ad",
                bgColor: "0xc71622",
                imageUrl: "asset://suggestedsites_jd",
                faviconUrl: "asset://jdLogo",
                trackingId: 704,
                title: "京东"
            ),
            SuggestedSiteData(
                url: "http://m.okpush.com/j.html?pk=redirect&adId=7863&planId=1838&webId=6975&channelId=6975&publishId=8545",
                bgColor: "0xea5415",
                imageUrl: "asset://suggestedsites_58City",
                faviconUrl: "asset://58CityLogo",
                trackingId: 705,
                title: "58 同城"
            )
        ]
    ]
}
