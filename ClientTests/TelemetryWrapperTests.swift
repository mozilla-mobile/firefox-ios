// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest

class TelemetryWrapperTests: XCTestCase {

    override func setUp() {
        super.setUp()

        Glean.shared.resetGlean(clearStores: true)
    }

    // MARK: Top Site

    func test_topSiteTileWithExtras_GleanIsCalled() {
        let topSitePositionKey = TelemetryWrapper.EventExtraKey.topSitePosition.rawValue
        let topSiteTileTypeKey = TelemetryWrapper.EventExtraKey.topSiteTileType.rawValue
        let extras = [topSitePositionKey : "\(1)", topSiteTileTypeKey: "history-based"]
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .topSiteTile, value: nil, extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.TopSite.tilePressed)
    }

    func test_topSiteTileWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .topSiteTile, value: nil)
        XCTAssertFalse(GleanMetrics.TopSite.tilePressed.testHasValue())
    }

    // MARK: Preferences

    func test_preferencesWithExtras_GleanIsCalled() {
        let extras: [String : Any] = [TelemetryWrapper.EventExtraKey.preference.rawValue: "ETP-strength",
                                      TelemetryWrapper.EventExtraKey.preferenceChanged.rawValue: BlockingStrength.strict.rawValue]
        TelemetryWrapper.recordEvent(category: .action, method: .change, object: .setting, extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Preferences.changed)
    }

    func test_preferencesWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .change, object: .setting)
        XCTAssertFalse(GleanMetrics.Preferences.changed.testHasValue())
    }

    // MARK: Firefox Home Page

    func test_recentlySavedBookmarkViewWithExtras_GleanIsCalled() {
        let extras: [String : Any] = [TelemetryWrapper.EventObject.recentlySavedBookmarkImpressions.rawValue: "\([].count)"]
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .firefoxHomepage, value: .recentlySavedBookmarkItemView, extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.FirefoxHomePage.recentlySavedBookmarkView)
    }

    func test_recentlySavedBookmarkViewWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .firefoxHomepage, value: .recentlySavedBookmarkItemView)
        XCTAssertFalse(GleanMetrics.FirefoxHomePage.recentlySavedBookmarkView.testHasValue())
    }

    func test_recentlySavedReadingListViewViewWithExtras_GleanIsCalled() {
        let extras: [String : Any] = [TelemetryWrapper.EventObject.recentlySavedReadingItemImpressions.rawValue: "\([].count)"]
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .firefoxHomepage, value: .recentlySavedReadingListView, extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.FirefoxHomePage.readingListView)
    }

    func test_recentlySavedReadingListViewWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .firefoxHomepage, value: .recentlySavedReadingListView)
        XCTAssertFalse(GleanMetrics.FirefoxHomePage.readingListView.testHasValue())
    }

    func test_firefoxHomePageAddView_GleanIsCalled() {
        let extras = [TelemetryWrapper.EventExtraKey.fxHomepageOrigin.rawValue: TelemetryWrapper.EventValue.fxHomepageOriginZeroSearch.rawValue]
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .firefoxHomepage, value: .fxHomepageOrigin, extras: extras)

        testLabeledMetricSuccess(metric: GleanMetrics.FirefoxHomePage.firefoxHomepageOrigin)
    }
}

// Helper functions
extension TelemetryWrapperTests {

    func testEventMetricRecordingSuccess<Keys: ExtraKeys, Extras: EventExtras>(metric: EventMetricType<Keys, Extras>,
                                                                               file: StaticString = #file,
                                                                               line: UInt = #line) {
        XCTAssertTrue(metric.testHasValue())
        XCTAssertEqual(try! metric.testGetValue().count, 1)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0)
    }

    func testCounterMetricRecordingSuccess(metric: CounterMetricType,
                                           file: StaticString = #file,
                                           line: UInt = #line) {
        XCTAssertTrue(metric.testHasValue())
        XCTAssertEqual(try! metric.testGetValue(), 1)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0)
    }

    func testLabeledMetricSuccess(metric: LabeledMetricType<CounterMetricType>,
                                  file: StaticString = #file,
                                  line: UInt = #line) {
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0)
    }
}
