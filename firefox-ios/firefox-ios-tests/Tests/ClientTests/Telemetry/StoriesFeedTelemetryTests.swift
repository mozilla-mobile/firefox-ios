// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class StoriesFeedTelemetryTests: XCTestCase {
    var subject: StoriesFeedTelemetry?
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        subject = StoriesFeedTelemetry(gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        subject = nil
        gleanWrapper = nil
        super.tearDown()
    }

    func testRecordEvent_WhenViewIsClosed_ThenGleanIsCalled() throws {
        let event = GleanMetrics.HomepageStoriesFeed.closed
        let expectedMetricType = type(of: event)

        subject?.storiesFeedClosed()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(
            expectedMetric: expectedMetricType,
            resultMetric: resultMetricType
        )

        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func testRecordEvent_WhenViewIsOpened_ThenGleanIsCalled() throws {
        let event = GleanMetrics.HomepageStoriesFeed.viewed
        let expectedMetricType = type(of: event)

        subject?.storiesFeedViewed()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(
            expectedMetric: expectedMetricType,
            resultMetric: resultMetricType
        )

        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func testRecordEvent_TappingAStoryToViewIt_ThenGleanIsCalled() throws {
        let event = GleanMetrics.HomepageStoriesFeed.storyTapped
        typealias EventExtrasType = GleanMetrics.HomepageStoriesFeed.StoryTappedExtra
        let expectedIndex = Int32(1)
        let expectedMetricType = type(of: event)

        subject?.sendStoryTappedTelemetry(atIndex: 0)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.index, expectedIndex)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func testRecordEvent_SendStoryImpression_ThenGleanIsCalled() throws {
        let event = GleanMetrics.HomepageStoriesFeed.storyViewed
        typealias EventExtrasType = GleanMetrics.HomepageStoriesFeed.StoryViewedExtra
        let expectedIndex = Int32(1)
        let expectedMetricType = type(of: event)

        subject?.sendStoryViewedTelemetryFor(storyIndex: 0)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.index, expectedIndex)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }
}
