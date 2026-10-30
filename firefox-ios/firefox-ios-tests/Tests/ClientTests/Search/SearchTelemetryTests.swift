// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import UIKit
import XCTest
@testable import Client

final class SearchTelemetryTests: XCTestCase {
    var mockGleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        mockGleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        mockGleanWrapper = nil
        super.tearDown()
    }

    func test_recordEvent_whenTrendingSearchSectionShown_thenProperEventCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.SearchTrendingSearches.suggestionsShown
        typealias EventExtrasType = GleanMetrics.SearchTrendingSearches.SuggestionsShownExtra

        subject.trendingSearchesShown(count: 3)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.count, 3)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_recordEvent_whenTrendingSearchTapped_thenProperEventCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.SearchTrendingSearches.suggestionTapped
        typealias EventExtrasType = GleanMetrics.SearchTrendingSearches.SuggestionTappedExtra

        subject.trendingSearchesTapped(at: 0)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.position, 1)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_recordEvent_whenRecentSearchSectionShown_thenProperEventCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.SearchRecentSearches.suggestionsShown
        typealias EventExtrasType = GleanMetrics.SearchRecentSearches.SuggestionsShownExtra

        subject.recentSearchesShown(count: 3)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.count, 3)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_recordEvent_whenRecentSearchTapped_thenProperEventCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.SearchRecentSearches.suggestionTapped
        typealias EventExtrasType = GleanMetrics.SearchRecentSearches.SuggestionTappedExtra

        subject.recentSearchesTapped(at: 0)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.position, 1)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_recordEvent_whenRecentSearchClearButtonTapped_thenProperEventCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.SearchRecentSearches.clearButtonTapped

        subject.recentSearchesClearButtonTapped()

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    private func createSubject() -> SearchTelemetry {
        return SearchTelemetry(tabManager: MockTabManager(), gleanWrapper: mockGleanWrapper)
    }
}

// MARK: - search-config-v3 partner codes

extension SearchTelemetryTests {
    @MainActor
    func test_searchConfigV3PartnerCode_withoutV3Engine_returnsNil() throws {
        let subject = try createV3Subject(partners: nil)
        let url = URL(string: "https://www.google.com/search?client=ios-firefox-o-re&q=kitten")

        XCTAssertNil(subject.searchConfigV3PartnerCode(for: .google, url: url))
    }

    @MainActor
    func test_searchConfigV3PartnerCode_withConfiguredClient_returnsClient() throws {
        let subject = try createV3Subject(partners: SearchPartnerResolverTests.googleIOSPartners)
        let url = URL(string: "https://www.google.com/search?client=ios-firefox-cm-re&q=kitten")

        XCTAssertEqual(subject.searchConfigV3PartnerCode(for: .google, url: url), "ios-firefox-cm-re")
    }

    @MainActor
    func test_searchConfigV3PartnerCode_withUnknownOrMissingClient_returnsNone() throws {
        let subject = try createV3Subject(partners: SearchPartnerResolverTests.googleIOSPartners)

        let unknown = URL(string: "https://www.google.com/search?client=other&q=kitten")
        let missing = URL(string: "https://www.google.com/search?q=kitten")

        XCTAssertEqual(subject.searchConfigV3PartnerCode(for: .google, url: unknown), "none")
        XCTAssertEqual(subject.searchConfigV3PartnerCode(for: .google, url: missing), "none")
    }

    @MainActor
    func test_searchConfigV3PartnerCode_nonGoogleProvider_returnsNil() throws {
        let subject = try createV3Subject(partners: SearchPartnerResolverTests.googleIOSPartners)
        let url = URL(string: "https://duckduckgo.com/?q=kitten")

        XCTAssertNil(subject.searchConfigV3PartnerCode(for: .none, url: url))
    }

    private func createV3Subject(partners: [String: SearchEnginePartner]?) throws -> SearchTelemetry {
        let image = try XCTUnwrap(UIImage(named: "wikipedia", in: Bundle(for: SearchTelemetryTests.self), with: nil))
        let engine = OpenSearchEngine(engineID: "google",
                                      shortName: "Google",
                                      telemetrySuffix: nil,
                                      image: image,
                                      searchTemplate: "https://www.google.com/search?client={partnerCode}&q={searchTerms}",
                                      suggestTemplate: nil,
                                      isCustomEngine: false,
                                      partners: partners)
        return SearchTelemetry(tabManager: MockTabManager(),
                               gleanWrapper: mockGleanWrapper,
                               searchEnginesManager: MockSearchEnginesManager(searchEngines: [engine]))
    }
}
