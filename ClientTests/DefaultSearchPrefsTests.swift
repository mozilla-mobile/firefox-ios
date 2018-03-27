/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
@testable import Client
import UIKit

import XCTest

class DefaultSearchPrefsTests: XCTestCase {

    func testParsing() {
        // setup the list json
        let searchPrefs = DefaultSearchPrefs(with: Bundle.main.resourceURL!.appendingPathComponent("SearchPlugins").appendingPathComponent("list.json"))!

        // setup the most popular locales
        let us = (lang: ["en-US", "en"], region: "US", resultList: ["google-2018", "bing", "amazondotcom", "ddg", "twitter", "wikipedia"], resultDefault: "Google")
        let england = (lang: ["en-GB", "en"], region: "GB", resultList: ["google", "bing", "amazon-co-uk", "ddg", "qwant", "twitter", "wikipedia"], resultDefault: "Google")
        let france = (lang: ["fr-FR", "fr"], region: "FR", resultList: ["google", "bing", "ddg", "qwant", "twitter", "wikipedia-fr"], resultDefault: "Google")
        let japan = (lang: ["ja-JP", "ja"], region: "JP", resultList: ["google", "amazon-jp", "bing", "twitter-ja", "wikipedia-ja", "yahoo-jp"], resultDefault: "Google")
        let canada = (lang: ["en-CA", "en"], region: "CA", resultList: ["google", "bing", "amazondotcom", "ddg", "twitter", "wikipedia"], resultDefault: "Google")
        let russia = (lang: ["ru-RU", "ru"], region: "RU", resultList: ["google-nocodes", "yandex-ru", "twitter", "wikipedia-ru"], resultDefault: "Яндекс")
        let taiwan = (lang: ["zh-TW", "zh"], region: "TW", resultList: ["google", "bing", "ddg", "wikipedia-zh-TW"], resultDefault: "Google")
        let china = (lang: ["zh-hans-CN", "zh-CN", "zh"], region: "CN", resultList: ["google-nocodes", "baidu", "bing", "taobao", "wikipedia-zh-CN"], resultDefault: "百度")
        let germany = (lang: ["de-DE", "de"], region: "DE", resultList: ["google", "bing", "amazon-de", "ddg", "qwant", "twitter", "wikipedia-de"], resultDefault: "Google")
        let southAfrica = (lang: ["en-SA", "en"], region: "SA", resultList: ["google", "bing", "amazondotcom", "ddg", "twitter", "wikipedia"], resultDefault: "Google")
        let testLocales = [us, england, france, japan, canada, russia, taiwan, china, germany, southAfrica]

        // run tests
        testLocales.forEach { locale in
            XCTAssertEqual(searchPrefs.searchDefault(for: locale.lang, and: locale.region), locale.resultDefault)
            XCTAssertEqual(searchPrefs.visibleDefaultEngines(for: locale.lang, and: locale.region), locale.resultList)
        }
    }
}
