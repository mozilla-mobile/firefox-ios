// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

class OnboardingTests: BaseTestCase {
    var onboardingScreen: OnboardingScreen!
    var firefoxHomePageScreen: FirefoxHomePageScreen!
    var settingsScreen: SettingScreen!

    var flowType: OnboardingScreen.OnboardingFlowType {
        if isFirefoxBeta {
            return .modernOrangeAndBlue
        } else if isFirefox {
            return .modernKit
        }

        return .legacy
    }

    override func setUp() async throws {
        launchArguments = [LaunchArguments.ClearProfile,
                           LaunchArguments.DisableAnimations,
                           LaunchArguments.SkipSplashScreenExperiment]
        try await super.setUp()
        onboardingScreen = OnboardingScreen(app: app, flowType: flowType)
        firefoxHomePageScreen = FirefoxHomePageScreen(app: app)
        settingsScreen = SettingScreen(app: app)
    }

    override func tearDown() async throws {
        app.terminate()
        try await super.tearDown()
    }

    // MARK: Test Complete Flow
    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/2575178
    func testFirstRunTour() throws {
        guard #available(iOS 17.0, *), !skipPlatform else {
            throw XCTSkip("Skipping first run tour")
        }

        onboardingScreen.handleTermsOfService()

        // Firefox and FirefoxBeta have a different onboarding flow
        if flowType.isModernFlow {
            onboardingScreen.completeFirefoxModernOnboardingFlow()
        } else {
            onboardingScreen.completeLegacyOnboardingFlow(isIPad: iPad())
        }

