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
        launchArguments = [LaunchArguments.ClearProfile,
                           LaunchArguments.DisableAnimations,
                           LaunchArguments.SkipSplashScreenExperiment]
        currentScreen = 0
        super.setUp()
    }

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/2306814
    func testFirstRunTour() {
        // Complete the First run from first screen to the latest one
        // Check that the first's tour screen is shown as well as all the elements in there
        waitForElementsToExist(
            [
                app.images["\(rootA11yId)ImageView"],
                app.staticTexts["\(rootA11yId)TitleLabel"],
                app.staticTexts["\(rootA11yId)DescriptionLabel"],
                app.buttons["\(rootA11yId)PrimaryButton"],
                app.buttons["\(rootA11yId)SecondaryButton"],
                app.buttons["\(AccessibilityIdentifiers.Onboarding.closeButton)"],
                app.pageIndicators["\(AccessibilityIdentifiers.Onboarding.pageControl)"]
            ]
        )

        // Swipe to the second screen
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        waitForElementsToExist(
            [
                app.images["\(rootA11yId)ImageView"],
                app.staticTexts["\(rootA11yId)TitleLabel"],
                app.staticTexts["\(rootA11yId)DescriptionLabel"],
                app.buttons["\(rootA11yId)PrimaryButton"],
                app.buttons["\(rootA11yId)SecondaryButton"]
            ]
        )

        // Swipe to the third screen
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.images["\(rootA11yId)ImageView"])
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)TitleLabel"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)DescriptionLabel"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)SecondaryButton"].exists)

        // Swipe to the fourth screen
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.images["\(rootA11yId)ImageView"], timeout: 15)
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)TitleLabel"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)DescriptionLabel"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)SecondaryButton"].exists)

        // Swipe to the fifth screen
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.images["\(rootA11yId)ImageView"], timeout: 15)
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)TitleLabel"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)DescriptionLabel"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)SecondaryButton"].exists)

        // Finish onboarding
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        let topSites = app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        mozWaitForElementToExist(topSites)
    }

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/2306816
    func testCloseTour() {
        app.buttons["\(AccessibilityIdentifiers.Onboarding.closeButton)"].tap()
        let topSites = app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        mozWaitForElementToExist(topSites)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306815
    func testWhatsNewPage() {
        app.buttons["\(AccessibilityIdentifiers.Onboarding.closeButton)"].tap()
        navigator.goto(BrowserTabMenu)
        navigator.performAction(Action.OpenWhatsNewPage)
        waitUntilPageLoad()

        // Extract version number from url
        let url = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url].value
        let textUrl = String(describing: url)
        let start = textUrl.index(textUrl.startIndex, offsetBy: 43)
        let end = textUrl.index(textUrl.startIndex, offsetBy: 48)
        let range = start..<end
        let mySubstring = textUrl[range]
        let releaseVersion = String(mySubstring)

        mozWaitForElementToExist(app.staticTexts[releaseVersion])
        mozWaitForValueContains(
            app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url],
            value: "www.mozilla.org/en-US/firefox/ios/" + releaseVersion + "/releasenotes/"
        )
        mozWaitForElementToExist(app.staticTexts["Release Notes"])
        if iPad() {
            mozWaitForElementToExist(
                app.staticTexts["Firefox for iOS \(releaseVersion), See All New Features, Updates and Fixes"]
            )
        }
        waitForElementsToExist(
            [
                app.staticTexts["Firefox for iOS Release"],
                app.staticTexts["Get the most recent version"]
            ]
        )
    }
}
