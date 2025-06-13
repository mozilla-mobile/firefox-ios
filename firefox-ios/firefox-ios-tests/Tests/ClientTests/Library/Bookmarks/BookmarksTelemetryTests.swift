// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class BookmarksTelemetryTests: XCTestCase {
    var subject: BookmarksTelemetry?
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        subject = BookmarksTelemetry(gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        subject = nil
        gleanWrapper = nil
        super.tearDown()
    }

    func testRecordBookmark_WhenAddedBookmark_ThenGleanIsCalled() throws {
        subject?.addBookmark(eventLabel: .bookmarksPanel)

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? LabeledMetricType<CounterMetricType>)
        let expectedMetricType = type(of: GleanMetrics.Bookmarks.add)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(gleanWrapper.recordLabelCalled, 1)
    }

    func testRecordBookmark_WhenDeletedBookmark_ThenGleanIsCalled() throws {
        subject?.deleteBookmark(eventLabel: .bookmarksPanel)

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? LabeledMetricType<CounterMetricType>)
        let expectedMetricType = type(of: GleanMetrics.Bookmarks.delete)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(gleanWrapper.recordLabelCalled, 1)
    }

    func testRecordBookmark_WhenOpenedSite_ThenGleanIsCalled() throws {
        subject?.openBookmarksSite(eventLabel: .bookmarksPanel)

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? LabeledMetricType<CounterMetricType>)
        let expectedMetricType = type(of: GleanMetrics.Bookmarks.open)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(gleanWrapper.recordLabelCalled, 1)
    }

    func testRecordBookmark_WhenEditedSite_ThenGleanIsCalled() throws {
        subject?.editBookmark(eventLabel: .bookmarksPanel)

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? LabeledMetricType<CounterMetricType>)
        let expectedMetricType = type(of: GleanMetrics.Bookmarks.edit)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(gleanWrapper.recordLabelCalled, 1)
    }

    func testRecordBookmark_WhenAddedFolder_ThenGleanIsCalled() throws {
        subject?.addBookmarkFolder()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.Bookmarks.folderAdd)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
    }
}
