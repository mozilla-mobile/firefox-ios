// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class ToolbarTelemetryTests: XCTestCase {
    var subject: ToolbarTelemetry?

    override func setUp() {
        super.setUp()
        Glean.shared.resetGlean(clearStores: true)
        subject = ToolbarTelemetry()
    }

    func testRecordToolbarWhenQrCodeTappedThenGleanIsCalled() throws {
        subject?.qrCodeButtonTapped(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.qrScanButtonTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.qrScanButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenClearSearchTappedThenGleanIsCalled() throws {
        subject?.clearSearchButtonTapped(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.clearSearchButtonTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.clearSearchButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenShareButtonTappedThenGleanIsCalled() throws {
        subject?.shareButtonTapped(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.shareButtonTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.shareButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenRefreshButtonTappedThenGleanIsCalled() throws {
        subject?.refreshButtonTapped(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.refreshButtonTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.refreshButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenReaderModeTappedThenGleanIsCalled() throws {
        subject?.readerModeButtonTapped(isPrivate: true, isEnabled: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.readerModeButtonTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.readerModeButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
        XCTAssertEqual(resultValue[0].extra?["enabled"], "true")
    }

    func testRecordToolbarWhenSiteInfoTappedThenGleanIsCalled() throws {
        subject?.siteInfoButtonTapped(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.siteInfoButtonTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.siteInfoButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenBackButtonTappedThenGleanIsCalled() throws {
        subject?.backButtonTapped(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.backButtonTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.backButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenForwardButtonTappedThenGleanIsCalled() throws {
        subject?.forwardButtonTapped(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.forwardButtonTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.forwardButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenBackLongPressedThenGleanIsCalled() throws {
        subject?.backButtonLongPressed(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.backLongPress)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.backLongPress.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenForwardLongPressedThenGleanIsCalled() throws {
        subject?.forwardButtonLongPressed(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.forwardLongPress)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.forwardLongPress.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenHomeButtonTappedThenGleanIsCalled() throws {
        subject?.homeButtonTapped(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.homeButtonTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.homeButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenOneTapNewTabTappedThenGleanIsCalled() throws {
        subject?.oneTapNewTabButtonTapped(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.oneTapNewTabButtonTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.oneTapNewTabButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenOneTapNewTabLongPressedThenGleanIsCalled() throws {
        subject?.oneTapNewTabButtonLongPressed(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.oneTapNewTabLongPress)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.oneTapNewTabLongPress.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenSearchTappedThenGleanIsCalled() throws {
        subject?.searchButtonTapped(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.searchButtonTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.searchButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenTabTrayTappedThenGleanIsCalled() throws {
        subject?.tabTrayButtonTapped(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.tabTrayButtonTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.tabTrayButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenTabTrayLongPressedThenGleanIsCalled() throws {
        subject?.tabTrayButtonLongPressed(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.tabTrayLongPress)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.tabTrayLongPress.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenMenuTappedThenGleanIsCalled() throws {
        subject?.menuButtonTapped(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.appMenuButtonTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.appMenuButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenDataClearanceTappedThenGleanIsCalled() throws {
        subject?.dataClearanceButtonTapped(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.dataClearanceButtonTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.dataClearanceButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }
}
