// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class WorldCupTelemetryTests: XCTestCase {
    var mockGleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        mockGleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        mockGleanWrapper = nil
        super.tearDown()
    }

    func test_closeCountdownWidgetButtonTapped_recordsEvent() throws {
        let subject = createSubject()

        subject.closeCountdownWidgetButtonTapped()

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.WorldCupCountdownWidget.closeButton)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_viewScheduleTapped_recordsEvent() throws {
        let subject = createSubject()

        subject.viewScheduleTapped()

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.WorldCupCountdownWidget.viewSchedule)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_countrySelected_recordsEventWithFifaCodeExtra() throws {
        let event = GleanMetrics.WorldCupWidget.countrySelected
        typealias EventExtrasType = GleanMetrics.WorldCupWidget.CountrySelectedExtra

        let subject = createSubject()
        let expectedFifaCode = "USA"
        let expectedMetricType = type(of: event)

        subject.countrySelected(fifaCode: expectedFifaCode)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.fifaCode, expectedFifaCode)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_countryDeselected_recordsEvent() throws {
        let subject = createSubject()

        subject.countryDeselected()

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.WorldCupWidget.countryDeselected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_widgetDismissed_recordsEvent() throws {
        let subject = createSubject()

        subject.widgetDismissed()

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.WorldCupWidget.widgetDismissed)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_errorRefreshButtonTapped_recordsEvent() throws {
        let subject = createSubject()

        subject.errorRefreshButtonTapped()

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.WorldCupWidget.errorRefreshButton)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_matchClicked_recordsEventWithMatchExtra() throws {
        let event = GleanMetrics.WorldCupWidget.matchClicked
        typealias EventExtrasType = GleanMetrics.WorldCupWidget.MatchClickedExtra

        let subject = createSubject()
        let expectedMatch = "USA/MEX"
        let expectedMetricType = type(of: event)

        subject.matchClicked(match: expectedMatch)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.match, expectedMatch)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_cardSwiped_recordsEventWithViewAndImpressionExtras() throws {
        let event = GleanMetrics.WorldCupWidget.cardSwiped
        typealias EventExtrasType = GleanMetrics.WorldCupWidget.CardSwipedExtra

        let subject = createSubject()
        let expectedView = "Round of 16"
        let expectedIsImpression = true
        let expectedMetricType = type(of: event)

        subject.cardSwiped(view: expectedView, isImpression: expectedIsImpression)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.view, expectedView)
        XCTAssertEqual(savedExtras.isImpression, expectedIsImpression)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_countrySelectorDisplayed_recordsEvent() throws {
        let subject = createSubject()

        subject.countrySelectorDisplayed()

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.WorldCupWidget.countrySelectorDisplayed)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_multipleEvents_recordedIndependently() {
        let subject = createSubject()

        subject.closeCountdownWidgetButtonTapped()
        subject.viewScheduleTapped()

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 2)
        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 2)
    }

    // MARK: - Helpers

    private func createSubject() -> WorldCupTelemetry {
        return WorldCupTelemetry(gleanWrapper: mockGleanWrapper)
    }
}
