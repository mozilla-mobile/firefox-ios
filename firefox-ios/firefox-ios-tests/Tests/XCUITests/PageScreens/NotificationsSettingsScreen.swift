// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class NotificationsSettingsScreen {
    private let app: XCUIApplication
    private let sel: NotificationsSettingsSelectorsSet

    init(app: XCUIApplication, selectors: NotificationsSettingsSelectorsSet = NotificationsSettingsSelectors()) {
        self.app = app
        self.sel = selectors
    }

    // MARK: - Elements

    private var tipsAndFeaturesSwitch: XCUIElement {
        sel.TIPS_AND_FEATURES_SWITCH.element(in: app)
    }

    private var systemNotificationsDisabledMessage: XCUIElement {
        sel.SYSTEM_NOTIFICATIONS_DISABLED_MESSAGE.element(in: app)
    }

    // MARK: - Actions

    func tapTipsAndFeaturesSwitch() {
        tipsAndFeaturesSwitch.waitAndTap()
    }

    // MARK: - Assertions

    func assertTipsAndFeaturesSwitchExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(tipsAndFeaturesSwitch, timeout: timeout)
    }

    func assertTipsAndFeaturesSwitchIsOn(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForValueContains(tipsAndFeaturesSwitch, value: "1", timeout: timeout)
    }

    func assertTipsAndFeaturesSwitchIsOff(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForValueContains(tipsAndFeaturesSwitch, value: "0", timeout: timeout)
    }

    func assertSystemNotificationsDisabledMessageExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(systemNotificationsDisabledMessage, timeout: timeout)
    }

    func assertSystemNotificationsDisabledMessageNotExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToNotExist(systemNotificationsDisabledMessage, timeout: timeout)
    }
}
