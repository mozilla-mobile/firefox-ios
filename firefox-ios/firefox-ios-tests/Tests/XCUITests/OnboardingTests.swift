// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

class OnboardingTests: BaseTestCase {
    var currentScreen = 0
    var rootA11yId: String {
        return "\(AccessibilityIdentifiers.Onboarding.onboarding)\(currentScreen)"
    }
    var onboardingScreen: OnboardingScreen!
    var firefoxHomePageScreen: FirefoxHomePageScreen!
    var settingsScreen: SettingScreen!

    override func setUp() async throws {
        launchArguments = [LaunchArguments.ClearProfile,
                           LaunchArguments.DisableAnimations,
                           LaunchArguments.SkipSplashScreenExperiment]
        currentScreen = 0
        try await super.setUp()
        onboardingScreen = OnboardingScreen(app: app)
        firefoxHomePageScreen = FirefoxHomePageScreen(app: app)
        settingsScreen = SettingScreen(app: app)
    }

    override func tearDown() async throws {
        // Skip theme switching for FirefoxBeta since test exits early
        if isFirefoxBeta {
            app.terminate()
            try await super.tearDown()
            return
        }

        if #available(iOS 17.0, *) {
            if self.name.contains("testSelectBottomPlacement")
                || self.name.contains("testValidateContinueButton")
                || iPad() {
                // Toolbar option not available for iPad, so the theme is not changed there.
                return
            } else {
                switchThemeToDarkOrLight(theme: "Light")
            }
        }
        app.terminate()
        try await super.tearDown()
    }

    // Smoketest TAE
    // https://mozilla.testrail.io/index.php?/cases/view/2575178
    func testFirstRunTour() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }

        // Handle initial gate (ToS for Fennec, Continue for Firefox/Beta)
        onboardingScreen.handleFirstRunGate(isFirefoxBeta: isFirefoxBeta, isFirefox: isFirefox)

        // Firefox Beta has a different onboarding flow and exits early
        if isFirefoxBeta {
            onboardingScreen.completeBetaOnboardingFlow()
            // Beta test exits here - no verification needed
            return
        }

        // Complete the standard onboarding tour (Firefox/Fennec)
        onboardingScreen.completeStandardOnboardingFlow(isIPad: iPad())

        // Verify we landed on homepage with TopSites
        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2793818
    func testFirstRunTourDarkMode() {
        waitForElementsToExist([app.buttons["TermsOfService.AgreeAndContinueButton"]])
        app.buttons["TermsOfService.AgreeAndContinueButton"].tap()

        app.buttons["CloseButton"].waitAndTap()
        // Dismiss new changes pop up if exists
        app.buttons["Close"].tapIfExists()
        switchThemeToDarkOrLight(theme: "Dark")
        app.terminate()
        app.launch()
        // Check that the first's tour screen is shown as well as all the elements in there
        navigator.nowAt(FirstRun)
        waitForElementsToExist([app.buttons["TermsOfService.AgreeAndContinueButton"]])
        app.buttons["TermsOfService.AgreeAndContinueButton"].tap()

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
        app.buttons["\(rootA11yId)SecondaryButton"].waitAndTap()
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
        app.buttons["\(rootA11yId)SecondaryButton"].waitAndTap()
        currentScreen += 1
        mozWaitForElementToExist(app.images["\(rootA11yId)ImageView"], timeout: TIMEOUT)
        XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)TitleLabel"].exists)
        XCTAssertTrue(app.staticTexts["\(rootA11yId)DescriptionLabel"].exists)
        XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
        XCTAssertFalse(app.buttons["\(rootA11yId)SecondaryButton"].exists)

        // Swipe to the fifth screen
        if !iPad() {
            app.buttons["\(rootA11yId)PrimaryButton"].waitAndTap()
            currentScreen += 1
            mozWaitForElementToExist(app.images["\(rootA11yId)ImageView"], timeout: TIMEOUT)
            XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
            XCTAssertTrue(app.staticTexts["\(rootA11yId)TitleLabel"].exists)
            XCTAssertTrue(app.staticTexts["\(rootA11yId)DescriptionLabel"].exists)
            XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
            XCTAssertFalse(app.buttons["\(rootA11yId)SecondaryButton"].exists)
        }

        // Finish onboarding
        let topSites = app.collectionViews.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        app.buttons["\(rootA11yId)PrimaryButton"].waitAndTap()
        // Dismiss new changes pop up if exists
        app.buttons["Close"].tapIfExists()
        mozWaitForElementToExist(topSites)
    }

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/2306814
    func testOnboardingSignIn() {
        waitForElementsToExist([app.buttons["TermsOfService.AgreeAndContinueButton"]])
        app.buttons["TermsOfService.AgreeAndContinueButton"].tap()

        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        // Swipe to the second screen
        app.buttons["\(rootA11yId)SecondaryButton"].waitAndTap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        XCTAssertEqual("Stay encrypted when you hop between devices", app.staticTexts["\(rootA11yId)TitleLabel"].label)
        XCTAssertEqual("Firefox encrypts your passwords, bookmarks, and more when you’re synced.",
                       app.staticTexts["\(rootA11yId)DescriptionLabel"].label)
        XCTAssertEqual("Sign In", app.buttons["\(rootA11yId)PrimaryButton"].label)
        XCTAssertEqual("Skip", app.buttons["\(rootA11yId)SecondaryButton"].label)
        // Tap on Sign In
        app.buttons["\(rootA11yId)PrimaryButton"].waitAndTap()
        mozWaitForElementToExist(app.navigationBars["Sync and Save Data"])
        XCTAssertTrue(app.buttons["QRCodeSignIn.button"].exists)
        XCTAssertEqual("Ready to Scan", app.buttons["QRCodeSignIn.button"].label)
        XCTAssertTrue(app.buttons["EmailSignIn.button"].exists)
        XCTAssertEqual("Use Email Instead", app.buttons["EmailSignIn.button"].label)
        app.buttons["Done"].waitAndTap()
        app.buttons["CloseButton"].waitAndTap()
    }

    // Smoketest TAE
    // https://mozilla.testrail.io/index.php?/cases/view/2306814
    func testOnboardingSignIn_TAE() {
        let onboardingScreen = OnboardingScreen(app: app)

        onboardingScreen.agreeAndContinue()
        onboardingScreen.swipeToNextScreen()

        onboardingScreen.assertTextsOnCurrentScreen(
            expectedTitle: "Stay encrypted when you hop between devices",
            expectedDescription: "Firefox encrypts your passwords, bookmarks, and more when you’re synced.",
            expectedPrimary: "Sign In",
            expectedSecondary: "Skip"
        )

        onboardingScreen.tapSignIn()
        onboardingScreen.assertSignInScreen()
        onboardingScreen.exitSignInFlow()
    }

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/2306816
    func testCloseTour() {
        waitForElementsToExist([app.buttons["TermsOfService.AgreeAndContinueButton"]])
        app.buttons["TermsOfService.AgreeAndContinueButton"].tap()

        app.buttons["\(AccessibilityIdentifiers.Onboarding.closeButton)"].waitAndTap()
        // Dismiss new changes pop up if exists
        app.buttons["Close"].tapIfExists()
        let topSites = app.collectionViews.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        mozWaitForElementToExist(topSites)
    }

    // Smoketest TAE
    // https://mozilla.testrail.io/index.php?/cases/view/2306816
    func testCloseTour_TAE() {
        onboardingScreen.agreeAndContinue()
        onboardingScreen.closeTourIfNeeded()
        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    // TOOLBAR THEME
    // https://mozilla.testrail.io/index.php?/cases/view/2575175
    func testSelectTopPlacement() {
        waitForElementsToExist([app.buttons["TermsOfService.AgreeAndContinueButton"]])
        app.buttons["TermsOfService.AgreeAndContinueButton"].tap()

        let toolbar = app.textFields["url"]

        // Wait for the initial title label to appear
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])

        app.buttons["\(rootA11yId)SecondaryButton"].waitAndTap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        app.buttons["\(rootA11yId)SecondaryButton"].waitAndTap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        app.buttons["\(rootA11yId)SecondaryButton"].waitAndTap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        if !iPad() {
            app.buttons["\(rootA11yId)PrimaryButton"].waitAndTap()
            currentScreen += 1
        }

        let buttons = app.buttons.matching(identifier: "\(rootA11yId)MultipleChoiceButton")
        for i in 0..<buttons.count {
            let button = buttons.element(boundBy: i)
            if button.label == "Top" {
                button.waitAndTap()
                break
            }
        }
        if !iPad() {
            app.buttons["Save and Start Browsing"].waitAndTap()
        } else {
            app.buttons["Save and Continue"].waitAndTap()
        }
        let topSites = app.collectionViews.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        mozWaitForElementToExist(topSites)
        // Dismiss new changes pop up if exists
        app.buttons["Close"].tapIfExists()

        // Check if the toolbar exists
        if toolbar.exists {
            // Get the screen height
            let screenHeight = app.windows.element(boundBy: 0).frame.height

            XCTAssertTrue(toolbar.frame.origin.y < screenHeight / 2, "Toolbar is not near the top")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2575176
    func testSelectBottomPlacement() throws {
        if iPad() {
            let shouldSkipTest = true
            try XCTSkipIf(shouldSkipTest, "Toolbar option not available for iPad")
        }
        waitForElementsToExist([app.buttons["TermsOfService.AgreeAndContinueButton"]])
        app.buttons["TermsOfService.AgreeAndContinueButton"].tap()
        let toolbar = app.textFields["url"]

        // Wait for the initial title label to appear
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])

        app.buttons["\(rootA11yId)SecondaryButton"].waitAndTap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        app.buttons["\(rootA11yId)SecondaryButton"].waitAndTap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        app.buttons["\(rootA11yId)SecondaryButton"].waitAndTap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        app.buttons["\(rootA11yId)PrimaryButton"].waitAndTap()
        currentScreen += 1

        let buttons = app.buttons.matching(identifier: "\(rootA11yId)MultipleChoiceButton")
        for i in 0..<buttons.count {
            let button = buttons.element(boundBy: i)
            if button.label == "Bottom" {
                button.waitAndTap()
                break
            }
        }

        app.buttons["Save and Start Browsing"].waitAndTap()
        let topSites = app.collectionViews.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        mozWaitForElementToExist(topSites)
        // Dismiss new changes pop up if exists
        app.buttons["Close"].tapIfExists()

        // Check if the toolbar exists
        if toolbar.exists {
            // Get the screen height
            let screenHeight = app.windows.element(boundBy: 0).frame.height

            XCTAssertFalse(toolbar.frame.origin.y < screenHeight / 2, "Toolbar is not near the bottom")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2575177
    func testCloseOptionToolbarCard() {
        waitForElementsToExist([app.buttons["TermsOfService.AgreeAndContinueButton"]])
        app.buttons["TermsOfService.AgreeAndContinueButton"].tap()

        // Wait for the initial title label to appear
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])

        app.buttons["\(rootA11yId)SecondaryButton"].waitAndTap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        app.buttons["\(rootA11yId)SecondaryButton"].waitAndTap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        app.buttons["\(rootA11yId)SecondaryButton"].waitAndTap()
        currentScreen += 1
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        if !iPad() {
            app.buttons["\(rootA11yId)PrimaryButton"].waitAndTap()
        }
        app.buttons["CloseButton"].waitAndTap()
        let topSites = app.collectionViews.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        mozWaitForElementToExist(topSites)
    }

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/3193571
    func testValidateContinueButton() {
        let onboardingScreen = OnboardingScreen(app: app)

        onboardingScreen.assertContinueButtonIsOnTheBottom()
        onboardingScreen.agreeAndContinue()
        onboardingScreen.waitForCurrentScreenElements()
        onboardingScreen.closeTourIfNeeded()
        navigator.goto(SettingsScreen)
        navigator.nowAt(SettingsScreen)
        settingsScreen.assertSendTechicalDataIsOn()
        settingsScreen.assertSendCrashReportsIsOn()
    }
}
