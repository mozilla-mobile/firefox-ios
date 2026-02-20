// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

/// Tests for the modern onboarding flow (enable-modern-ui feature flag)
/// Modern onboarding has 4 main screens: Welcome, Toolbar, Theme, Sync
/// Plus an optional Terms of Service screen if not previously accepted
class ModernOnboardingTests: FeatureFlaggedTestSuite {
    var onboardingScreen: OnboardingScreen!
    var firefoxHomePageScreen: FirefoxHomePageScreen!

    override func setUpExperimentVariables() {
        jsonFileName = "modernOnboardingOn"
        featureName = "onboarding-framework-feature"

        launchArguments = [
            LaunchArguments.ClearProfile,
            LaunchArguments.DisableAnimations,
            LaunchArguments.SkipSplashScreenExperiment
        ]
    }

    override func setUp() async throws {
        try await super.setUp()

        onboardingScreen = OnboardingScreen(app: app)
        firefoxHomePageScreen = FirefoxHomePageScreen(app: app)
    }

    override func tearDown() async throws {
        app.terminate()
        try await super.tearDown()
    }

    // MARK: - Full Flow Tests

    // Smoketest
    func testModernOnboardingFullFlowWithToS() throws {
        launchApp()

        onboardingScreen.assertModernTermsOfServiceScreen()
        onboardingScreen.acceptModernTermsOfService()

        onboardingScreen.completeModernOnboardingFlow(isIPad: iPad(), tosAccepted: true)

        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    // Smoketest
    func testModernOnboardingFullFlowToSAlreadyAccepted() throws {
        launchApp()

        // TODO: Pre-accept ToS via launch argument instead of accepting inline
        onboardingScreen.acceptModernTermsOfService()

        onboardingScreen.currentScreen = 0

        onboardingScreen.completeModernOnboardingFlow(isIPad: iPad(), tosAccepted: true)

        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    // MARK: - Individual Screen Tests

    func testModernTermsOfServiceScreen() throws {
        launchApp()

        let tosRoot = AccessibilityIdentifiers.TermsOfService.root

        let title = app.staticTexts["\(tosRoot)TitleLabel"]
        let description = app.staticTexts["\(tosRoot)DescriptionLabel"]
        let button = app.buttons["\(tosRoot)PrimaryButton"]

        mozWaitForElementToExist(title)
        XCTAssertTrue(title.exists, "ToS title should exist")
        XCTAssertTrue(description.exists, "ToS description should exist")
        XCTAssertTrue(button.exists, "ToS button should exist")

        XCTAssertEqual(title.label, "Welcome to Firefox", "Should show correct title")
        XCTAssertEqual(button.label, "Continue", "Should show Continue button")
    }

    func testModernOnboardingWelcomeScreen() throws {
        launchApp()

        onboardingScreen.acceptModernTermsOfService()

        onboardingScreen.currentScreen = 0

        let title = app.staticTexts["\(onboardingScreen.rootA11yId)TitleLabel"]
        let description = app.staticTexts["\(onboardingScreen.rootA11yId)DescriptionLabel"]
        let primaryButton = app.buttons["\(onboardingScreen.rootA11yId)PrimaryButton"]
        let secondaryButton = app.buttons["\(onboardingScreen.rootA11yId)SecondaryButton"]

        mozWaitForElementToExist(primaryButton)
        XCTAssertTrue(title.exists, "Welcome title should exist")
        XCTAssertTrue(description.exists, "Welcome description should exist")
        XCTAssertTrue(primaryButton.exists, "Primary button should exist")
        XCTAssertTrue(secondaryButton.exists, "Secondary button should exist")
    }

    func testModernOnboardingToolbarSelection() throws {
        if iPad() {
            throw XCTSkip("Toolbar customization is not available on iPad")
        }

        launchApp()

        onboardingScreen.acceptModernTermsOfService()
        onboardingScreen.currentScreen = 0

        onboardingScreen.goToNextScreen()

        onboardingScreen.assertToolbarCustomizationScreen()

        onboardingScreen.selectToolbarPosition("Top")

        onboardingScreen.goToNextScreenViaPrimary()

        onboardingScreen.assertThemeCustomizationScreen()
    }

    func testModernOnboardingThemeSelection() throws {
        launchApp()

        onboardingScreen.acceptModernTermsOfService()
        onboardingScreen.currentScreen = 0

        onboardingScreen.goToNextScreen()

        if !iPad() {
            onboardingScreen.selectToolbarPosition("Bottom")
            onboardingScreen.goToNextScreenViaPrimary()
        }

        onboardingScreen.assertThemeCustomizationScreen()

        let themes = ["System Auto", "Light", "Dark"]
        for theme in themes {
            onboardingScreen.selectTheme(theme)
        }

        onboardingScreen.selectTheme("System Auto")
        onboardingScreen.goToNextScreenViaPrimary()

        onboardingScreen.assertSyncScreen()
    }

    // MARK: - Sync Flow Tests

    func testModernOnboardingSyncFlow() throws {
        launchApp()

        onboardingScreen.acceptModernTermsOfService()
        onboardingScreen.currentScreen = 0

        onboardingScreen.goToNextScreen()

        if !iPad() {
            onboardingScreen.selectToolbarPosition("Bottom")
            onboardingScreen.goToNextScreenViaPrimary()
        }

        onboardingScreen.selectTheme("System Auto")
        onboardingScreen.goToNextScreenViaPrimary()

        onboardingScreen.assertSyncScreen()

        let primaryButton = app.buttons["\(onboardingScreen.rootA11yId)PrimaryButton"]
        primaryButton.waitAndTap()

        mozWaitForElementToExist(app.navigationBars["Sync and Save Data"])
        XCTAssertTrue(app.buttons["QRCodeSignIn.button"].exists)
        XCTAssertTrue(app.buttons["EmailSignIn.button"].exists)

        app.buttons["Done"].waitAndTap()
    }

    func testModernOnboardingSkipSync() throws {
        launchApp()

        onboardingScreen.acceptModernTermsOfService()
        onboardingScreen.currentScreen = 0

        onboardingScreen.goToNextScreen()

        if !iPad() {
            onboardingScreen.selectToolbarPosition("Bottom")
            onboardingScreen.goToNextScreenViaPrimary()
        }

        onboardingScreen.selectTheme("System Auto")
        onboardingScreen.goToNextScreenViaPrimary()

        onboardingScreen.assertSyncScreen()

        let secondaryButton = app.buttons["\(onboardingScreen.rootA11yId)SecondaryButton"]
        secondaryButton.waitAndTap()

        app.buttons["Close"].tapIfExists()

        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    // MARK: - Navigation Tests

    func testModernOnboardingSkipButton() throws {
        launchApp()

        onboardingScreen.acceptModernTermsOfService()

        let skipButton = app.buttons[AccessibilityIdentifiers.Onboarding.closeButton]
        mozWaitForElementToExist(skipButton)
        XCTAssertTrue(skipButton.exists, "Skip button should exist")

        skipButton.waitAndTap()

        app.buttons["Close"].tapIfExists()

        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    func testModernOnboardingSecondaryNavigation() throws {
        launchApp()

        onboardingScreen.acceptModernTermsOfService()
        onboardingScreen.currentScreen = 0

        onboardingScreen.assertModernWelcomeScreen()

        let secondaryButton = app.buttons["\(onboardingScreen.rootA11yId)SecondaryButton"]
        secondaryButton.waitAndTap()
        onboardingScreen.currentScreen += 1

        // Should be on toolbar (iPhone) or theme (iPad) screen
        if iPad() {
            onboardingScreen.assertThemeCustomizationScreen()
        } else {
            onboardingScreen.assertToolbarCustomizationScreen()
        }
    }

    // MARK: - Accessibility Tests

    func testModernOnboardingAccessibility() throws {
        launchApp()

        let tosRoot = AccessibilityIdentifiers.TermsOfService.root
        XCTAssertTrue(app.staticTexts["\(tosRoot)TitleLabel"].exists)
        XCTAssertTrue(app.staticTexts["\(tosRoot)DescriptionLabel"].exists)
        XCTAssertTrue(app.buttons["\(tosRoot)PrimaryButton"].exists)

        onboardingScreen.acceptModernTermsOfService()
        onboardingScreen.currentScreen = 0

        mozWaitForElementToExist(app.buttons["\(onboardingScreen.rootA11yId)PrimaryButton"])
        XCTAssertTrue(app.staticTexts["\(onboardingScreen.rootA11yId)TitleLabel"].exists)
        XCTAssertTrue(app.staticTexts["\(onboardingScreen.rootA11yId)DescriptionLabel"].exists)
        XCTAssertTrue(app.buttons["\(onboardingScreen.rootA11yId)PrimaryButton"].exists)
        XCTAssertTrue(app.buttons["\(onboardingScreen.rootA11yId)SecondaryButton"].exists)

        // Test page control exists (CustomPageControl is rendered as otherElements, not pageIndicators)
        let pageControl = app.otherElements[AccessibilityIdentifiers.Onboarding.pageControl]
        XCTAssertTrue(pageControl.exists, "Page control should exist")
    }

    // MARK: - Multiple Choice UI Tests

    func testModernOnboardingMultipleChoiceUI() throws {
        if iPad() {
            throw XCTSkip("Toolbar customization is not available on iPad")
        }

        launchApp()

        onboardingScreen.acceptModernTermsOfService()
        onboardingScreen.currentScreen = 0
        onboardingScreen.goToNextScreen()

        let topButton = app.buttons["\(onboardingScreen.rootA11yId)SegmentedButton.Top"]
        let bottomButton = app.buttons["\(onboardingScreen.rootA11yId)SegmentedButton.Bottom"]

        XCTAssertTrue(topButton.exists, "Should have 'Top' option")
        XCTAssertTrue(bottomButton.exists, "Should have 'Bottom' option")

        onboardingScreen.selectToolbarPosition("Top")

        onboardingScreen.selectToolbarPosition("Bottom")
    }
}
