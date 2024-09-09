// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class EngagementNotificationTests: BaseTestCase {
    override func setUp() {
        // Fresh install the app
        // removeApp() does not work on iOS 15 and 16 intermittently
        if #available(iOS 17, *) {
            removeApp()
        }
        // The app is correctly installed
        super.setUp()
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
        let tipsSwitch = app.switches["TipsAndFeaturesNotificationsUserPrefsKey"]
        mozWaitForElementToExist(tipsSwitch)
        app.switches["TipsAndFeaturesNotificationsUserPrefsKey"].tap()
        let springBoard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let popUpTitle = "Would Like to Send You Notifications"
        // Validate pop-up
        mozWaitForElementToExist(springBoard.alerts.elementContainingText(popUpTitle))
        // Choose "Don't allow"
        springBoard.buttons["Don’t Allow"].tap()
        // Toggle moves back to the "Off" position
        mozWaitForValueContains(tipsSwitch, value: "0")
        // Validate You turned off all Firefox notifications message
        let notificationMessage1 = "You turned off all Firefox notifications. "
        let notificationMessage2 = "Turn them on by going to device Settings > Notifications > Firefox"
        // Workaround to validate message due to https://github.com/mozilla-mobile/firefox-ios/issues/13790
        mozWaitForElementToNotExist(app.staticTexts[notificationMessage1 + notificationMessage2])
        navigator.goto(SettingsScreen)
        navigator.goto(NotificationsSettings)
        mozWaitForElementToExist(app.staticTexts[notificationMessage1 + notificationMessage2])
    }
}
