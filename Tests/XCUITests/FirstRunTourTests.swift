// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class FirstRunTourTests: BaseTestCase {
    var currentScreen = 0
    var rootA11yId: String {
        return "\(AccessibilityIdentifiers.Onboarding.onboarding)\(currentScreen)."
    }

    override func setUp() {
        launchArguments = [LaunchArguments.ClearProfile]
        currentScreen = 0
        super.setUp()
    }

    // Smoketest
    func testFirstRunTour() {
        // Complete the First run from first screen to the latest one
        // Check that the first's tour screen is shown as well as all the elements in there
        print("RGB - \(app.debugDescription)")
        waitForExistence(app.staticTexts["Welcome to an independent internet"], timeout: 15)

        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.textViews["\(rootA11yId)TitleLabel"].exists)
        XCTAssertTrue(app.textViews["\(rootA11yId)DescriptionLabel"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(AccessibilityIdentifiers.Onboarding.closeButton)"].exists)
        XCTAssertTrue(app.pageIndicators["\(AccessibilityIdentifiers.Onboarding.pageControl)"].exists)

        // Swipe to the second screen
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        currentScreen += 1
        waitForExistence(app.staticTexts["Hop from phone to laptop and back"])
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)SecondaryButton"].exists)
    }

    func testCloseTour() {
        app.buttons["\(AccessibilityIdentifiers.Onboarding.closeButton)"].tap()
        let topSites = app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        waitForExistence(topSites)
    }

    // MARK: Private
    private func goToNextScreen() {
        waitForExistence(app.buttons["\(rootA11yId)PrimaryButton"], timeout: 10)
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        currentScreen += 1
    }

    private func tapStartBrowsingButton() {
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        // User starts in HomePanelScreen with the default Top Sites
        let topSites = app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        waitForExistence(topSites)
    }
}