        firefoxHomePageScreen.assertTopSitesItemCellExist()
        firefoxHomePageScreen.dismissNewChangesPopupIfNeeded()
    }

    // MARK: Testing Dark Mode
    // https://mozilla.testrail.io/index.php?/cases/view/2793818
    func testFirstRunTourDarkMode() throws {
        if flowType.isModernFlow {
            throw XCTSkip("Incomplete implementation for modern flows (see TODO below)")
        }

        onboardingScreen.handleTermsOfService()
        onboardingScreen.closeTour()
        firefoxHomePageScreen.dismissNewChangesPopupIfNeeded()

        switchThemeToDarkOrLight(theme: "Dark")

        app.terminate()
        app.launch()
        navigator.nowAt(FirstRun)

        /// FYI: Due to Bug FXIOS-14759, modern onboarding reverts to **old onboarding** after app restart.
        onboardingScreen.handleTermsOfService()

        if flowType.isModernFlow {
            // TODO: Test rail needs update for modern flows
            // TODO: Update and check actual title and texts instead of existence
            // Early abort for now until implementation is complete.
            throw XCTSkip("Incomplete implementation")
        } else {
            // TODO: This test needs to be fully migrated to the TAE pattern.
            // Then currentScreen and rootA11yId won't be needed.
            var currentScreen = 0
            var rootA11yId: String {
                return "\(AccessibilityIdentifiers.Onboarding.onboarding)\(currentScreen)"
            }

            // Check the first screen
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

            // Swipe to and check the second screen
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

            // Swipe to and check the third screen
            app.buttons["\(rootA11yId)SecondaryButton"].waitAndTap()
            currentScreen += 1
            mozWaitForElementToExist(app.images["\(rootA11yId)ImageView"])
            XCTAssertTrue(app.images["\(rootA11yId)ImageView"].exists)
            XCTAssertTrue(app.staticTexts["\(rootA11yId)TitleLabel"].exists)
            XCTAssertTrue(app.staticTexts["\(rootA11yId)DescriptionLabel"].exists)
            XCTAssertTrue(app.buttons["\(rootA11yId)PrimaryButton"].exists)
            XCTAssertTrue(app.buttons["\(rootA11yId)SecondaryButton"].exists)

            // Swipe to and check the fourth screen
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
            app.buttons["\(rootA11yId)PrimaryButton"].waitAndTap()
        }

        firefoxHomePageScreen.assertTopSitesItemCellExist()
        firefoxHomePageScreen.dismissNewChangesPopupIfNeeded()
    }

    // MARK: Testing Sign In
    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/2306814
    func testOnboardingSignIn() throws {
        onboardingScreen.handleTermsOfService()

        if flowType.isModernFlow {
            // In the new modern onboarding flows, the sign-in screen is in position 3. Swipe past 3 screens then sign in.
            onboardingScreen.goToNextScreenViaSecondary()
            onboardingScreen.goToNextScreenViaPrimary()
            onboardingScreen.goToNextScreenViaPrimary()

            // There are textual differences between the flows
            let expectedDescription: String
            let expectedSecondary: String
            switch flowType {
            case .modernOrangeAndBlue:
                expectedDescription = "Get your bookmarks, history, and passwords on any device."
                expectedSecondary = "Not now"
            case .modernKit:
                // swiftlint:disable line_length
                expectedDescription = "Grab bookmarks, passwords, and more on any device in a snap. Your personal data stays safe and secure with encryption."
                expectedSecondary = "Not Now"
                // swiftlint:enable line_length
            case .legacy:
                expectedDescription = "" // Unexpected path; should not happen
                expectedSecondary = ""
            }

            onboardingScreen.assertTextsOnCurrentScreen(
                expectedTitle: "Instantly pick up where you left off",
                expectedDescription: expectedDescription,
                expectedPrimary: "Start Syncing",
                expectedSecondary: expectedSecondary
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
        firefoxHomePageScreen.dismissNewChangesPopupIfNeeded()
        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    // MARK: Toolbar Position
    // https://mozilla.testrail.io/index.php?/cases/view/2575175
    func testSelectAddressBarTopPlacement() {
        onboardingScreen.handleTermsOfService()

        // Wait for the initial onboarding screen title label to appear
        onboardingScreen.assertTitle()

        if flowType.isModernFlow {
            onboardingScreen.goToNextScreenViaSecondary()
            onboardingScreen.assertTitle()

            // Address bar choice is onboarding flow screen 2
            onboardingScreen.selectAddressBarPosition(position: .top)
            onboardingScreen.goToNextScreenViaPrimary()
            onboardingScreen.assertTitle()

            // Exit onboarding early after the address bar position has been chosen
            onboardingScreen.closeTour()
        } else {
            onboardingScreen.goToNextScreenViaSecondary()
            onboardingScreen.assertTitle()

            onboardingScreen.goToNextScreenViaSecondary()
            onboardingScreen.assertTitle()

            onboardingScreen.goToNextScreenViaSecondary()
            onboardingScreen.assertTitle()
            if !iPad() {
                onboardingScreen.goToNextScreenViaPrimary()
            }

            onboardingScreen.selectAddressBarPosition(position: .top)

            if !iPad() {
                app.buttons["Save and Start Browsing"].waitAndTap()
            } else {
                app.buttons["Save and Continue"].waitAndTap()
            }
        }

        firefoxHomePageScreen.assertTopSitesItemCellExist()
        firefoxHomePageScreen.dismissNewChangesPopupIfNeeded()

        // Assert position of the toolbar
        // TODO: Migrate to TAE
        let toolbar = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].firstMatch
        waitForElementsToExist([toolbar])

        let screenHeight = app.windows.element(boundBy: 0).frame.height
        XCTAssertTrue(toolbar.frame.origin.y < screenHeight / 2, "Toolbar is not near the top")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2575176
    func testSelectAddressBarBottomPlacement() throws {
        onboardingScreen.handleTermsOfService()

        // Wait for the initial onboarding screen title label to appear
        onboardingScreen.assertTitle()

        if flowType.isModernFlow {
            onboardingScreen.goToNextScreenViaSecondary()
            onboardingScreen.assertTitle()

            // Address bar choice is onboarding flow screen 2
            onboardingScreen.selectAddressBarPosition(position: .bottom)
            onboardingScreen.goToNextScreenViaPrimary()
            onboardingScreen.assertTitle()

            // Exit onboarding early after the address bar position has been chosen
            onboardingScreen.closeTour()
        } else {
            onboardingScreen.goToNextScreenViaSecondary()
            onboardingScreen.assertTitle()

            onboardingScreen.goToNextScreenViaSecondary()
            onboardingScreen.assertTitle()

            onboardingScreen.goToNextScreenViaSecondary()
            onboardingScreen.assertTitle()
            if !iPad() {
                onboardingScreen.goToNextScreenViaPrimary()
            }

            onboardingScreen.selectAddressBarPosition(position: .bottom)

            if !iPad() {
                app.buttons["Save and Start Browsing"].waitAndTap()
            } else {
                app.buttons["Save and Continue"].waitAndTap()
            }
        }

        firefoxHomePageScreen.assertTopSitesItemCellExist()
        firefoxHomePageScreen.dismissNewChangesPopupIfNeeded()

        // Assert position of the toolbar
        // TODO: Migrate to TAE
        let toolbar = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].firstMatch
        waitForElementsToExist([toolbar])

        let screenHeight = app.windows.element(boundBy: 0).frame.height
        XCTAssertFalse(toolbar.frame.origin.y < screenHeight / 2, "Toolbar is not near the bottom")
    }

    // MARK: Skipping Onboarding with Close Button
    // https://mozilla.testrail.io/index.php?/cases/view/2575177
    func testCloseOptionToolbarCard() {
        onboardingScreen.handleTermsOfService()

        // Wait for the initial title label to appear
        onboardingScreen.assertTitle()

        if flowType.isModernFlow {
            // Go to second screen
            onboardingScreen.goToNextScreenViaSecondary()
            onboardingScreen.assertTitle()

            // Go to third screen
            onboardingScreen.goToNextScreenViaPrimary()
            onboardingScreen.assertTitle()

            // Go to fourth (last) screen
            onboardingScreen.goToNextScreenViaPrimary()
            onboardingScreen.assertTitle()
        } else {
            // Go to second screen
            onboardingScreen.goToNextScreenViaSecondary()
            onboardingScreen.assertTitle()

            // Go to third screen
            onboardingScreen.goToNextScreenViaSecondary()
            onboardingScreen.assertTitle()

            // Go to fourth screen
            onboardingScreen.goToNextScreenViaSecondary()
            onboardingScreen.assertTitle()

            if !iPad() {
                // Go to fifth (last) screen
                onboardingScreen.goToNextScreenViaPrimary()
                onboardingScreen.assertTitle()
            }
        }

        // Test closing the tour at the very last card using the X
        onboardingScreen.closeTour()

        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    // MARK: ToS Acceptance Settings
    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/3193571
    func testValidateContinueButtonAndSettings() {
        onboardingScreen.assertContinueButtonIsOnTheBottom()
        onboardingScreen.handleTermsOfService()

        // Early exit onboarding after ToS are accepted
        onboardingScreen.assertTitle()
        onboardingScreen.closeTourIfNeeded()
        firefoxHomePageScreen.dismissNewChangesPopupIfNeeded()

        // Check for correct settings from ToS acceptance
        navigator.goto(SettingsScreen)
        navigator.nowAt(SettingsScreen)
        settingsScreen.assertSendTechicalDataIsOn()
        settingsScreen.assertSendCrashReportsIsOn()
    }
}
