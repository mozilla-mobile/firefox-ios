// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class ShareExtensionTelemetryTests: XCTestCase {
    var actionExtensionTelemetry: ShareExtensionTelemetry?
    var shareExtensionTelemetry: ShareExtensionTelemetry?
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        actionExtensionTelemetry = ShareExtensionTelemetry(extensionSource: .actionExtension, gleanWrapper: gleanWrapper)
        shareExtensionTelemetry = ShareExtensionTelemetry(extensionSource: .shareExtension, gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        actionExtensionTelemetry = nil
        shareExtensionTelemetry = nil
        gleanWrapper = nil
        super.tearDown()
    }

    // MARK: - shareURL Tests

    func testShareURL_WithActionExtensionSource_RecordsActionExtensionEvent() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtensionList.optionSelected
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtensionList.OptionSelectedExtra
        let expectedSource = "action-extension"
        let expectedOption = "open_in_firefox"

        actionExtensionTelemetry?.shareURL()

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.extensionSource, expectedSource)
        XCTAssertEqual(savedExtras.option, expectedOption)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testShareURL_WithShareExtensionSource_RecordsShareExtensionEvent() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtensionList.optionSelected
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtensionList.OptionSelectedExtra
        let expectedSource = "share-extension"
        let expectedOption = "open_in_firefox"

        shareExtensionTelemetry?.shareURL()

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.extensionSource, expectedSource)
        XCTAssertEqual(savedExtras.option, expectedOption)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    // MARK: - shareText Tests

    func testShareText_WithActionExtensionSource_RecordsActionExtensionEvent() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtensionList.optionSelected
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtensionList.OptionSelectedExtra
        let expectedSource = "action-extension"
        let expectedOption = "open_in_firefox"

        actionExtensionTelemetry?.shareText()

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.extensionSource, expectedSource)
        XCTAssertEqual(savedExtras.option, expectedOption)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testShareText_WithShareExtensionSource_RecordsShareExtensionEvent() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtensionList.optionSelected
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtensionList.OptionSelectedExtra
        let expectedSource = "share-extension"
        let expectedOption = "open_in_firefox"

        shareExtensionTelemetry?.shareText()

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.extensionSource, expectedSource)
        XCTAssertEqual(savedExtras.option, expectedOption)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    // MARK: - Multiple Events Tests

    func testMultipleShareURLEvents_RecordsAllEvents() throws {
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtensionList.OptionSelectedExtra

        actionExtensionTelemetry?.shareURL()
        shareExtensionTelemetry?.shareURL()

        XCTAssertEqual(gleanWrapper.recordEventCalled, 2)
        XCTAssertEqual(gleanWrapper.savedExtras.count, 2)

        let firstExtras = try XCTUnwrap(gleanWrapper.savedExtras[0] as? EventExtrasType)
        let secondExtras = try XCTUnwrap(gleanWrapper.savedExtras[1] as? EventExtrasType)

        XCTAssertEqual(firstExtras.extensionSource, "action-extension")
        XCTAssertEqual(firstExtras.option, "open_in_firefox")
        XCTAssertEqual(secondExtras.extensionSource, "share-extension")
        XCTAssertEqual(secondExtras.option, "open_in_firefox")
    }

    func testMultipleShareTextEvents_RecordsAllEvents() throws {
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtensionList.OptionSelectedExtra

        actionExtensionTelemetry?.shareText()
        shareExtensionTelemetry?.shareText()

        XCTAssertEqual(gleanWrapper.recordEventCalled, 2)
        XCTAssertEqual(gleanWrapper.savedExtras.count, 2)

        let firstExtras = try XCTUnwrap(gleanWrapper.savedExtras[0] as? EventExtrasType)
        let secondExtras = try XCTUnwrap(gleanWrapper.savedExtras[1] as? EventExtrasType)

        XCTAssertEqual(firstExtras.extensionSource, "action-extension")
        XCTAssertEqual(firstExtras.option, "open_in_firefox")
        XCTAssertEqual(secondExtras.extensionSource, "share-extension")
        XCTAssertEqual(secondExtras.option, "open_in_firefox")
    }

    // MARK: - loadInBackground Tests

    func testLoadInBackground_RecordsEvent() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtensionList.optionSelected
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtensionList.OptionSelectedExtra
        let expectedOption = "load_in_background"
        let expectedSource = "share-extension"

        shareExtensionTelemetry?.loadInBackground()

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.option, expectedOption)
        XCTAssertEqual(savedExtras.extensionSource, expectedSource)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    // MARK: - bookmarkThisPage Tests

    func testBookmarkThisPage_RecordsEvent() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtensionList.optionSelected
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtensionList.OptionSelectedExtra
        let expectedOption = "bookmark_this_page"
        let expectedSource = "share-extension"

        shareExtensionTelemetry?.bookmarkThisPage()

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.option, expectedOption)
        XCTAssertEqual(savedExtras.extensionSource, expectedSource)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    // MARK: - addToReadingList Tests

    func testAddToReadingList_RecordsEvent() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtensionList.optionSelected
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtensionList.OptionSelectedExtra
        let expectedOption = "add_to_reading_list"
        let expectedSource = "share-extension"

        shareExtensionTelemetry?.addToReadingList()

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.option, expectedOption)
        XCTAssertEqual(savedExtras.extensionSource, expectedSource)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    // MARK: - sendToDevice Tests

    func testSendToDevice_RecordsEvent() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtensionList.optionSelected
        typealias EventExtrasType = GleanMetrics.ShareOpenInFirefoxExtensionList.OptionSelectedExtra
        let expectedOption = "send_to_device"
        let expectedSource = "share-extension"

        shareExtensionTelemetry?.sendToDevice()

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.option, expectedOption)
        XCTAssertEqual(savedExtras.extensionSource, expectedSource)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    // MARK: - All Share Extension Actions Tests

    func testAllShareExtensionActions_RecordsAllEvents() throws {
        shareExtensionTelemetry?.loadInBackground()
        shareExtensionTelemetry?.bookmarkThisPage()
        shareExtensionTelemetry?.addToReadingList()
        shareExtensionTelemetry?.sendToDevice()

        XCTAssertEqual(gleanWrapper.recordEventCalled, 4)
        XCTAssertEqual(gleanWrapper.savedEvents.count, 4)
        XCTAssertEqual(gleanWrapper.savedExtras.count, 4)
    }
}
