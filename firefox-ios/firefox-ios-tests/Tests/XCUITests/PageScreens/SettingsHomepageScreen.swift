// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class SettingsHomepageScreen {
    private let app: XCUIApplication
    private let sel: SettingsHomepageSelectorsSet

    init(app: XCUIApplication, selectors: SettingsHomepageSelectorsSet = SettingsHomepageSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func assertDefaultOptionsVisible() {
        BaseTestCase().waitForElementsToExist([
            sel.NAVBAR.element(in: app),
            sel.START_AT_HOME_ALWAYS.element(in: app),
            sel.START_AT_HOME_DISABLED.element(in: app)
        ])
        BaseTestCase().mozWaitForElementToExist(sel.START_AT_HOME_AFTER_4H.element(in: app))
    }

    /// Selects "Homepage" in the Opening screen section, i.e. Start at Home set to always.
    func selectHomepageAsOpeningScreen() {
        sel.START_AT_HOME_ALWAYS.element(in: app).waitAndTap()
        assertHomepageIsSelectedAsOpeningScreen()
    }

    func assertHomepageIsSelectedAsOpeningScreen() {
        let homepageOption = sel.START_AT_HOME_ALWAYS.element(in: app)
        BaseTestCase().mozWaitForElementToExist(homepageOption)
        // The checkmark is applied on a table reload, so the selected state settles asynchronously
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isSelected == true"),
            object: homepageOption
        )
        XCTAssertEqual(
            XCTWaiter().wait(for: [expectation], timeout: TIMEOUT),
            .completed,
            "Homepage is not selected as the opening screen"
        )
    }

    /// Below iOS 17 the Stories row is never added to Homepage settings, see
    /// https://github.com/mozilla-mobile/firefox-ios/issues/35618. Fails once the bug is fixed.
    func assertStoriesSwitchIsAbsent(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(sel.NAVBAR.element(in: app))
        XCTAssertFalse(
            sel.STORIES_SWITCH.element(in: app).mozWaitForElementToExist(timeout: timeout, failOnTimeout: false),
            "Stories switch is present below iOS 17. Issue #35618 looks fixed, remove the version guard."
        )
    }

    func assertStoriesSwitch(isOn expected: Bool) {
        let sw = sel.STORIES_SWITCH.element(in: app)
        BaseTestCase().mozWaitForElementToExist(sw)
        let value = (sw.value as? String) ?? ""
        XCTAssertEqual(value, expected ? "1" : "0", "Stories switch expected to be \(expected ? "ON" : "OFF")")
    }
}
