// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class OnboardingTests: BaseTestCase {
    var currentScreen = 0
    var rootA11yId: String {
        return "\(AccessibilityIdentifiers.Onboarding.onboarding)\(currentScreen)"
    }

    override func setUp() {
        launchArguments = [LaunchArguments.ClearProfile]
        currentScreen = 0
        super.setUp()
    }

    // Smoketest
    // https://testrail.stage.mozaws.net/index.php?/cases/view/471228
    func testFirstRunTour() {
        // Complete the First run from first screen to the latest one
        // Check that the first's tour screen is shown as well as all the elements in there
        waitForExistence(app.images["\(rootA11yId)ImageView"], timeout: 15)
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)TitleLabel"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)DescriptionLabel"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)SecondaryButton"].exists)
        XCTAssertTrue(app.buttons["\(AccessibilityIdentifiers.Onboarding.closeButton)"].exists)
        XCTAssertTrue(app.pageIndicators["\(AccessibilityIdentifiers.Onboarding.pageControl)"].exists)

        // Swipe to the second screen
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        waitForExistence(app.images["\(rootA11yId)ImageView"], timeout: 15)
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)TitleLabel"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)DescriptionLabel"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)SecondaryButton"].exists)

        // Swipe to the third screen
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        waitForExistence(app.images["\(rootA11yId)ImageView"], timeout: 15)
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)TitleLabel"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)DescriptionLabel"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)SecondaryButton"].exists)

        // Finish onboarding
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        let topSites = app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        waitForExistence(topSites)
    }

    // Smoketest
    // https://testrail.stage.mozaws.net/index.php?/cases/view/2250844
    func testCloseTour() {
        app.buttons["\(AccessibilityIdentifiers.Onboarding.closeButton)"].tap()
        let topSites = app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        waitForExistence(topSites)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/67227
    func testWhatsNewPage() {
        app.buttons["\(AccessibilityIdentifiers.Onboarding.closeButton)"].tap()
        navigator.goto(BrowserTabMenu)
        navigator.performAction(Action.OpenWhatsNewPage)
        waitUntilPageLoad()

        // Extract version number from url
        let url = app.textFields["url"].value
        let textUrl = String(describing: url)
        let start = textUrl.index(textUrl.startIndex, offsetBy: 43)
        let end = textUrl.index(textUrl.startIndex, offsetBy: 48)
        let range = start..<end
        let mySubstring = textUrl[range]
        let releaseVersion = String(mySubstring)

        XCTAssertTrue(app.staticTexts[releaseVersion].exists)
        waitForValueContains(app.textFields["url"], value: "www.mozilla.org/en-US/firefox/ios/" + releaseVersion + "/releasenotes/")
        XCTAssertTrue(app.staticTexts["Release Notes"].exists)
        if iPad() {
            XCTAssertTrue(app.staticTexts["Firefox for iOS \(releaseVersion), See All New Features, Updates and Fixes"].exists)
        }
        XCTAssertTrue(app.staticTexts["Firefox for iOS Release"].exists)
        XCTAssertTrue(app.staticTexts["Get the most recent version"].exists)
    }
}
