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

    var flowType: OnboardingScreen.OnboardingFlowType {
        if isFirefoxBeta {
            return .modernOrangeAndBlue
        } else if isFirefox {
            return .modernKit
        }

        return .old
    }

    override func setUp() async throws {
        launchArguments = [LaunchArguments.ClearProfile,
                           LaunchArguments.DisableAnimations,
                           LaunchArguments.SkipSplashScreenExperiment]
        currentScreen = 0
        try await super.setUp()
        onboardingScreen = OnboardingScreen(app: app, flowType: flowType)
        firefoxHomePageScreen = FirefoxHomePageScreen(app: app)
        settingsScreen = SettingScreen(app: app)
    }

    override func tearDown() async throws {
        app.terminate()
        try await super.tearDown()
    }

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/2575178
    func testFirstRunTour() throws {
        guard #available(iOS 17.0, *), !skipPlatform else {
            throw XCTSkip("Skipping first run tour")
        }

        onboardingScreen.handleTermsOfService()

        // Firefox and FirefoxBeta have a different onboarding flow
        if flowType.isModernFlow {
            onboardingScreen.completeFirefoxBetaOnboardingFlow()
        } else {
            onboardingScreen.completeStandardOnboardingFlow(isIPad: iPad())
        }

        // Dismiss new changes pop up if exists
        onboardingScreen.dismissNewChangesPopup()
        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2793818
    func testFirstRunTourDarkMode() {
        onboardingScreen.handleTermsOfService()
        onboardingScreen.closeTourIfNeeded()

        switchThemeToDarkOrLight(theme: "Dark")

        app.terminate()
        app.launch()

        // Check that the first tour screen is shown as well as all the elements in there
        /// FYI: Due to Bug FXIOS-14759, modern onboarding reverts to **old onboarding** after app restart.
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
        firefoxHomePageScreen.assertTopSitesItemCellExist() // FIXME: Test this
        let topSites = app.collectionViews.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        app.buttons["\(rootA11yId)PrimaryButton"].waitAndTap()
        // Dismiss new changes pop up if exists
        app.buttons["Close"].tapIfExists()
        mozWaitForElementToExist(topSites)
    }

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/2306814
    func testOnboardingSignIn() throws {
        onboardingScreen.handleTermsOfService()

        // FIXME: is this true for the Kit flow also?
        if flowType.isModernFlow {
            // In the new modern onboarding flows, the sign-in screen is in position 3. Swipe past 3 screens then sign in.
            onboardingScreen.goToNextScreenViaSecondary()
            onboardingScreen.goToNextScreenViaPrimary()
            onboardingScreen.goToNextScreenViaPrimary()

            onboardingScreen.assertTextsOnCurrentScreen(
                expectedTitle: "Instantly pick up where you left off",
                expectedDescription: "Get your bookmarks, history, and passwords on any device.",
                expectedPrimary: "Start Syncing",
                expectedSecondary: "Not now"
            )
        } else {
            // Sign-in is on the second screen after ToS. Swipe past first screen, and then test sign in on the second
            onboardingScreen.goToNextScreenViaSecondary()

            onboardingScreen.assertTextsOnCurrentScreen(
                expectedTitle: "Stay encrypted when you hop between devices",
                expectedDescription: "Firefox encrypts your passwords, bookmarks, and more when you’re synced.",
                expectedPrimary: "Sign In",
                expectedSecondary: "Skip"
            )
        }

        onboardingScreen.tapSignIn()
        onboardingScreen.assertSignInScreen()
        onboardingScreen.exitSignInFlow()
    }

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/2306816
    func testCloseTour() {
        onboardingScreen.handleTermsOfService()
        onboardingScreen.closeTourIfNeeded()
        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    // TOOLBAR THEME
    // https://mozilla.testrail.io/index.php?/cases/view/2575175
    func testSelectTopPlacement() {
        onboardingScreen.handleTermsOfService()

        let toolbar = app.textFields["url"]

        // Wait for the initial title label to appear
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])

        onboardingScreen.goToNextScreenViaSecondary()
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])

        onboardingScreen.goToNextScreenViaSecondary()
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])

        onboardingScreen.goToNextScreenViaSecondary()
        mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
        if !iPad() {
            onboardingScreen.goToNextScreenViaPrimary()
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
        onboardingScreen.assertContinueButtonIsOnTheBottom()
        onboardingScreen.handleTermsOfService()
        onboardingScreen.waitForCurrentScreenElements()
        onboardingScreen.closeTourIfNeeded()
        navigator.goto(SettingsScreen)
        navigator.nowAt(SettingsScreen)
        settingsScreen.assertSendTechicalDataIsOn()
        settingsScreen.assertSendCrashReportsIsOn()
    }
}
