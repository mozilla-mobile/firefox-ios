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
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to put them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
        subject = MainMenuTelemetry()
    }

    func testRecordMainMenuWhenMainMenuOptionTappedThenGleanIsCalled() throws {
        subject?.mainMenuOptionTapped(with: true, and: "test_option")
        testEventMetricRecordingSuccess(metric: GleanMetrics.AppMenu.mainMenuOptionSelected)

        let resultValue = try XCTUnwrap(GleanMetrics.AppMenu.mainMenuOptionSelected.testGetValue())
        XCTAssertEqual(resultValue[0].extra?[optionKey], "test_option")
        XCTAssertEqual(resultValue[0].extra?[isHomepageKey], "true")
    }

    func testRecordMainMenuWhenSaveSubmenuOptionTappedThenGleanIsCalled() throws {
        subject?.saveSubmenuOptionTapped(with: true, and: "test_option")
        testEventMetricRecordingSuccess(metric: GleanMetrics.AppMenu.saveMenuOptionSelected)

        let resultValue = try XCTUnwrap(GleanMetrics.AppMenu.saveMenuOptionSelected.testGetValue())
        XCTAssertEqual(resultValue[0].extra?[optionKey], "test_option")
        XCTAssertEqual(resultValue[0].extra?[isHomepageKey], "true")
    }

    func testRecordMainMenuWhenToolsSubmenuOptionTappedThenGleanIsCalled() throws {
        subject?.toolsSubmenuOptionTapped(with: true, and: "test_option")
        testEventMetricRecordingSuccess(metric: GleanMetrics.AppMenu.toolsMenuOptionSelected)

        let resultValue = try XCTUnwrap(GleanMetrics.AppMenu.toolsMenuOptionSelected.testGetValue())
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
