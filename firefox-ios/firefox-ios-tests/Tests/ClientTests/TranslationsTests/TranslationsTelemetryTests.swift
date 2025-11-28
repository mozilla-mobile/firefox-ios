// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest
@testable import Client

final class TranslationsTelemetryTests: XCTestCase {
    var mockGleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        mockGleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        mockGleanWrapper = nil
        super.tearDown()
    }

    func testRecordEvent_WhenPageLanguageIdentified_ThenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.Translations.pageLanguageIdentified
        typealias EventExtrasType = GleanMetrics.Translations.PageLanguageIdentifiedExtra

        let expectedDeviceLanguage = "en"
        let expectedIdentifiedLanguage = "fr"

        subject.pageLanguageIdentified(
            identifiedLanguage: expectedIdentifiedLanguage,
            deviceLanguage: expectedDeviceLanguage
        )

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.deviceLanguage, expectedDeviceLanguage)
        XCTAssertEqual(savedExtras.identifiedLanguage, expectedIdentifiedLanguage)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_WhenPageLanguageIdentificationFailed_ThenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.Translations.pageLanguageIdentificationFailed
        typealias EventExtrasType = GleanMetrics.Translations.PageLanguageIdentificationFailedExtra

        let expectedErrorType = "some_error"

        subject.pageLanguageIdentificationFailed(errorType: expectedErrorType)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.errorType, expectedErrorType)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_WhenTranslationFailed_ThenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.Translations.translationFailed
        typealias EventExtrasType = GleanMetrics.Translations.TranslationFailedExtra

        let expectedErrorType = "network_error"
        let expectedFlowId = UUID()

        subject.translationFailed(
            translationFlowId: expectedFlowId,
            errorType: expectedErrorType
        )

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.errorType, expectedErrorType)
        XCTAssertEqual(savedExtras.translationFlowId, expectedFlowId.uuidString)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_WhenWebpageRestored_ThenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.Translations.webpageRestored
        typealias EventExtrasType = GleanMetrics.Translations.WebpageRestoredExtra

        let expectedFlowId = UUID()

        subject.webpageRestored(translationFlowId: expectedFlowId)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.translationFlowId, expectedFlowId.uuidString)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_WhenTranslateButtonTapped_ThenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.Toolbar.translateButtonTapped
        typealias EventExtrasType = GleanMetrics.Toolbar.TranslateButtonTappedExtra

        let expectedIsPrivate = true
        let expectedActionType: TranslateButtonActionType = .willTranslate
        let expectedFlowId = UUID()

        subject.translateButtonTapped(
            isPrivate: expectedIsPrivate,
            actionType: expectedActionType,
            translationFlowId: expectedFlowId
        )

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.isPrivate, expectedIsPrivate)
        XCTAssertEqual(savedExtras.actionType, expectedActionType.rawValue)
        XCTAssertEqual(savedExtras.translationFlowId, expectedFlowId.uuidString)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    private func createSubject() -> TranslationsTelemetry {
        return TranslationsTelemetry(gleanWrapper: mockGleanWrapper)
    }
}
