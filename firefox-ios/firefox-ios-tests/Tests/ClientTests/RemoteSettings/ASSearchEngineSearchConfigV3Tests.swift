// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import MozillaAppServices
import UIKit
import XCTest

@MainActor
final class ASSearchEngineSearchConfigV3Tests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - RefinedSearchConfigV3

    func testRemoveDeprecatedEngines_withoutDeprecatedEngines_changesNothing() {
        var subject = makeConfig(engines: [makeV3Engine("google"), makeV3Engine("ddg")], defaultID: "google")

        let removed = subject.removeDeprecatedEngines()

        XCTAssertEqual(removed, [])
        XCTAssertEqual(subject.engines.map(\.identifier), ["google", "ddg"])
        XCTAssertEqual(subject.appDefaultEngineId, "google")
    }

    func testRemoveDeprecatedEngines_removesDeprecatedNonDefaultEngine() {
        var subject = makeConfig(engines: [makeV3Engine("google"), makeV3Engine("perplexity", deprecated: true)],
                                 defaultID: "google")

        let removed = subject.removeDeprecatedEngines()

        XCTAssertEqual(removed, ["perplexity"])
        XCTAssertEqual(subject.engines.map(\.identifier), ["google"])
        XCTAssertEqual(subject.appDefaultEngineId, "google")
    }

    func testRemoveDeprecatedEngines_withDeprecatedDefault_clearsDefaultID() {
        var subject = makeConfig(engines: [makeV3Engine("google", deprecated: true), makeV3Engine("ddg")],
                                 defaultID: "google",
                                 privateDefaultID: "google")

        subject.removeDeprecatedEngines()
        subject.sortDefaultEngineToIndex0()

        XCTAssertEqual(subject.engines.map(\.identifier), ["ddg"])
        XCTAssertNil(subject.appDefaultEngineId)
        XCTAssertNil(subject.appPrivateDefaultEngineId)
    }

    func testSortDefaultEngineToIndex0_movesDefaultToFront() {
        var subject = makeConfig(engines: [makeV3Engine("ddg"), makeV3Engine("bing"), makeV3Engine("google")],
                                 defaultID: "google")

        subject.sortDefaultEngineToIndex0()

        XCTAssertEqual(subject.engines.map(\.identifier), ["google", "ddg", "bing"])
    }

    // MARK: - ASSearchEngineProvider

    func testProvider_flagOff_usesV2Only() throws {
        let selector = MockASSearchEngineSelector()
        selector.v2Result = RefinedSearchConfig(engines: [makeV2Engine("google")],
                                                appDefaultEngineId: "google",
                                                appPrivateDefaultEngineId: nil)

        let engines = try fetchEngines(selector: selector, isSearchConfigV3Enabled: false)

        XCTAssertEqual(selector.v2CallCount, 1)
        XCTAssertEqual(selector.v3CallCount, 0)
        XCTAssertEqual(engines.map(\.engineID), ["google"])
        XCTAssertNil(engines.first?.partners)
    }

    func testProvider_flagOn_usesV3AndSkipsOptionalEngines() throws {
        let selector = MockASSearchEngineSelector()
        selector.v3Result = makeConfig(engines: [makeV3Engine("google"), makeV3Engine("optional-one", optional: true)],
                                       defaultID: "google")

        let engines = try fetchEngines(selector: selector, isSearchConfigV3Enabled: true)

        XCTAssertEqual(selector.v3CallCount, 1)
        XCTAssertEqual(selector.v2CallCount, 0)
        XCTAssertEqual(engines.map(\.engineID), ["google"])
        XCTAssertEqual(engines.first?.partners?["default"]?.code, "ios-firefox-o-re")
        XCTAssertEqual(engines.first?.searchTemplate.contains(OpenSearchEngine.partnerCodeComponent), true)
    }

    func testProvider_flagOn_v3Error_fallsBackToV2() throws {
        let selector = MockASSearchEngineSelector()
        selector.v3Error = NSError(domain: "test", code: 1)
        selector.v2Result = RefinedSearchConfig(engines: [makeV2Engine("google")],
                                                appDefaultEngineId: "google",
                                                appPrivateDefaultEngineId: nil)

        let engines = try fetchEngines(selector: selector, isSearchConfigV3Enabled: true)

        XCTAssertEqual(selector.v3CallCount, 1)
        XCTAssertEqual(selector.v2CallCount, 1)
        XCTAssertEqual(engines.map(\.engineID), ["google"])
        XCTAssertNil(engines.first?.partners)
    }

    func testProvider_flagOn_v3Empty_fallsBackToV2() throws {
        let selector = MockASSearchEngineSelector()
        selector.v3Result = makeConfig(engines: [], defaultID: nil)
        selector.v2Result = RefinedSearchConfig(engines: [makeV2Engine("google")],
                                                appDefaultEngineId: "google",
                                                appPrivateDefaultEngineId: nil)

        let engines = try fetchEngines(selector: selector, isSearchConfigV3Enabled: true)

        XCTAssertEqual(selector.v2CallCount, 1)
        XCTAssertEqual(engines.map(\.engineID), ["google"])
    }

    // MARK: - Helpers

    private func fetchEngines(selector: MockASSearchEngineSelector,
                              isSearchConfigV3Enabled: Bool) throws -> [OpenSearchEngine] {
        let subject = ASSearchEngineProvider(selector: selector,
                                             iconDataFetcher: MockASSearchEngineIconDataFetcher(),
                                             isSearchConfigV3Enabled: isSearchConfigV3Enabled)
        let expectation = expectation(description: "Engines fetched")
        nonisolated(unsafe) var result: [OpenSearchEngine] = []
        subject.getOrderedEngines(customEngines: [],
                                  engineOrderingPrefs: SearchEnginePrefs(engineIdentifiers: nil,
                                                                         disabledEngines: nil,
                                                                         version: .v2),
                                  prefsMigrator: PassthroughPrefsMigrator()) { _, engines in
            result = engines
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
        return result
    }

    private func makeConfig(engines: [SearchEngineDefinitionV3],
                            defaultID: String?,
                            privateDefaultID: String? = nil) -> RefinedSearchConfigV3 {
        return RefinedSearchConfigV3(engines: engines,
                                     appDefaultEngineId: defaultID,
                                     appPrivateDefaultEngineId: privateDefaultID)
    }

    private func makeV3Engine(_ identifier: String,
                              optional: Bool = false,
                              deprecated: Bool = false) -> SearchEngineDefinitionV3 {
        return SearchEngineDefinitionV3(
            aliases: [],
            charset: "UTF-8",
            classification: .general,
            identifier: identifier,
            isNewUntil: nil,
            name: identifier,
            optional: optional,
            partner: ["default": SearchEnginePartnerDetails(code: "ios-firefox-o-re", telemetrySuffix: "ios-main")],
            urls: makeURLs(),
            orderHint: nil,
            deprecated: deprecated
        )
    }

    private func makeV2Engine(_ identifier: String) -> SearchEngineDefinition {
        return SearchEngineDefinition(
            aliases: [],
            charset: "UTF-8",
            classification: .general,
            identifier: identifier,
            isNewUntil: nil,
            name: identifier,
            optional: false,
            partnerCode: "firefox-b-m",
            telemetrySuffix: "",
            urls: makeURLs(),
            orderHint: nil,
            clickUrl: nil
        )
    }

    private func makeURLs() -> SearchEngineUrls {
        return SearchEngineUrls(
            search: SearchEngineUrl(
                base: "https://www.google.com/search",
                method: "GET",
                params: [SearchUrlParam(name: "client",
                                        value: "{partnerCode}",
                                        enterpriseValue: nil,
                                        experimentConfig: nil)],
                searchTermParamName: "q",
                displayName: nil
            ),
            suggestions: nil,
            trending: nil,
            searchForm: nil,
            visualSearch: nil
        )
    }
}

