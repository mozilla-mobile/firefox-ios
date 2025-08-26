// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class ShortcutsLibraryMiddlewareTests: XCTestCase {
    var mockGleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        mockGleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        mockGleanWrapper = nil
        super.tearDown()
    }

    func test_viewDidAppearAction_sendsTelemetryData() throws {
        let subject = createSubject()
        let action = ShortcutsLibraryAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ShortcutsLibraryActionType.viewDidAppear
        )

        subject.shortcutsLibraryProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.ShortcutsLibrary.viewed)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_viewDidDisappearAction_sendsTelemetryData() throws {
        let subject = createSubject()
        let action = ShortcutsLibraryAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ShortcutsLibraryActionType.viewDidDisappear
        )

        subject.shortcutsLibraryProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.ShortcutsLibrary.closed)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_tapOnShortcutCellAction_sendsTelemetryData() throws {
        let subject = createSubject()
        let action = ShortcutsLibraryAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ShortcutsLibraryActionType.tapOnShortcutCell
        )

        subject.shortcutsLibraryProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.ShortcutsLibrary.shortcutTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    // MARK: - Helpers
    private func createSubject() -> ShortcutsLibraryMiddleware {
        return ShortcutsLibraryMiddleware(
            shortcutsLibraryTelemetry: ShortcutsLibraryTelemetry(
                gleanWrapper: mockGleanWrapper
            )
        )
    }
}
