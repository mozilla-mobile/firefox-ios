// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class EngagementNotificationTests: BaseTestCase {
    var currentScreen = 0
    var rootA11yId: String {
        return "\(AccessibilityIdentifiers.Onboarding.onboarding)\(currentScreen)"
    }

    override func setUp() {
        launchArguments = [LaunchArguments.ClearProfile,
                           LaunchArguments.LoadExperiment, "engagementNotificationWithoutConditions"]
        super.setUp()
    }

    func testShowingNotification() {
        goThroughOnboarding()

        // As we cannot trigger the background refresh 
        XCUIDevice.shared.press(XCUIDevice.Button.home)

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let notification = springboard.otherElements["Notification"]
        XCTAssertTrue(notification.waitForExistence(timeout: 150)) // implicit wait
        notification.tap()

        let urlField = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.searchTextField]
        waitForExistence(urlField)
        sleep(1)
    }

    // MARK: Helper

    private func allowNotifications () {
        addUIInterruptionMonitor(withDescription: "notifications") { (alert) -> Bool in
            alert.buttons["Allow"].tap()
            return true
        }
        app.swipeDown()
    }

    private func goThroughOnboarding() {
        // Complete the First run from first screen to the latest one
        // Check that the first's tour screen is shown as well as all the elements in there
        waitForExistence(app.images["\(rootA11yId)ImageView"], timeout: 15)
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(AccessibilityIdentifiers.Onboarding.closeButton)"].exists)

        // Go to the second screen
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        currentScreen += 1
        waitForExistence(app.images["\(rootA11yId)ImageView"], timeout: 15)
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)SecondaryButton"].exists)

        // Go to the third screen
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        sleep(3)
        allowNotifications()

        currentScreen += 1
        waitForExistence(app.images["\(rootA11yId)ImageView"], timeout: 15)
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)SecondaryButton"].exists)

        // Finish onboarding
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
    }
}
