// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
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

    private func createSubject() -> SearchTelemetry {
        return SearchTelemetry(tabManager: MockTabManager(), gleanWrapper: mockGleanWrapper)
    }
}
