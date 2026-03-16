// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

/// Tests for the modern onboarding flow (enable-modern-ui feature flag)
/// Modern onboarding has 4 main screens: Welcome, Toolbar, Theme, Sync
/// Plus an optional Terms of Service screen if not previously accepted
///
/// **NOTE**: These tests almost precisely mirror those in `ModernKitOnboardingTests.swift`
///
class ModernOrangeAndBlueOnboardingTests: FeatureFlaggedTestSuite {
    // We just test the modern orange and blue onboarding flow in this file
    let flowType = OnboardingScreen.OnboardingFlowType.modernOrangeAndBlue

    var onboardingScreen: OnboardingScreen!
    var firefoxHomePageScreen: FirefoxHomePageScreen!

    override func setUpExperimentVariables() {
        launchArguments = [
            LaunchArguments.ClearProfile,
            LaunchArguments.DisableAnimations,
            LaunchArguments.SkipSplashScreenExperiment
        ]

        jsonFileName = flowType.jsonFeatureOverrideFileName
        featureName = flowType.onboardingFeatureName
    }

    override func setUp() async throws {
        try await super.setUp()

        onboardingScreen = OnboardingScreen(app: app, flowType: flowType)
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

        onboardingScreen.handleTermsOfService()

        onboardingScreen.completeOnboardingFlow(isIpad: iPad())

        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    // Smoketest
    func testModernOnboardingFullFlowToSAlreadyAccepted() throws {
        launchApp()

        // TODO: Pre-accept ToS via launch argument instead of accepting inline
        onboardingScreen.handleTermsOfService()

        onboardingScreen.completeOnboardingFlow(isIpad: iPad())

        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    // MARK: - Individual Screen Tests

    func testModernTermsOfServiceScreen() throws {
        launchApp()

        onboardingScreen.assertModernTermsOfServiceScreen()
    }

    func testModernOnboardingWelcomeScreen() throws {
        launchApp()

        onboardingScreen.handleTermsOfService()
        onboardingScreen.assertModernWelcomeScreen()
    }

    func testModernOnboardingToolbarPlacementTop() throws {
        if iPad() {
            throw XCTSkip("Toolbar customization is not available on iPad")
        }

        launchApp()

        onboardingScreen.handleTermsOfService()

        // Wait for the initial onboarding screen title label to appear
        onboardingScreen.assertTitle()

        onboardingScreen.goToNextScreenViaSecondary()
        onboardingScreen.assertTitle()

        // Address bar choice is onboarding flow screen 2
        onboardingScreen.selectAddressBarPosition(position: .top)
        onboardingScreen.goToNextScreenViaPrimary()
        onboardingScreen.assertTitle()

        // Exit onboarding early after the address bar position has been chosen
        onboardingScreen.closeTour()

        // Check Home screen is visible
        firefoxHomePageScreen.assertTopSitesItemCellExist()
        firefoxHomePageScreen.dismissNewChangesPopupIfNeeded()

        // Assert position of the toolbar
        // TODO: Migrate to TAE
        let toolbar = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].firstMatch
        waitForElementsToExist([toolbar])

        let screenHeight = app.windows.element(boundBy: 0).frame.height
        XCTAssertTrue(toolbar.frame.origin.y < screenHeight / 2, "Toolbar is not near the top")
    }

    func testModernOnboardingToolbarPlacementBottom() throws {
        if iPad() {
            throw XCTSkip("Toolbar customization is not available on iPad")
        }

        launchApp()

        onboardingScreen.handleTermsOfService()

        // Wait for the initial onboarding screen title label to appear
        onboardingScreen.assertTitle()

        onboardingScreen.goToNextScreenViaSecondary()
        onboardingScreen.assertTitle()

        // Address bar choice is onboarding flow screen 2
        onboardingScreen.selectAddressBarPosition(position: .bottom)
        onboardingScreen.goToNextScreenViaPrimary()
        onboardingScreen.assertTitle()

        // Exit onboarding early after the address bar position has been chosen
        onboardingScreen.closeTour()

        // Check Home screen is visible
        firefoxHomePageScreen.assertTopSitesItemCellExist()
        firefoxHomePageScreen.dismissNewChangesPopupIfNeeded()

        // Assert position of the toolbar
        // TODO: Migrate to TAE
        let toolbar = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].firstMatch
        waitForElementsToExist([toolbar])

        let screenHeight = app.windows.element(boundBy: 0).frame.height
        XCTAssertFalse(toolbar.frame.origin.y < screenHeight / 2, "Toolbar is not near the bottom")
    }

