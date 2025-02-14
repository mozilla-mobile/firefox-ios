// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class ToolbarTelemetryTests: XCTestCase {
    var subject: ToolbarTelemetry?
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
    }

    private func createSubject(gleanWrapper: MockGleanWrapper) -> ToolbarTelemetry {
        return ToolbarTelemetry(gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testRecordToolbarWhenQrCodeTappedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.qrCodeButtonTapped(isPrivate: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.qrScanButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.PrivateBrowsing.DataClearanceIconTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.PrivateBrowsing.dataClearanceIconTapped)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenClearSearchTappedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.clearSearchButtonTapped(isPrivate: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.clearSearchButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Toolbar.clearSearchButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.clearSearchButtonTapped)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenShareButtonTappedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.shareButtonTapped(isPrivate: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.shareButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Toolbar.shareButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.shareButtonTapped)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenRefreshButtonTappedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.refreshButtonTapped(isPrivate: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.refreshButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Toolbar.refreshButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.refreshButtonTapped)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenReaderModeTappedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.readerModeButtonTapped(isPrivate: true, isEnabled: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.readerModeButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Toolbar.readerModeButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.readerModeButtonTapped)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenSiteInfoTappedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.siteInfoButtonTapped(isPrivate: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.siteInfoButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Toolbar.siteInfoButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.siteInfoButtonTapped)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenBackButtonTappedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.backButtonTapped(isPrivate: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.backButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Toolbar.backButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.backButtonTapped)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenForwardButtonTappedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.forwardButtonTapped(isPrivate: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.forwardButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Toolbar.forwardButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.forwardButtonTapped)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenBackLongPressedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.backButtonLongPressed(isPrivate: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.backLongPressExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Toolbar.backLongPressExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.backLongPress)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenForwardLongPressedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.forwardButtonLongPressed(isPrivate: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.forwardLongPressExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Toolbar.forwardLongPressExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.forwardLongPress)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenHomeButtonTappedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.homeButtonTapped(isPrivate: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.homeButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Toolbar.homeButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.homeButtonTapped)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenOneTapNewTabTappedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.oneTapNewTabButtonTapped(isPrivate: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.oneTapNewTabButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Toolbar.oneTapNewTabButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.oneTapNewTabButtonTapped)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenOneTapNewTabLongPressedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.oneTapNewTabButtonLongPressed(isPrivate: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.oneTapNewTabLongPressExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Toolbar.oneTapNewTabLongPressExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.oneTapNewTabLongPress)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenSearchTappedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.searchButtonTapped(isPrivate: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.searchButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Toolbar.searchButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.searchButtonTapped)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenTabTrayTappedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.tabTrayButtonTapped(isPrivate: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.tabTrayButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Toolbar.tabTrayButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.tabTrayButtonTapped)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenTabTrayLongPressedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.tabTrayButtonLongPressed(isPrivate: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.tabTrayLongPressExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Toolbar.tabTrayLongPressExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.tabTrayLongPress)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenMenuTappedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.menuButtonTapped(isPrivate: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.appMenuButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Toolbar.appMenuButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.appMenuButtonTapped)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenDataClearanceTappedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.dataClearanceButtonTapped(isPrivate: true)
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Toolbar.dataClearanceButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Toolbar.dataClearanceButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.dataClearanceButtonTapped)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testRecordToolbarWhenLocationDraggedThenGleanIsCalled() throws {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.dragInteractionStarted()
        
        let savedEvent = try XCTUnwrap(
                gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.Awesomebar.dragLocationBarExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Awesomebar.dragLocationBarExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Awesomebar.dragLocationBar)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }
}
