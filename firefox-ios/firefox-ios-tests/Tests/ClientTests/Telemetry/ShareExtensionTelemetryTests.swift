// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class ShareExtensionTelemetryTests: XCTestCase {
    var shareExtensionTelemetry: ShareExtensionTelemetry?
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        shareExtensionTelemetry = ShareExtensionTelemetry(gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        shareExtensionTelemetry = nil
        gleanWrapper = nil
        super.tearDown()
    }

    // MARK: - shareURL Tests

    func testShareURL_RecordsShareExtensionEvent() throws {
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

    func testShareText_RecordsShareExtensionEvent() throws {
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
