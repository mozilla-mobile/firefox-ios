// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client
import XCTest
import WebKit
import MozillaAppServices

class ASSearchEngineUtilitiesTests: XCTestCase {
    private let leo_eng_deu_engine_no_search_params =
    SearchEngineDefinition(
        aliases: [],
        charset: "UTF-8",
        classification: .unknown,
        identifier: "leo_ende_de",
        isNewUntil: nil,
        name: "LEO Eng-Deu",
        optional: false,
        partnerCode: "",
        telemetrySuffix: "",
        urls: SearchEngineUrls(
            search: SearchEngineUrl(
                base: "https://dict.leo.org/englisch-deutsch/{searchTerms}",
                method: "GET",
                params: [],
                searchTermParamName: nil,
                displayName: nil
            ),
            suggestions: nil,
            trending: nil,
            searchForm: nil,
            visualSearch: nil
        ),
        orderHint: nil,
        clickUrl: nil
    )
    private let leo_eng_deu_engine =
    SearchEngineDefinition(
        aliases: [],
        charset: "UTF-8",
        classification: .unknown,
        identifier: "leo_ende_de",
        isNewUntil: nil,
        name: "LEO Eng-Deu",
        optional: false,
        partnerCode: "",
        telemetrySuffix: "",
        urls: SearchEngineUrls(
            search: SearchEngineUrl(
                base: "https://dict.leo.org/englisch-deutsch/{searchTerms}",
                method: "GET",
                params: [SearchUrlParam(
                    name: "foo",
                    value: "bar",
                    enterpriseValue: nil,
                    experimentConfig: nil
                )],
                searchTermParamName: nil,
                displayName: nil
            ),
            suggestions: nil,
            trending: nil,
            searchForm: nil,
            visualSearch: nil
        ),
        orderHint: nil,
        clickUrl: nil
    )
    private let google_US_testEngine =
    SearchEngineDefinition(
        aliases: ["google"],
        charset: "UTF-8",
        classification: .general,
        identifier: "google",
        isNewUntil: nil,
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
                searchTermParamName: "q",
                displayName: nil
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
                searchTermParamName: "q",
                displayName: nil
            ),
            trending: SearchEngineUrl(
                base: "https://www.google.com/complete/search",
                method: "GET",
                params: [
                    SearchUrlParam(
                        name: "client",
                        value: "firefox",
                        enterpriseValue: nil,
                        experimentConfig: nil
                    ),
                    SearchUrlParam(
                        name: "channel",
                        value: "ftr",
                        enterpriseValue: nil,
                        experimentConfig: nil
                    )
                ],
                searchTermParamName: "q",
                displayName: nil
            ),
            searchForm: nil,
            visualSearch: nil
        ),
        orderHint: nil,
        clickUrl: nil
    )

    private let perplexity_testEngine =
    SearchEngineDefinition(
        aliases: ["perplexity"],
        charset: "UTF-8",
        classification: .general,
        identifier: "perplexity",
        isNewUntil: nil,
        name: "Perplexity",
        optional: false,
        partnerCode: "firefox",
        telemetrySuffix: "",
        urls: SearchEngineUrls(
            search: SearchEngineUrl(
                base: "https://www.perplxity.ai/search",
                method: "GET",
                params: [
                    SearchUrlParam(
                        name: "pc",
                        value: "{partnerCode}",
                        enterpriseValue: nil,
                        experimentConfig: nil
                    )
                ],
                searchTermParamName: "q",
                displayName: nil
            ),
            suggestions: SearchEngineUrl(
                base: "https://www.suggest.perplxity.ai/suggest",
                method: "GET",
                params: [],
                searchTermParamName: "q",
                displayName: nil
            ),
            trending: SearchEngineUrl(
                base: "https://www.perplexity.ai/rest/autosuggest/list-trending-suggest",
                method: "GET",
                params: [
                    SearchUrlParam(
                        name: "lang",
                        value: "{acceptLanguages}",
                        enterpriseValue: nil,
                        experimentConfig: nil
                    )
                ],
                searchTermParamName: "q",
                displayName: nil
            ),
            searchForm: nil,
            visualSearch: nil
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

    func testConvertGoogleEngineTrendingURL() {
        let engine = google_US_testEngine
        let result = ASSearchEngineUtilities.convertASSearchURLToOpenSearchURL(engine.urls.trending,
                                                                               for: engine)
        let expected = "https://www.google.com/complete/search?client=firefox&channel=ftr&q={searchTerms}"
        XCTAssertEqual(result, expected)
    }

    func testEmptyPartnerCodeSearchURL() {
        var engine = google_US_testEngine

        // Force an empty partnerCode string:
        engine.partnerCode = ""

        let result = ASSearchEngineUtilities.convertASSearchURLToOpenSearchURL(engine.urls.search,
                                                                               for: engine)
        let expected = "https://www.google.com/search?client=&q={searchTerms}"
        XCTAssertEqual(result, expected)
    }

    func testSearchTermIncludedInBaseURL() {
        let engine = leo_eng_deu_engine_no_search_params

        let result = ASSearchEngineUtilities.convertASSearchURLToOpenSearchURL(engine.urls.search,
                                                                               for: engine)
        let expected = "https://dict.leo.org/englisch-deutsch/{searchTerms}"
        XCTAssertEqual(result, expected)
    }

    func testSearchTermIncludedInBaseURLAndParams() {
        let engine = leo_eng_deu_engine

        let result = ASSearchEngineUtilities.convertASSearchURLToOpenSearchURL(engine.urls.search,
                                                                               for: engine)
        let expected = "https://dict.leo.org/englisch-deutsch/{searchTerms}?foo=bar"
        XCTAssertEqual(result, expected)
    }

    func testPerplexityTrendingURLWithUS() {
        let engine = perplexity_testEngine
        let localeProvider = MockLocaleProvider.defaultEN()
        let result = ASSearchEngineUtilities.convertASSearchURLToOpenSearchURL(
            engine.urls.trending,
            for: engine,
            with: localeProvider
        )
        let expected = "https://www.perplexity.ai/rest/autosuggest/list-trending-suggest?lang=en-US&q={searchTerms}"
        XCTAssertEqual(result, expected)
    }

    func testPerplexityTrendingURLWithDE() {
        let engine = perplexity_testEngine
        let localeProvider = MockLocaleProvider(
            current: Locale(identifier: "de-US"),
            preferredLanguages: ["de"],
            regionCode: "US"
        )
        let result = ASSearchEngineUtilities.convertASSearchURLToOpenSearchURL(
            engine.urls.trending,
            for: engine,
            with: localeProvider
        )
        let expected = "https://www.perplexity.ai/rest/autosuggest/list-trending-suggest?lang=de&q={searchTerms}"
        XCTAssertEqual(result, expected)
    }
}