    func testModernOnboardingThemeSelection() throws {
        launchApp()

        onboardingScreen.handleTermsOfService()

        // Screen 1: Default Browser - Skip (secondary button)
        onboardingScreen.assertTitle()
        onboardingScreen.goToNextScreenViaSecondary()

        if iPad() {
            // iPad does not show the address bar top/bottom placement card (second screen).
            // However, the accessibility IDs increase by one.
            onboardingScreen.currentScreen += 1
        } else {
            // Screen 2: Choose address bar - Continue (primary button)
            onboardingScreen.assertTitle()
            onboardingScreen.goToNextScreenViaPrimary()
        }

        // Screen 3: Choose theme - Continue (primary button)
        onboardingScreen.assertModernThemeCustomizationScreen()

        onboardingScreen.selectThemeButtons()

        onboardingScreen.selectTheme("System Auto")
        onboardingScreen.goToNextScreenViaPrimary()
    }

    // MARK: - Sync Flow Tests

    func testModernOnboardingSyncFlow() throws {
        launchApp()

        onboardingScreen.handleTermsOfService()

        // Screen 1: Default Browser - Skip (secondary button)
        onboardingScreen.assertTitle()
        onboardingScreen.goToNextScreenViaSecondary()

        if iPad() {
            // iPad does not show the address bar top/bottom placement card (second screen).
            // However, the accessibility IDs increase by one.
            onboardingScreen.currentScreen += 1
        } else {
            // Screen 2: Choose address bar - Continue (primary button)
            onboardingScreen.assertTitle()
            onboardingScreen.selectAddressBarPosition(position: .bottom)
            onboardingScreen.goToNextScreenViaPrimary()
        }

        // Screen 3: Choose theme - Continue (primary button)
        onboardingScreen.assertTitle()
        onboardingScreen.selectTheme("System Auto")
        onboardingScreen.goToNextScreenViaPrimary()

        // Screen 4: Sign in to sync - Not now (secondary button)
        onboardingScreen.assertSyncScreen()

        // Sign in overlay interaction
        onboardingScreen.tapSignIn()
        onboardingScreen.assertSignInScreen()
        onboardingScreen.exitSignInFlow()
    }

    func testModernOnboardingSkipSync() throws {
        launchApp()

        onboardingScreen.handleTermsOfService()
        onboardingScreen.currentScreen = 0

        onboardingScreen.goToNextScreenViaSecondary()

        if !iPad() {
            onboardingScreen.selectToolbarPosition("Bottom")
            onboardingScreen.goToNextScreenViaPrimary()
        } else {
            onboardingScreen.currentScreen += 1
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

        onboardingScreen.handleTermsOfService()

        onboardingScreen.closeTour()

        firefoxHomePageScreen.dismissNewChangesPopupIfNeeded()
        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    func testModernOnboardingSecondaryNavigation() throws {
        launchApp()

        onboardingScreen.handleTermsOfService()
        onboardingScreen.currentScreen = 0

        onboardingScreen.assertModernWelcomeScreen()

        let secondaryButton = app.buttons["\(onboardingScreen.rootA11yId)SecondaryButton"]
        secondaryButton.waitAndTap()
        if !iPad() {
            onboardingScreen.currentScreen += 1
        } else {
            onboardingScreen.currentScreen += 2
        }

        // Should be on toolbar (iPhone) or theme (iPad) screen
        if iPad() {
            onboardingScreen.assertModernThemeCustomizationScreen()
        } else {
            onboardingScreen.assertToolbarCustomizationScreen()
        }
    }

    // MARK: - Accessibility Tests

    func testModernOnboardingAccessibility() throws {
        launchApp()

        onboardingScreen.assertModernTermsOfServiceScreen()

        onboardingScreen.handleTermsOfService()

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

        onboardingScreen.handleTermsOfService()
        onboardingScreen.currentScreen = 0
        onboardingScreen.goToNextScreenViaSecondary()

        let topButton = app.buttons["\(onboardingScreen.rootA11yId)SegmentedButton.Top"]
        let bottomButton = app.buttons["\(onboardingScreen.rootA11yId)SegmentedButton.Bottom"]

        XCTAssertTrue(topButton.exists, "Should have 'Top' option")
        XCTAssertTrue(bottomButton.exists, "Should have 'Bottom' option")

        onboardingScreen.selectToolbarPosition("Top")

        onboardingScreen.selectToolbarPosition("Bottom")
    }

    // MARK: Skipping Onboarding with Close Button
    func testModernOnboardingCloseOptionLastCard() {
        onboardingScreen.handleTermsOfService()

        // Wait for the initial title label to appear
        onboardingScreen.assertTitle()

        // Go to second screen
        onboardingScreen.goToNextScreenViaSecondary()
        onboardingScreen.assertTitle()

        // Go to third screen
        onboardingScreen.goToNextScreenViaPrimary()
        onboardingScreen.assertTitle()

        // Go to fourth (last) screen
        onboardingScreen.goToNextScreenViaPrimary()
        onboardingScreen.assertTitle()

        // Test closing the tour at the very last card using the X
        onboardingScreen.closeTour()

        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }
}
