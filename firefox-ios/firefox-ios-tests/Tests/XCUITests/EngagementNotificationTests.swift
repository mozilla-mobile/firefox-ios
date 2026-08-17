// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class EngagementNotificationTests: BaseTestCase {
    var notificationsSettingsScreen: NotificationsSettingsScreen!
    var springboardScreen: SpringboardScreen!

    override func setUp() async throws {
        // Fresh install the app
        // removeApp() does not work on iOS 15 and 16 intermittently
        if #available(iOS 17, *) {
            removeApp()
        }
        // The app is correctly installed
        try await super.setUp()

        notificationsSettingsScreen = NotificationsSettingsScreen(app: app)
        springboardScreen = SpringboardScreen()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307101
    func testDontAllowNotifications() throws {
        if #unavailable(iOS 17) {
            throw XCTSkip("setUp() fails to remove app intermittently")
        }
        // Skip login
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        // Navigate to "Tips and Features"
        // Toggle on switch position
        navigator.goto(NotificationsSettings)
        notificationsSettingsScreen.assertTipsAndFeaturesSwitchExists()
        notificationsSettingsScreen.tapTipsAndFeaturesSwitch()
        // Validate pop-up
        springboardScreen.assertNotificationsPermissionAlertExists()
        // Choose "Don't allow"
        springboardScreen.tapDontAllowNotifications()
        // Toggle moves back to the "Off" position
        notificationsSettingsScreen.assertTipsAndFeaturesSwitchIsOff()
        // Validate You turned off all Firefox notifications message
        // Workaround to validate message due to https://github.com/mozilla-mobile/firefox-ios/issues/13790
        notificationsSettingsScreen.assertSystemNotificationsDisabledMessageNotExists()
        navigator.goto(SettingsScreen)
        navigator.goto(NotificationsSettings)
        notificationsSettingsScreen.assertSystemNotificationsDisabledMessageExists()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307102
    // Regression
    func testAllowNotifications() throws {
        if #unavailable(iOS 17) {
            throw XCTSkip("setUp() fails to remove app intermittently")
        }
        // Skip login
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        // Navigate to "Tips and Features"
        // Toggle on switch position
        navigator.goto(NotificationsSettings)
        notificationsSettingsScreen.assertTipsAndFeaturesSwitchExists()
        notificationsSettingsScreen.tapTipsAndFeaturesSwitch()
        // Validate pop-up
        springboardScreen.assertNotificationsPermissionAlertExists()
        // Choose "Allow"
        springboardScreen.tapAllowNotifications()
        // Toggle moves back to the "On" position
        notificationsSettingsScreen.assertTipsAndFeaturesSwitchIsOn()
        // Notifications are granted, so the system notifications disabled message is not displayed
        notificationsSettingsScreen.assertSystemNotificationsDisabledMessageNotExists()
        // The preference is persisted, so the toggle is still on when the screen is reopened
        navigator.goto(SettingsScreen)
        navigator.goto(NotificationsSettings)
        notificationsSettingsScreen.assertTipsAndFeaturesSwitchIsOn()
    }
}
