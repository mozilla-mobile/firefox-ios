// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class ShareExtensionTelemetryTests: XCTestCase {
    var subject: ShareExtensionTelemetry?
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        subject = ShareExtensionTelemetry(gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        subject = nil
        gleanWrapper = nil
        super.tearDown()
    }

    // MARK: - shareURL Tests

    func testShareURL_WithDefaultSource_RecordsActionExtensionEvent() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtension.urlShared
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtension.UrlSharedExtra
        let expectedSource = "action-extension"

        subject?.shareURL()

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.extensionSource, expectedSource)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testShareURL_WithShareExtensionSource_RecordsShareExtensionEvent() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtension.urlShared
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtension.UrlSharedExtra
        let expectedSource = "share-extension"

        subject?.shareURL(extensionSource: expectedSource)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.extensionSource, expectedSource)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testShareURL_WithCustomSource_RecordsWithCustomSource() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtension.urlShared
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtension.UrlSharedExtra
        let expectedSource = "custom-source"

        subject?.shareURL(extensionSource: expectedSource)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.extensionSource, expectedSource)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    // MARK: - shareText Tests

    func testShareText_WithDefaultSource_RecordsActionExtensionEvent() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtension.textShared
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtension.TextSharedExtra
        let expectedSource = "action-extension"

        subject?.shareText()

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.extensionSource, expectedSource)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testShareText_WithShareExtensionSource_RecordsShareExtensionEvent() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtension.textShared
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtension.TextSharedExtra
        let expectedSource = "share-extension"

        subject?.shareText(extensionSource: expectedSource)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.extensionSource, expectedSource)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testShareText_WithCustomSource_RecordsWithCustomSource() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtension.textShared
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtension.TextSharedExtra
        let expectedSource = "custom-source"

        subject?.shareText(extensionSource: expectedSource)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.extensionSource, expectedSource)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    // MARK: - Multiple Events Tests

    func testMultipleShareURLEvents_RecordsAllEvents() throws {
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtension.UrlSharedExtra

        subject?.shareURL(extensionSource: "action-extension")
        subject?.shareURL(extensionSource: "share-extension")

        XCTAssertEqual(gleanWrapper.recordEventCalled, 2)
        XCTAssertEqual(gleanWrapper.savedExtras.count, 2)

        let firstExtras = try XCTUnwrap(gleanWrapper.savedExtras[0] as? EventExtrasType)
        let secondExtras = try XCTUnwrap(gleanWrapper.savedExtras[1] as? EventExtrasType)

        XCTAssertEqual(firstExtras.extensionSource, "action-extension")
        XCTAssertEqual(secondExtras.extensionSource, "share-extension")
    }

    func testMultipleShareTextEvents_RecordsAllEvents() throws {
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtension.TextSharedExtra

        subject?.shareText(extensionSource: "action-extension")
        subject?.shareText(extensionSource: "share-extension")

        XCTAssertEqual(gleanWrapper.recordEventCalled, 2)
        XCTAssertEqual(gleanWrapper.savedExtras.count, 2)

        let firstExtras = try XCTUnwrap(gleanWrapper.savedExtras[0] as? EventExtrasType)
        let secondExtras = try XCTUnwrap(gleanWrapper.savedExtras[1] as? EventExtrasType)

        XCTAssertEqual(firstExtras.extensionSource, "action-extension")
        XCTAssertEqual(secondExtras.extensionSource, "share-extension")
    }
}
