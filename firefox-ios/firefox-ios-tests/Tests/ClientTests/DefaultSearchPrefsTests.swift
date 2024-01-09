// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client
import UIKit

import XCTest

class DefaultSearchPrefsTests: XCTestCase {
    func testParsing_hasAllInfo_succeeds() {
        // setup the list json
        let searchPrefs = DefaultSearchPrefs(
            with: Bundle.main.resourceURL!.appendingPathComponent("SearchPlugins").appendingPathComponent("list.json")
        )!

        // setup the most popular locales
        let usa = (
            lang: ["en-US", "en"],
            region: "US",
            resultList: ["google-b-1-m", "amazondotcom", "bing", "ddg", "ebay", "wikipedia"],
            resultDefault: "Google"
        )
        let england = (
            lang: ["en-GB", "en"],
            region: "GB",
            resultList: ["google-b-m", "amazon-co-uk", "bing", "ddg", "ebay-co-uk", "qwant", "wikipedia"],
            resultDefault: "Google"
        )
        let france = (
            lang: ["fr-FR", "fr"],
            region: "FR",
            resultList: ["google-b-m", "bing", "ddg", "ebay-fr", "qwant", "wikipedia-fr"],
            resultDefault: "Google"
        )
        let japan = (
            lang: ["ja-JP", "ja"],
            region: "JP",
            resultList: ["google-b-m", "amazon-jp", "bing", "ebay", "wikipedia-ja", "yahoo-jp"],
            resultDefault: "Google"
        )
        let canada = (
            lang: ["en-CA", "en"],
            region: "CA",
            resultList: ["google-b-m", "amazondotcom", "bing", "ddg", "ebay", "wikipedia"],
            resultDefault: "Google"
        )
        let russia = (
            lang: ["ru-RU", "ru"],
            region: "RU",
            resultList: ["google-com-nocodes", "ebay", "wikipedia-ru"],
            resultDefault: "Google"
        )
        let taiwan = (
            lang: ["zh-TW", "zh"],
            region: "TW",
            resultList: ["google-b-m", "bing", "ddg", "wikipedia-zh-TW"],
            resultDefault: "Google"
        )
        let china = (
            lang: ["zh-hans-CN", "zh-CN", "zh"],
            region: "CN",
            resultList: ["google-b-m", "baidu", "bing", "wikipedia-zh-CN"],
            resultDefault: "百度"
        )
        let germany = (
            lang: ["de-DE", "de"],
            region: "DE",
            resultList: ["google-b-m", "amazon-de", "bing", "ddg", "ebay-de", "ecosia", "qwant", "wikipedia-de"],
            resultDefault: "Google"
        )
        let southAfrica = (
            lang: ["en-SA", "en"],
            region: "SA",
            resultList: ["google-b-m", "amazondotcom", "bing", "ddg", "ebay", "wikipedia"],
            resultDefault: "Google"
        )
        let testLocales = [
            usa,
            england,
            france,
            japan,
            canada,
            russia,
            taiwan,
            china,
            germany,
            southAfrica
        ]

        // run tests
        testLocales.forEach { locale in
            XCTAssertEqual(searchPrefs.searchDefault(for: locale.lang, and: locale.region), locale.resultDefault, "incorrect search defaults for \(locale.lang) and \(locale.region)")
            XCTAssertEqual(searchPrefs.visibleDefaultEngines(for: locale.lang, and: locale.region), locale.resultList, "incorrect visible defaults for \(locale.lang) and \(locale.region)")
        }
    }

    func testParsing_hasNoLocalesAndNoRegionOverrides_usesDefault() {
        // setup the defaultOnlyTestList json
        let testBundle = Bundle(for: type(of: self))
        guard let filePath = testBundle.path(
            forResource: "defaultOnlyTestList",
            ofType: "json"
        ) else { fatalError("Couldn't find test file") }
        let searchPrefs = DefaultSearchPrefs(with: URL(fileURLWithPath: filePath))!

        // setup locale
        let us = (
            lang: ["en-US", "en"],
            region: "US",
            resultList: ["google-b-1-m", "amazondotcom", "bing", "ddg", "ebay", "wikipedia"],
            resultDefault: "google-b-m"
        )

        // run tests
        let expectedResult = "fakeDefault"
        XCTAssertEqual(
            searchPrefs.searchDefault(
                for: us.lang,
                and: us.region
            ),
            expectedResult,
            "incorrect for \(us.lang) and \(us.region)"
        )
        XCTAssertEqual(searchPrefs.visibleDefaultEngines(for: us.lang, and: us.region), [expectedResult])
    }
}
