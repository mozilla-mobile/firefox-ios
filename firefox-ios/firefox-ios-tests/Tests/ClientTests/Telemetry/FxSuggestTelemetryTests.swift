// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import Storage
import XCTest

@testable import Client

final class FxSuggestTelemetryTests: XCTestCase {
    private var gleanWrapper: MockGleanWrapper!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()

        Self.setupTelemetry(with: MockProfile())
        TelemetryContextualIdentifier.clearUserDefaults()
        gleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        Self.tearDownTelemetry()
        TelemetryContextualIdentifier.clearUserDefaults()
        gleanWrapper = nil
        super.tearDown()
    }

    // MARK: Click event

    func testClickEventPing_givenWikipediaInfo_thenPingSent() throws {
        TelemetryContextualIdentifier.setupContextId()
        let expectation = expectation(description: "The Firefox Suggest ping was sent")
        GleanMetrics.Pings.shared.fxSuggest.testBeforeNextSubmit { _ in
            let event = try XCTUnwrap(GleanMetrics.Awesomebar.searchResultTap.testGetValue())
            XCTAssertEqual(event[0].extra?["type"], FxSuggestTelemetry.EventInfo.wikipediaSuggestion.rawValue)

            XCTAssertEqual(
                GleanMetrics.FxSuggest.pingType.testGetValue(),
                FxSuggestTelemetry.EventInfo.pingTypeClick.rawValue
            )
            XCTAssertEqual(
                GleanMetrics.FxSuggest.contextId.testGetValue()?.uuidString,
                TelemetryContextualIdentifier.contextId
            )
            XCTAssertEqual(GleanMetrics.FxSuggest.isClicked.testGetValue(), true)
            XCTAssertEqual(GleanMetrics.FxSuggest.position.testGetValue(), 3)
            XCTAssertEqual(GleanMetrics.FxSuggest.blockId.testGetValue(), nil)
            XCTAssertEqual(GleanMetrics.FxSuggest.country.testGetValue(), "US")
            XCTAssertEqual(GleanMetrics.FxSuggest.advertiser.testGetValue(),
                           FxSuggestTelemetry.EventInfo.wikipediaAdvertiser.rawValue)
            XCTAssertEqual(GleanMetrics.FxSuggest.iabCategory.testGetValue(), nil)
            XCTAssertEqual(GleanMetrics.FxSuggest.reportingUrl.testGetValue(), nil)
            expectation.fulfill()
        }

        let info = RustFirefoxSuggestionTelemetryInfo.wikipedia
        let subject = createSubject()
        subject.clickEvent(telemetryInfo: info, position: 3)
        wait(for: [expectation], timeout: 5.0)
    }

    func testClickEventPing_givenAmpInfo_thenPingSent() throws {
        TelemetryContextualIdentifier.setupContextId()
        let expectation = expectation(description: "The Firefox Suggest ping was sent")
        GleanMetrics.Pings.shared.fxSuggest.testBeforeNextSubmit { _ in
            let event = try XCTUnwrap(GleanMetrics.Awesomebar.searchResultTap.testGetValue())
            XCTAssertEqual(event[0].extra?["type"], FxSuggestTelemetry.EventInfo.ampSuggestion.rawValue)

            XCTAssertEqual(
                GleanMetrics.FxSuggest.pingType.testGetValue(),
                FxSuggestTelemetry.EventInfo.pingTypeClick.rawValue
            )
            XCTAssertEqual(
                GleanMetrics.FxSuggest.contextId.testGetValue()?.uuidString,
                TelemetryContextualIdentifier.contextId
            )
            XCTAssertEqual(GleanMetrics.FxSuggest.isClicked.testGetValue(), true)
            XCTAssertEqual(GleanMetrics.FxSuggest.position.testGetValue(), 3)
            XCTAssertEqual(GleanMetrics.FxSuggest.blockId.testGetValue(), 1234)
            XCTAssertEqual(GleanMetrics.FxSuggest.country.testGetValue(), "US")
            XCTAssertEqual(GleanMetrics.FxSuggest.advertiser.testGetValue(), "test advertiser")
            XCTAssertEqual(GleanMetrics.FxSuggest.iabCategory.testGetValue(), "999 - Test Category")
            XCTAssertEqual(GleanMetrics.FxSuggest.reportingUrl.testGetValue(),
                           "https://example.com/ios_test_click_reporting_url")
            XCTAssertEqual(GleanMetrics.FxSuggest.country.testGetValue(), "US")
            expectation.fulfill()
        }

        let info = RustFirefoxSuggestionTelemetryInfo.amp(
            blockId: 1234,
            advertiser: "test advertiser",
            iabCategory: "999 - Test Category",
            impressionReportingURL: URL(string: "https://example.com/ios_test_impression_reporting_url"),
            clickReportingURL: URL(string: "https://example.com/ios_test_click_reporting_url")
        )
        let subject = createSubject()
        subject.clickEvent(telemetryInfo: info, position: 3)
        wait(for: [expectation], timeout: 5.0)
    }

    func testClickEventPing_givenContextId_thenPingSent() {
        TelemetryContextualIdentifier.setupContextId()
        let info = RustFirefoxSuggestionTelemetryInfo.amp(
            blockId: 1234,
            advertiser: "test-advertiser",
            iabCategory: "test-category",
            impressionReportingURL: URL(string: "https://test1.com"),
            clickReportingURL: URL(string: "https://test2.com")
        )

        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.clickEvent(telemetryInfo: info, position: 0)

        XCTAssertNotNil(gleanWrapper.savedPing)
    }

    // MARK: Impression event

    func testImpressionEventPing_givenWikipediaInfo_thenPingSent() throws {
        TelemetryContextualIdentifier.setupContextId()
        let expectation = expectation(description: "The Firefox Suggest ping was sent")
        GleanMetrics.Pings.shared.fxSuggest.testBeforeNextSubmit { _ in
            let event = try XCTUnwrap(GleanMetrics.Awesomebar.searchResultImpression.testGetValue())
            XCTAssertEqual(event[0].extra?["type"], FxSuggestTelemetry.EventInfo.wikipediaSuggestion.rawValue)
            XCTAssertEqual(
                GleanMetrics.FxSuggest.pingType.testGetValue(),
                FxSuggestTelemetry.EventInfo.pingTypeImpression.rawValue
            )
            XCTAssertEqual(
                GleanMetrics.FxSuggest.contextId.testGetValue()?.uuidString,
                TelemetryContextualIdentifier.contextId
            )
            XCTAssertEqual(GleanMetrics.FxSuggest.isClicked.testGetValue(), true)
            XCTAssertEqual(GleanMetrics.FxSuggest.position.testGetValue(), 3)
            XCTAssertEqual(GleanMetrics.FxSuggest.blockId.testGetValue(), nil)
            XCTAssertEqual(GleanMetrics.FxSuggest.advertiser.testGetValue(),
                           FxSuggestTelemetry.EventInfo.wikipediaAdvertiser.rawValue)
            XCTAssertEqual(GleanMetrics.FxSuggest.iabCategory.testGetValue(), nil)
            XCTAssertEqual(GleanMetrics.FxSuggest.reportingUrl.testGetValue(), nil)
            XCTAssertEqual(GleanMetrics.FxSuggest.country.testGetValue(), "US")
            expectation.fulfill()
        }

        let info = RustFirefoxSuggestionTelemetryInfo.wikipedia
        let subject = createSubject()
        subject.impressionEvent(telemetryInfo: info,
                                position: 3,
                                didTap: true,
                                didAbandonSearchSession: false)
        wait(for: [expectation], timeout: 5.0)
    }

    func testImpressionEventPing_givenAmpInfo_thenPingSent() throws {
        TelemetryContextualIdentifier.setupContextId()
        let expectation = expectation(description: "The Firefox Suggest ping was sent")
        GleanMetrics.Pings.shared.fxSuggest.testBeforeNextSubmit { _ in
            let event = try XCTUnwrap(GleanMetrics.Awesomebar.searchResultImpression.testGetValue())
            XCTAssertEqual(event[0].extra?["type"], FxSuggestTelemetry.EventInfo.ampSuggestion.rawValue)
            XCTAssertEqual(
                GleanMetrics.FxSuggest.pingType.testGetValue(),
                FxSuggestTelemetry.EventInfo.pingTypeImpression.rawValue
            )
            XCTAssertEqual(
                GleanMetrics.FxSuggest.contextId.testGetValue()?.uuidString,
                TelemetryContextualIdentifier.contextId
            )
            XCTAssertEqual(GleanMetrics.FxSuggest.isClicked.testGetValue(), true)
            XCTAssertEqual(GleanMetrics.FxSuggest.position.testGetValue(), 3)
            XCTAssertEqual(GleanMetrics.FxSuggest.blockId.testGetValue(), 1234)
            XCTAssertEqual(GleanMetrics.FxSuggest.advertiser.testGetValue(), "test-advertiser")
            XCTAssertEqual(GleanMetrics.FxSuggest.iabCategory.testGetValue(), "999 - Test Category")
            XCTAssertEqual(GleanMetrics.FxSuggest.reportingUrl.testGetValue(),
                           "https://example.com/ios_test_impression_reporting_url")
            XCTAssertEqual(GleanMetrics.FxSuggest.country.testGetValue(), "US")
            expectation.fulfill()
        }

        let info = RustFirefoxSuggestionTelemetryInfo.amp(
            blockId: 1234,
            advertiser: "test-advertiser",
            iabCategory: "999 - Test Category",
            impressionReportingURL: URL(string: "https://example.com/ios_test_impression_reporting_url"),
            clickReportingURL: URL(string: "https://example.com/ios_test_click_reporting_url")
        )
        let subject = createSubject()
        subject.impressionEvent(telemetryInfo: info,
                                position: 3,
                                didTap: true,
                                didAbandonSearchSession: false)
        wait(for: [expectation], timeout: 5.0)
    }

    func testImpressionEventPing_givenContextId_thenPingSent() {
        TelemetryContextualIdentifier.setupContextId()
        let info = RustFirefoxSuggestionTelemetryInfo.amp(
            blockId: 1234,
            advertiser: "test-advertiser",
            iabCategory: "test-category",
            impressionReportingURL: URL(string: "https://test1.com"),
            clickReportingURL: URL(string: "https://test2.com")
        )

        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.impressionEvent(telemetryInfo: info,
                                position: 1,
                                didTap: true,
                                didAbandonSearchSession: false)

        XCTAssertNotNil(gleanWrapper.savedPing)
    }

    func testImpressionEventPing_givenDidAbandonSearchSession_thenPingNotSent() {
        TelemetryContextualIdentifier.setupContextId()
        let info = RustFirefoxSuggestionTelemetryInfo.amp(
            blockId: 1234,
            advertiser: "test-advertiser",
            iabCategory: "test-category",
            impressionReportingURL: URL(string: "https://test1.com"),
            clickReportingURL: URL(string: "https://test2.com")
        )

        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.impressionEvent(telemetryInfo: info,
                                position: 1,
                                didTap: true,
                                didAbandonSearchSession: true)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1, "Awesomebar.searchResultTap is called")
        XCTAssertNil(gleanWrapper.savedPing)
    }

    // MARK: Helper methods

    func createSubject(locale: LocaleProvider = MockLocaleProvider(),
                       gleanWrapper: GleanWrapper = DefaultGleanWrapper()) -> FxSuggestTelemetry {
        gleanWrapper.enableTestingMode()
        return FxSuggestTelemetry(locale: locale, gleanWrapper: gleanWrapper)
    }
}
