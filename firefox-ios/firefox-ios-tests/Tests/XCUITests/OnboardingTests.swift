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

    override func tearDown() {
        if #available(iOS 17.0, *) {
            switchThemeToDarkOrLight(theme: "Light")
        }
        app.terminate()
        super.tearDown()
    }

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/2575178
    func testFirstRunTour() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }

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
        try app.performAccessibilityAudit()

        // Swipe to the second screen
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        waitForElementsToExist(
            [
                app.images["\(rootA11yId)ImageView"],
                app.staticTexts["\(rootA11yId)TitleLabel"],
                app.staticTexts["\(rootA11yId)DescriptionLabel"],
                app.buttons["\(rootA11yId)PrimaryButton"],
            ]
        )
        try app.performAccessibilityAudit()

        // Swipe to the third screen
        app.buttons["\(rootA11yId)SecondaryButton"].waitAndTap()
        currentScreen += 1
        mozWaitForElementToExist(app.images["\(rootA11yId)ImageView"])
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)TitleLabel"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)DescriptionLabel"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)SecondaryButton"].exists)
        try app.performAccessibilityAudit()

        // Swipe to the fourth screen
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.images["\(rootA11yId)ImageView"], timeout: TIMEOUT)
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)TitleLabel"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)DescriptionLabel"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)SecondaryButton"].exists)
        try app.performAccessibilityAudit()

        // Swipe to the fifth screen
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.images["\(rootA11yId)ImageView"], timeout: TIMEOUT)
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)TitleLabel"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)DescriptionLabel"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)SecondaryButton"].exists)
        try app.performAccessibilityAudit()

        // Finish onboarding
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        let topSites = app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        mozWaitForElementToExist(topSites)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2793818
    func testFirstRunTourDarkMode() {
        app.buttons["CloseButton"].tap()
        switchThemeToDarkOrLight(theme: "Dark")
        app.terminate()
        app.launch()
        // Check that the first's tour screen is shown as well as all the elements in there
        navigator.nowAt(FirstRun)
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
                app.buttons["\(rootA11yId)PrimaryButton"]
            ]
        )

        // Swipe to the third screen
        app.buttons["\(rootA11yId)SecondaryButton"].waitAndTap()
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
        mozWaitForElementToExist(app.images["\(rootA11yId)ImageView"], timeout: TIMEOUT)
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)TitleLabel"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)DescriptionLabel"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)SecondaryButton"].exists)

        // Swipe to the fifth screen
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.images["\(rootA11yId)ImageView"], timeout: TIMEOUT)
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)TitleLabel"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)DescriptionLabel"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)SecondaryButton"].exists)

        // Finish onboarding
        let topSites = app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        mozWaitForElementToExist(topSites)
    }

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/2306814
    func testOnboardingSignIn() {
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        // Swipe to the second screen
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        XCTAssertEqual("Stay encrypted when you hop between devices", app.staticTexts["\(rootA11yId)TitleLabel"].label)
        // Tap on Sign In
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        mozWaitForElementToExist(app.navigationBars["Sync and Save Data"])
        XCTAssertTrue(app.buttons["QRCodeSignIn.button"].exists)
        XCTAssertEqual("Ready to Scan", app.buttons["QRCodeSignIn.button"].label)
        XCTAssertTrue(app.buttons["EmailSignIn.button"].exists)
        XCTAssertEqual("Use Email Instead", app.buttons["EmailSignIn.button"].label)
        app.buttons["Done"].tap()
        app.buttons["CloseButton"].tap()
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
        app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].tap()

        // Extract version number from url
        let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].value
        let textUrl = String(describing: url)
        let start = textUrl.index(textUrl.startIndex, offsetBy: 51)
        let end = textUrl.index(textUrl.startIndex, offsetBy: 56)
        let range = start..<end
        let mySubstring = textUrl[range]
        let releaseVersion = String(mySubstring)

        mozWaitForElementToExist(app.staticTexts[releaseVersion])
        mozWaitForValueContains(
            app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField],
            value: "https://www.mozilla.org/en-US/firefox/ios/" + releaseVersion + "/releasenotes/"
        )
        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].tap()
        waitForElementsToExist(
            [
                app.staticTexts["Release Notes"],
                app.staticTexts["Firefox for iOS Release"],
                app.staticTexts["\(releaseVersion)"],
                app.staticTexts["Get the most recent version"]
            ]
        )
    }

    // TOOLBAR THEME
    // https://mozilla.testrail.io/index.php?/cases/view/2575175
    func testSelectTopPlacement() {
        let toolbar = app.textFields["url"]

        // Wait for the initial title label to appear
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])

        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        currentScreen += 1

        let buttons = app.buttons.matching(identifier: "\(rootA11yId)MultipleChoiceButton")
        for i in 0..<buttons.count {
            let button = buttons.element(boundBy: i)
            if button.label == "Top" {
                button.tap()
                break
            }
        }

        app.buttons["Save and Start Browsing"].waitAndTap()
        let topSites = app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        mozWaitForElementToExist(topSites)

        // Check if the toolbar exists
        if toolbar.exists {
            // Get the screen height
            let screenHeight = app.windows.element(boundBy: 0).frame.height

            XCTAssertTrue(toolbar.frame.origin.y < screenHeight / 2, "Toolbar is not near the top")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2575176
    func testSelectBottomPlacement() throws {
        guard !iPad() else {
            throw XCTSkip("Toolbar option not available for iPad")
        }
        let toolbar = app.textFields["url"]

        // Wait for the initial title label to appear
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])

        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        currentScreen += 1

        let buttons = app.buttons.matching(identifier: "\(rootA11yId)MultipleChoiceButton")
        for i in 0..<buttons.count {
            let button = buttons.element(boundBy: i)
            if button.label == "Bottom" {
                button.tap()
                break
            }
        }

        app.buttons["Save and Start Browsing"].waitAndTap()
        let topSites = app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        mozWaitForElementToExist(topSites)

        // Check if the toolbar exists
        if toolbar.exists {
            // Get the screen height
            let screenHeight = app.windows.element(boundBy: 0).frame.height

            XCTAssertFalse(toolbar.frame.origin.y < screenHeight / 2, "Toolbar is not near the bottom")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2575177
    func testCloseOptionToolbarCard() {
        // Wait for the initial title label to appear
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])

        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        app.buttons["CloseButton"].waitAndTap()
        let topSites = app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        mozWaitForElementToExist(topSites)
    }
}
