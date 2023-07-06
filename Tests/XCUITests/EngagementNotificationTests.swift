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
                           "\(LaunchArguments.LoadExperiment)engagementNotificationWithoutConditions"]
        super.setUp()
    }

    func testShowingNotification() throws {
        throw XCTSkip("This test passes only right after the simulator is erased")
        // goThroughOnboarding()

        // As we cannot trigger the background refresh 
        // XCUIDevice.shared.press(XCUIDevice.Button.home)

        // let notification = springboard.otherElements["Notification"]
        // XCTAssertTrue(notification.waitForExistence(timeout: TIMEOUT_LONG)) // implicit wait
        // notification.tap()

        // waitForExistence(app.textFields["url"])
        // let url = app.textFields["url"].value as! String
        // XCTAssertEqual(url, "mozilla.com", "Wrong url loaded")
    }

    // MARK: Helper

    private func goThroughOnboarding() {
        // Complete the First run from first screen to the latest one
        // Check that the first's tour screen is shown as well as all the elements in there
        waitForExistence(app.images["\(rootA11yId)ImageView"], timeout: TIMEOUT)
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(AccessibilityIdentifiers.Onboarding.closeButton)"].exists)

        // Go to the second screen
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        currentScreen += 1
        waitForExistence(app.images["\(rootA11yId)ImageView"], timeout: TIMEOUT)
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)SecondaryButton"].exists)

        // Go to the third screen
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        waitForExistence(app.images["\(rootA11yId)ImageView"], timeout: TIMEOUT)
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)SecondaryButton"].exists)

        // Finish onboarding
        app.buttons["\(rootA11yId)PrimaryButton"].tap()

        sleep(1)

        // Allow notifications
        if springboard.alerts.buttons["Allow"].exists {
            springboard.alerts.buttons["Allow"].tap()
        }

        let topSites = app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        waitForExistence(topSites)
    }
}
