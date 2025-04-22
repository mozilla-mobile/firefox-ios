// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client
import XCTest
import WebKit
import MozillaAppServices

class ASSearchEngineUtilitiesTests: XCTestCase {
    private let google_US_testEngine =
    SearchEngineDefinition(
        aliases: ["google"],
        charset: "UTF-8",
        classification: .general,
        identifier: "google",
        name: "Google",
        optional: false,
        partnerCode: "firefox-b-1-m",
        telemetrySuffix: "b-1-m",
        urls: SearchEngineUrls(
            search: SearchEngineUrl(
                base: "https://www.google.com/search",
                method: "GET",
                params: [
                    SearchUrlParam(
                        name: "client",
                        value: "{partnerCode}",
                        enterpriseValue: nil,
                        experimentConfig: nil
                    ),
                    SearchUrlParam(
                        name: "channel",
                        value: nil,
                        enterpriseValue: nil,
                        experimentConfig: "google_channel_us"
                    ),
                    SearchUrlParam(
                        name: "channel",
                        value: nil,
                        enterpriseValue: "entpr",
                        experimentConfig: "google_channel_us"
                    )
                ],
                searchTermParamName: "q"
            ),
            suggestions: SearchEngineUrl(
                base: "https://www.google.com/complete/search",
                method: "GET",
                params: [SearchUrlParam(
                    name: "client",
                    value: "firefox",
                    enterpriseValue: nil,
                    experimentConfig: nil
                )],
                searchTermParamName: "q"
            ),
            trending: SearchEngineUrl(
                base: "https://www.google.com/complete/search",
                method: "GET",
                params: [SearchUrlParam(
                    name: "client",
                    value: "firefox",
                    enterpriseValue: nil,
                    experimentConfig: nil
                )],
                searchTermParamName: "q"
            ),
            searchForm: nil
        ),
        orderHint: nil,
        clickUrl: nil
    )

    func testConvertGoogleEngineSearchURL() {
        let engine = google_US_testEngine
        let result = ASSearchEngineUtilities.convertASSearchURLToOpenSearchURL(engine.urls.search,
                                                                               for: engine)
        let expected = "https://www.google.com/search?client=firefox-b-1-m&q={searchTerms}"
        XCTAssertEqual(result, expected)
    }

    func testConvertGoogleEngineSuggestURL() {
        let engine = google_US_testEngine
        let result = ASSearchEngineUtilities.convertASSearchURLToOpenSearchURL(engine.urls.suggestions,
                                                                               for: engine)
        let expected = "https://www.google.com/complete/search?client=firefox&q={searchTerms}"
        XCTAssertEqual(result, expected)
    }
}
