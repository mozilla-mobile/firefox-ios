// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

/// Tests for the modern onboarding flow (enable-modern-ui feature flag)
/// Modern onboarding has 4 main screens: Welcome, Toolbar, Theme, Sync
/// Plus an optional Terms of Service screen if not previously accepted
///
/// **NOTE**: These tests almost precisely mirror those in `ModernOrangeAndBlueOnboardingTests.swift`
///
class ModernKitOnboardingTests: FeatureFlaggedTestSuite {
    // We just test the modern Kit rebranded flow in this file
    let flowType = OnboardingScreen.OnboardingFlowType.modernKit

    var onboardingScreen: OnboardingScreen!
    var firefoxHomePageScreen: FirefoxHomePageScreen!
    var settingScreen: SettingScreen!

    override func setUpExperimentVariables() {
        launchArguments = [
            LaunchArguments.ClearProfile,
            LaunchArguments.DisableAnimations
        ]

        jsonFileName = flowType.jsonFeatureOverrideFileName
        featureName = flowType.onboardingFeatureName
    }

    override func setUp() async throws {
        try await super.setUp()

        onboardingScreen = OnboardingScreen(app: app, flowType: flowType)
        firefoxHomePageScreen = FirefoxHomePageScreen(app: app)
        settingScreen = SettingScreen(app: app)
    }

    override func tearDown() async throws {
        app.terminate()
        try await super.tearDown()
    }

    // MARK: - Full Flow Tests

