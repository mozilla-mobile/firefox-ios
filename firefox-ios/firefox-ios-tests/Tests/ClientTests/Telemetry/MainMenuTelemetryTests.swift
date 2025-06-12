// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class MainMenuTelemetryTests: XCTestCase {
    var subject: MainMenuTelemetry?
    var mockGleanWrapper: MockGleanWrapper!

    let isHomepageKey = "is_homepage"
    let optionKey = "option"

    override func setUp() {
        super.setUp()

        mockGleanWrapper = MockGleanWrapper()
        subject = MainMenuTelemetry(gleanWrapper: mockGleanWrapper)
    }

    override func tearDown() {
        mockGleanWrapper = nil
        super.tearDown()
    }

    func testRecordMainMenuWhenMainMenuOptionTappedThenGleanIsCalled() throws {
        subject?.mainMenuOptionTapped(with: true, and: "test_option")

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "test_option")
        XCTAssertEqual(savedExtras.isHomepage, true)
    }

    func testRecordMainMenuWhenSaveSubmenuOptionTappedThenGleanIsCalled() throws {
        subject?.saveSubmenuOptionTapped(with: true, and: "test_option")

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.SaveMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.SaveMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.saveMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "test_option")
        XCTAssertEqual(savedExtras.isHomepage, true)
    }

    func testRecordMainMenuWhenToolsSubmenuOptionTappedThenGleanIsCalled() throws {
        subject?.toolsSubmenuOptionTapped(with: true, and: "test_option")

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.ToolsMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.ToolsMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.toolsMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "test_option")
        XCTAssertEqual(savedExtras.isHomepage, true)
    }

    func testRecordMainMenuWhenCloseButtonTappedThenGleanIsCalled() throws {
        subject?.closeButtonTapped(isHomepage: true)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.CloseButtonExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.CloseButtonExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.closeButton)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isHomepage, true)
    }

    func testRecordMainMenuWhenMenuIsDismissedThenGleanIsCalled() throws {
        subject?.menuDismissed(isHomepage: true)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MenuDismissedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MenuDismissedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.menuDismissed)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isHomepage, true)
    }
}