private final class MockASSearchEngineSelector: ASSearchEngineSelectorProtocol, @unchecked Sendable {
    var v2Result: RefinedSearchConfig?
    var v3Result: RefinedSearchConfigV3?
    var v3Error: Error?
    var v2CallCount = 0
    var v3CallCount = 0

    func fetchSearchEngines(locale: String,
                            region: String,
                            completion: @escaping ((RefinedSearchConfig?, Error?) -> Void)) {
        v2CallCount += 1
        completion(v2Result, nil)
    }

    func fetchSearchEnginesV3(locale: String,
                              region: String,
                              completion: @escaping ((RefinedSearchConfigV3?, Error?) -> Void)) {
        v3CallCount += 1
        completion(v3Result, v3Error)
    }
}

private final class MockASSearchEngineIconDataFetcher: ASSearchEngineIconDataFetcherProtocol, @unchecked Sendable {
    func populateEngineIconData(_ engines: [SearchEngineDefinition],
                                completion: @escaping ([(SearchEngineDefinition, UIImage)]) -> Void) {
        completion(engines.map { ($0, UIImage()) })
    }

    func populateEngineIconDataV3(_ engines: [SearchEngineDefinitionV3],
                                  completion: @escaping ([(SearchEngineDefinitionV3, UIImage)]) -> Void) {
        completion(engines.map { ($0, UIImage()) })
    }
}

private struct PassthroughPrefsMigrator: SearchEnginePreferencesMigrator {
    func migratePrefsIfNeeded(_ prefs: SearchEnginePrefs,
                              to expectedVersion: SearchEngineOrderingPrefsVersion,
                              availableEngines: [OpenSearchEngine]) -> SearchEnginePrefs {
        return prefs
    }
}