    // Smoketest
    func testModernKitOnboardingFullFlowWithToS() throws {
        launchApp()

        onboardingScreen.handleTermsOfService()

        onboardingScreen.completeOnboardingFlow(isIpad: iPad())

        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    // Smoketest
    func testModernKitOnboardingFullFlowToSAlreadyAccepted() throws {
        launchApp()

        // TODO: Pre-accept ToS via launch argument instead of accepting inline
        onboardingScreen.handleTermsOfService()

        onboardingScreen.completeOnboardingFlow(isIpad: iPad())

        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    // MARK: - Individual Screen Tests

    // https://mozilla.testrail.io/index.php?/cases/view/4035806
    func testModernTermsOfServiceScreen() {
        launchApp()

        onboardingScreen.assertModernTermsOfServiceScreen()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4035799
    func testModernTermsOfUseLinkDisplayAndDismissal() {
        verifyLinkDisplayAndDismissal(for: .termsOfUse)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4035800
    func testModernPrivacyNoticeLinkDisplayAndDismissal() {
        verifyLinkDisplayAndDismissal(for: .privacyNotice)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4035801
    func testModernManageBottomSheetDisplayAndDismissal() {
        verifyLinkDisplayAndDismissal(for: .manage)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4035796
    func testModernManageBottomSheetContent() {
        launchApp()

        // Step 1: The ToS onboarding card, including the Manage link, is displayed
        onboardingScreen.assertModernTermsOfServiceScreen()
        onboardingScreen.assertLinkIsDisplayed(.manage)

        // Step 2: Tapping Manage opens the bottom sheet showing all of its content
        onboardingScreen.tapLink(.manage)
        onboardingScreen.assertManageBottomSheetContents()
    }

    /// Shared flow for the ToS card link cases (C4035799–C4035801): tap link → overlay shown → force
    /// close hides it → backgrounding keeps it → Done dismisses it. iOS 26+ only (link tappability).
    private func verifyLinkDisplayAndDismissal(for link: OnboardingScreen.ToSLink) {
        launchApp()

        // Step 1: The ToS card, including the link, is displayed
        onboardingScreen.assertModernTermsOfServiceScreen()
        onboardingScreen.assertLinkIsDisplayed(link)

        // Step 2: Tapping the link displays its overlay
        onboardingScreen.tapLink(link)
        onboardingScreen.assertOverlayIsDisplayed(for: link)

        // Step 3: Force closing and resuming closes the overlay and shows the ToS card
        app.terminate()
        launchApp()
        onboardingScreen.assertModernTermsOfServiceScreen()
        onboardingScreen.assertOverlayIsClosed(for: link)

        // Step 4: Reopen the overlay; backgrounding and foregrounding keeps it displayed
        onboardingScreen.tapLink(link)
        onboardingScreen.assertOverlayIsDisplayed(for: link)
        restartInBackground()
        onboardingScreen.assertOverlayIsDisplayed(for: link)

        // Step 5: Dismissing via the Done button closes the overlay and shows the ToS card
        onboardingScreen.dismissOverlay(for: link)
        onboardingScreen.assertModernTermsOfServiceScreen()
        onboardingScreen.assertOverlayIsClosed(for: link)
    }

    func testModernKitOnboardingWelcomeScreen() throws {
        launchApp()

        onboardingScreen.handleTermsOfService()
        onboardingScreen.assertModernWelcomeScreen()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4035645
    func testModernKitOnboardingToolbarPlacementTop() throws {
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

    // https://mozilla.testrail.io/index.php?/cases/view/4038428
    func testModernKitOnboardingToolbarPlacementBottom() throws {
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

    // https://mozilla.testrail.io/index.php?/cases/view/4035640
    func testModernKitOnboardingThemeSelection() throws {
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

        // Screen 3: Choose theme - System Auto is the default selection
        onboardingScreen.assertModernThemeCustomizationScreen()
        onboardingScreen.assertDefaultThemeIsSystemAuto()

        // Keep the default (System Auto) and continue
        onboardingScreen.goToNextScreenViaPrimary()

        // Screen 4: Sign in to sync - Not now (secondary button) completes onboarding
        onboardingScreen.assertSyncScreen()
        onboardingScreen.goToNextScreenViaSecondary()

        // Homepage is reached with System Auto kept as the theme
        firefoxHomePageScreen.dismissNewChangesPopupIfNeeded()
        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3309013
    func testModernKitOnboardingCardsCopy() throws {
        launchApp()

        onboardingScreen.handleTermsOfService()

        // Card 1: Set as Default Browser
        onboardingScreen.assertTextsOnCurrentScreen(
            expectedTitle: "Open all your links with built-in privacy",
            expectedDescription: "We protect your data and automatically block companies from spying on your clicks.",
            expectedPrimary: "Set as Default Browser",
            expectedSecondary: "Not Now"
        )
        onboardingScreen.goToNextScreenViaSecondary()

        if iPad() {
            // iPad does not show the address bar card; a11y IDs still increase by one.
            onboardingScreen.currentScreen += 1
        } else {
            // Card 2: Choose your address bar (iPhone only) - advanced via the Continue primary button
            onboardingScreen.assertTextsOnCurrentScreen(
                expectedTitle: "Choose your address bar",
                expectedDescription: "Start typing to get search suggestions, your top sites, " +
                    "bookmarks, history and search engines – all in one place.",
                expectedPrimary: "Continue"
            )
            onboardingScreen.assertToolbarCustomizationScreen()
            onboardingScreen.goToNextScreenViaPrimary()
        }

        // Card 3: Pick your theme - advanced via the Continue primary button
        onboardingScreen.assertTextsOnCurrentScreen(
            expectedTitle: "Pick your theme",
            expectedDescription: "Pick your favorite theme or have Firefox match your device, putting you in control.",
            expectedPrimary: "Continue"
        )
        onboardingScreen.assertModernThemeCustomizationScreen()
        onboardingScreen.goToNextScreenViaPrimary()

        // Card 4: Instantly pick up where you left off (Sync)
        onboardingScreen.assertSyncScreen()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4035641
    func testModernKitOnboardingLightThemeSelection() throws {
        verifyThemeSelection(theme: "Light")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4035642
    func testModernKitOnboardingDarkThemeSelection() throws {
        verifyThemeSelection(theme: "Dark", restoreLightThemeAfterwards: true)
    }

    /// Shared flow for the theme selection cases (C4035641, C4035642): reach the theme card, select
    /// the given theme, confirm the Sync card is shown, then close the tour to reach the homepage.
    private func verifyThemeSelection(theme: String, restoreLightThemeAfterwards: Bool = false) {
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

        // Step 1: Reach the "Pick your theme" card
        onboardingScreen.assertModernThemeCustomizationScreen()

        // Step 2: Select the theme and tap Continue - the theme is applied, the card closes and the
        // next card (Sync) is displayed
        onboardingScreen.selectTheme(theme)
        onboardingScreen.assertThemeIsSelected(theme)
        onboardingScreen.goToNextScreenViaPrimary()
        onboardingScreen.assertSyncScreen()

        // Step 3: Close the onboarding tour - the homepage is reached with the theme applied
        onboardingScreen.closeTour()
        firefoxHomePageScreen.dismissNewChangesPopupIfNeeded()
        firefoxHomePageScreen.assertTopSitesItemCellExist()

        // Validate the theme was applied app-wide by checking Settings > Appearance reflects the choice
        assertAppearanceSettingReflects(theme: theme)

        // Restore Light theme from the Appearance screen so the test does not leave the device in Dark mode
        if restoreLightThemeAfterwards {
            settingScreen.selectLightTheme()
            settingScreen.assertLightThemeSelected()
        }
    }

    /// Opens Settings > Appearance and asserts the given theme is the selected option, confirming the
    /// onboarding choice was applied app-wide via ThemeManager rather than only on the card.
    private func assertAppearanceSettingReflects(theme: String) {
        navigator.nowAt(BrowserTab)
        navigator.goto(SettingsScreen)
        navigator.goto(DisplaySettings)
        settingScreen.assertAppearanceScreenIsShown()

        switch theme {
        case "Light":
            settingScreen.assertLightThemeSelected()
        case "Dark":
            settingScreen.assertDarkThemeSelected()
        default:
            XCTFail("Unsupported theme: \(theme)")
        }
    }

    // MARK: - Sync Flow Tests

    // https://mozilla.testrail.io/index.php?/cases/view/4036954
    func testModernKitOnboardingSyncFlow() throws {
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
        onboardingScreen.selectThemeButtons()
        onboardingScreen.goToNextScreenViaPrimary()

        // Screen 4: Sign in to sync - Not now (secondary button)
        onboardingScreen.assertSyncScreen()

        // Sign in overlay interaction
        onboardingScreen.tapSignIn()
        onboardingScreen.assertSignInScreen()
        onboardingScreen.exitSignInFlow()
    }

    func testModernKitOnboardingSkipSync() throws {
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

        onboardingScreen.selectThemeButtons()
        onboardingScreen.goToNextScreenViaPrimary()

        onboardingScreen.assertSyncScreen()

        let secondaryButton = app.buttons["\(onboardingScreen.rootA11yId)SecondaryButton"]
        secondaryButton.waitAndTap()

        app.buttons["Close"].tapIfExists()

        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    // MARK: - Navigation Tests

    // https://mozilla.testrail.io/index.php?/cases/view/4035643
    func testModernKitOnboardingSkipButton() {
        launchApp()

        onboardingScreen.handleTermsOfService()

        onboardingScreen.closeTour()

        firefoxHomePageScreen.dismissNewChangesPopupIfNeeded()
        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4038427
    func testModernKitOnboardingDefaultBrowserSkip() {
        launchApp()

        onboardingScreen.handleTermsOfService()

        // Step 1: The Set as Default Browser card (first onboarding card) is available
        onboardingScreen.assertModernWelcomeScreen()

        // Step 2: Tap Skip - the onboarding carousel closes and the homepage is displayed
        onboardingScreen.closeTour()
        firefoxHomePageScreen.dismissNewChangesPopupIfNeeded()
        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    func testModernKitOnboardingSecondaryNavigation() throws {
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

    func testModernKitOnboardingAccessibility() throws {
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

    func testModernKitOnboardingMultipleChoiceUI() throws {
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
    func testModernKitOnboardingCloseOptionLastCard() {
        launchApp()

        onboardingScreen.handleTermsOfService()

        // Wait for the initial title label to appear
        onboardingScreen.assertTitle()

        // Go to second screen
        onboardingScreen.goToNextScreenViaSecondary()
        if iPad() {
            onboardingScreen.currentScreen += 1
        }
        onboardingScreen.assertTitle()

        // Go to third screen
        onboardingScreen.goToNextScreenViaPrimary()
        onboardingScreen.assertTitle()

        // Go to fourth (last) screen
        if !iPad() {
            onboardingScreen.goToNextScreenViaPrimary()
            onboardingScreen.assertTitle()
        }

        // Test closing the tour at the very last card using the X
        onboardingScreen.closeTour()

        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }
}
