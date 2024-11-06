// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class MainMenuTelemetryTests: XCTestCase {
    var subject: MainMenuTelemetry?
    let isHomepageKey = "is_homepage"
    let optionKey = "option"

    override func setUp() {
        super.setUp()
        Glean.shared.resetGlean(clearStores: true)
        subject = MainMenuTelemetry()
    }

    func testRecordMainMenuWhenOptionTappedThenGleanIsCalled() throws {
        subject?.optionTapped(with: true, and: "test_option")
        testEventMetricRecordingSuccess(metric: GleanMetrics.AppMenu.mainMenuOptionSelected)

        let resultValue = try XCTUnwrap(GleanMetrics.AppMenu.mainMenuOptionSelected.testGetValue())
        XCTAssertEqual(resultValue[0].extra?[optionKey], "test_option")
        XCTAssertEqual(resultValue[0].extra?[isHomepageKey], "true")
    }

    func testRecordMainMenuWhenCloseButtonTappedThenGleanIsCalled() throws {
        subject?.closeButtonTapped(isHomepage: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.AppMenu.closeButton)

        let resultValue = try XCTUnwrap(GleanMetrics.AppMenu.closeButton.testGetValue())
        XCTAssertEqual(resultValue[0].extra?[isHomepageKey], "true")
    }

    func testRecordMainMenuWhenMenuIsDismissedThenGleanIsCalled() throws {
        subject?.menuDismissed(isHomepage: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.AppMenu.menuDismissed)

        let resultValue = try XCTUnwrap(GleanMetrics.AppMenu.menuDismissed.testGetValue())
        XCTAssertEqual(resultValue[0].extra?[isHomepageKey], "true")
    }
}
