// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class OnboardingScreen {
    /// Describes the onboarding flow. A different flow is shown depending app channel (Fennec, FirefoxBeta, and Firefox).
    /// **legacy**: The original onboarding with the first ToS screen. Simple backgrounds and hand-sketched imagery.
    /// **modernOrangeAndBlue**: New modern onboarding built in 2025. Vivid orange/pink/blue backgrounds around cards.
    /// **modernKit**: Rebranding of modernOrangeAndBlue built in 2026. Light pastel backgrounds with new Kit imagery.
    enum OnboardingFlowType {
        case legacy
        case modernOrangeAndBlue
        case modernKit

        /// Firefox and FirefoxBeta show a new modern onboarding UI with an alternative card flow compared to Fennec.
        var isModernFlow: Bool {
            switch self {
            case .legacy:
                return false
            case .modernOrangeAndBlue, .modernKit:
                return true
            }
        }

        /// The name of the feature flag governing which onboarding flow appears on launch.
        var onboardingFeatureName: String {
            return "onboarding-framework-feature"
        }

        /// Feature flag overrides for the onboarding feature. Will force a specific feature to show.
        var jsonFeatureOverrideFileName: String {
            switch self {
            case .legacy:
                return "legacyOnboardingOn"
            case .modernOrangeAndBlue:
                return "modernOrangeAndBlueOnboardingOn"
            case .modernKit:
                return "modernKitOnboardingOn"
            }
        }
    }

    // Address bar position is chosen on a card during onboarding. It can either be top or bottom.
    enum AddressBarPosition: String {
        case top = "Top"
        case bottom = "Bottom"
    }

    private let app: XCUIApplication
    private let sel: OnboardingSelectorsSet
    private let flowType: OnboardingFlowType

    var currentScreen = 0
    var rootA11yId: String {
        return "\(AccessibilityIdentifiers.Onboarding.onboarding)\(currentScreen)"
    }

    // MARK: Private computed properties for common elements
    /// Returns the primary button on the currentScreen.
    private var primaryButton: XCUIElement {
        switch flowType {
        case .legacy:
            return sel.primaryButton(rootId: rootA11yId).element(in: app)
        case .modernOrangeAndBlue, .modernKit:
            return sel.betaPrimaryButton(screenIndex: currentScreen).element(in: app)
        }
    }

    /// Returns the primary button on the currentScreen.
    private var secondaryButton: XCUIElement {
        switch flowType {
        case .legacy:
            return sel.secondaryButton(rootId: rootA11yId).element(in: app)
        case .modernOrangeAndBlue, .modernKit:
            return sel.betaSecondaryButton(screenIndex: currentScreen).element(in: app)
        }
    }

    private var tosContinueButton: XCUIElement {
        switch flowType {
        case .legacy:
            // Old onboarding shows the same "Continue" text, except with a different accessibility ID than modern flows.
            return sel.AGREE_AND_CONTINUE_BUTTON.element(in: app)

        case .modernOrangeAndBlue, .modernKit:
            // The modern onboarding flows have standardized the ToS primary button to match the other primary buttons.
            return sel.ONBOARDING_PRIMARY_BUTTON.element(in: app)
        }
    }

    init(
        app: XCUIApplication,
        flowType: OnboardingFlowType,
        selectors: OnboardingSelectorsSet = OnboardingSelectors()
    ) {
        self.app = app
        self.flowType = flowType
        self.sel = selectors
    }

    /// Handles the initial ToS screen based on app channel (Firefox Beta, Firefox, Fennec). ToS must be accepted before the
    /// onboarding flow begins.
    func handleTermsOfService() {
        BaseTestCase().mozWaitForElementToExist(tosContinueButton, timeout: TIMEOUT_LONG)
        tosContinueButton.tap()
    }

    func assertContinueButtonIsOnTheBottom() {
        if flowType.isModernFlow {
            // Get the last description text and make sure the button is below that
            let lastDescriptionBlock = sel.LAST_TOS_DESCRIPTION_TEXT.element(in: app)
            XCTAssertTrue(tosContinueButton.isBelow(element: lastDescriptionBlock),
                          "Continue button is not displayed at the bottom of The ToS card")
        } else {
            let manageButton = sel.MANAGE_TEXT_BUTTON.element(in: app)
            XCTAssertTrue(tosContinueButton.isBelow(element: manageButton),
                          "Continue button is not displayed at the bottom of The ToS card")
        }
    }

    func assertTextsOnCurrentScreen(expectedTitle: String,
                                    expectedDescription: String,
                                    expectedPrimary: String,
                                    expectedSecondary: String) {
        let title = sel.titleLabel(rootId: rootA11yId).element(in: app)
        let description = sel.descriptionLabel(rootId: rootA11yId).element(in: app)

        BaseTestCase().mozWaitForElementToExist(title)
        XCTAssertEqual(title.label, expectedTitle)
        XCTAssertEqual(description.label, expectedDescription)
        XCTAssertEqual(primaryButton.label, expectedPrimary)
        XCTAssertEqual(secondaryButton.label, expectedSecondary)
    }

    func tapSignIn() {
        primaryButton.waitAndTap()
    }

    func assertSignInScreen() {
        BaseTestCase().mozWaitForElementToExist(sel.NAVBAR_SYNC_AND_SAVE.element(in: app))
        let qr = sel.QR_SIGN_IN_BUTTON.element(in: app)
        let email = sel.EMAIL_SIGN_IN_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(qr)
        BaseTestCase().mozWaitForElementToExist(email)
        XCTAssertEqual(qr.label, "Ready to Scan")
        XCTAssertEqual(email.label, "Use Email Instead")
    }

    func assertTitle() {
        BaseTestCase().mozWaitForElementToExist(app.staticTexts["\(rootA11yId)TitleLabel"])
    }

    /// Exercises the multiple choice buttons on the card to choose your address bar position.
    func selectAddressBarPosition(position: AddressBarPosition) {
        if flowType.isModernFlow {
            let multipleChoiceButton = sel.addressBarTopButton(rootId: rootA11yId, position: position).element(in: app)
            multipleChoiceButton.waitAndTap()
        } else {
            // TODO: Migrate to TAE
            let buttons = app.buttons.matching(identifier: "\(rootA11yId)MultipleChoiceButton")
            for i in 0..<buttons.count {
                let button = buttons.element(boundBy: i)
                if button.label == position.rawValue {
                    button.waitAndTap()
                    break
                }
            }
        }
    }

    /// Exercises the multiple choice buttons on the card to choose your theme.
    func selectThemeButtons() {
        var themes = ["Light", "Dark"]

        // The "System Auto" / "Automatic" label is different between the flows
        switch flowType {
        case .legacy, .modernOrangeAndBlue:
            themes.append("System Auto")
        case .modernKit:
            themes.append("Automatic")
        }

        for theme in themes {
            selectTheme(theme)
        }
    }

    func exitSignInFlow() {
        sel.DONE_BUTTON.element(in: app).waitAndTap()
        sel.CLOSE_BUTTON.element(in: app).waitAndTap()
    }

    func closeTourIfNeeded() {
        let closeButton = sel.CLOSE_TOUR_BUTTON.element(in: app)
        if closeButton.exists {
            closeButton.waitAndTap()
        }
    }

    func closeTour() {
        let closeButton = sel.CLOSE_TOUR_BUTTON.element(in: app)
        closeButton.waitAndTap()
    }

    func waitForCurrentScreenElements(checkCloseButton: Bool = false,
                                      checkPageControl: Bool = false,
                                      waitForImage: Bool = true) {
        var img: XCUIElement
        let title = sel.titleLabel(rootId: rootA11yId).element(in: app)
        let desc = sel.descriptionLabel(rootId: rootA11yId).element(in: app)

        if waitForImage {
            img = app.images["\(rootA11yId)ImageView"]
            BaseTestCase().waitForElementsToExist([img, title, desc, primaryButton])
        } else {
            img = app.images["firefoxLoader"]
            BaseTestCase().waitForElementsToExist([title, desc, primaryButton])
        }

        var elementsToCheck = [img, title, desc, primaryButton]

        if checkCloseButton {
            let closeBtn = sel.CLOSE_TOUR_BUTTON.element(in: app)
            elementsToCheck.append(closeBtn)
        }

        if checkPageControl {
            let pageCtrl = sel.PAGE_CONTROL.element(in: app)
            elementsToCheck.append(pageCtrl)
        }

        BaseTestCase().waitForElementsToExist(elementsToCheck)

        // The secondary button only exists in some screens
        if secondaryButton.exists { BaseTestCase().mozWaitForElementToExist(secondaryButton) }
    }

    func assertCurrentScreenElements(primaryExists: Bool = true, secondaryExists: Bool = true) {
        let img = app.images["\(rootA11yId)ImageView"]
        let title = sel.titleLabel(rootId: rootA11yId).element(in: app)
        let desc = sel.descriptionLabel(rootId: rootA11yId).element(in: app)

        XCTAssertTrue(img.exists)
        XCTAssertTrue(title.exists)
        XCTAssertTrue(desc.exists)
        XCTAssertEqual(primaryButton.exists, primaryExists)
        XCTAssertEqual(secondaryButton.exists, secondaryExists)
    }

    /// Taps the primary button in the onboarding flow to navigate to the next screen (excluding ToS). Only call this
    /// method when the primary action for a specific onboarding card will cause forward navigation.
    func goToNextScreenViaPrimary() {
        BaseTestCase().mozWaitForElementToExist(primaryButton)
        primaryButton.waitAndTap()
        currentScreen += 1
    }

    /// Taps the secondary button in the onboarding flow to navigate to the next screen (excluding ToS). Only call this
    /// method when the secondary action for a specific onboarding card will cause forward navigation.
    func goToNextScreenViaSecondary() {
        BaseTestCase().mozWaitForElementToExist(secondaryButton)
        secondaryButton.waitAndTap()
        currentScreen += 1
    }

    // MARK: - Completing Different Onboarding Flows

    func completeOnboardingFlow(isIpad: Bool) {
        if flowType.isModernFlow {
            completeModernOnboardingFlow(isIpad: isIpad)
        } else {
            completeLegacyOnboardingFlow(isIPad: isIpad)
        }
    }

    /// Completes the Firefox Beta onboarding flow
    /// Beta has a different flow with specific screen IDs
    private func completeModernOnboardingFlow(isIpad: Bool) {
        // Screen 1: Default Browser - Skip (secondary button)
        assertTitle()
        goToNextScreenViaSecondary()

        if isIpad {
            // iPad does not show the address bar top/bottom placement card (second screen).
            // However, the accessibility IDs increase by one.
            currentScreen += 1
        } else {
            // Screen 2: Choose address bar - Continue (primary button)
            assertTitle()
            goToNextScreenViaPrimary()
        }

        // Screen 3: Choose theme - Continue (primary button)
        assertTitle()
        goToNextScreenViaPrimary()

        // Screen 4: Sign in to sync - Not now (secondary button)
        assertTitle()
        goToNextScreenViaSecondary()
    }

    /// Completes the standard onboarding tour (for Firefox and Fennec)
    /// - Parameters:
    ///   - isIPad: Whether running on iPad (skips fifth screen)
    ///   - afterBetaFlow: If true, the first screen may not have an image
    private func completeLegacyOnboardingFlow(isIPad: Bool, afterBetaFlow: Bool = false) {
        // First screen - already shown after gate
        // After Beta flow, the first standard screen may not have an image
        waitForCurrentScreenElements(waitForImage: !afterBetaFlow)
        assertTitle()

        // Navigate to second screen: Skip (secondary button)
        goToNextScreenViaSecondary()
        assertTitle()
        waitForCurrentScreenElements(checkCloseButton: true, checkPageControl: true)

        // Navigate to third screen: Skip (secondary button)
        goToNextScreenViaSecondary()
        assertTitle()
        assertCurrentScreenElements()

        // Navigate to fourth screen: Skip (secondary button)
        goToNextScreenViaSecondary()
        assertTitle()
        assertCurrentScreenElements(secondaryExists: false)

        // Navigate to fifth screen (iPhone only): Save and Continue (primary button)
        if !isIPad {
            goToNextScreenViaPrimary()
            assertTitle()
            assertCurrentScreenElements(secondaryExists: false)
        }

        // End onboarding: Save and Start Browsing (primary button)
        goToNextScreenViaPrimary()
    }

    // MARK: - Assertions

    func assertModernTermsOfServiceScreen() {
        let tosRoot = AccessibilityIdentifiers.TermsOfService.root
        let title = app.staticTexts["\(tosRoot)TitleLabel"]
        let description = app.staticTexts["\(tosRoot)DescriptionLabel"]
        let button = app.buttons["\(tosRoot)PrimaryButton"]

        BaseTestCase().mozWaitForElementToExist(title)
        XCTAssertTrue(title.exists)
        XCTAssertTrue(description.exists)
        XCTAssertTrue(button.exists)

        XCTAssertEqual(title.label, "Welcome to Firefox", "Should show correct title")
        XCTAssertEqual(button.label, "Continue", "Should show Continue button")
    }

    /// Verifies the welcome screen (shown after ToS acceptance)
    func assertModernWelcomeScreen() {
        let title = sel.titleLabel(rootId: rootA11yId).element(in: app)
        let desc = sel.descriptionLabel(rootId: rootA11yId).element(in: app)

        BaseTestCase().mozWaitForElementToExist(title)
        XCTAssertTrue(title.exists, "Welcome title should exist")
        XCTAssertTrue(desc.exists, "Welcome description should exist")
        XCTAssertTrue(primaryButton.exists, "Primary button should exist")
        XCTAssertTrue(secondaryButton.exists, "Secondary button should exist")
    }

    func assertToolbarCustomizationScreen() {
        let title = sel.titleLabel(rootId: rootA11yId).element(in: app)
        let primary = sel.primaryButton(rootId: rootA11yId).element(in: app)
        let topButton = sel.addressBarTopButton(rootId: rootA11yId, position: .top).element(in: app)
        let bottomButton = sel.addressBarTopButton(rootId: rootA11yId, position: .bottom).element(in: app)

        BaseTestCase().mozWaitForElementToExist(primary)
        XCTAssertTrue(title.exists, "Toolbar title should exist")
        XCTAssertTrue(primary.exists, "Primary button should exist")
        XCTAssertTrue(topButton.exists, "Top toolbar option should exist")
        XCTAssertTrue(bottomButton.exists, "Bottom toolbar option should exist")
    }

    func assertModernThemeCustomizationScreen() {
        let title = sel.titleLabel(rootId: rootA11yId).element(in: app)
        let primary = sel.primaryButton(rootId: rootA11yId).element(in: app)
        let lightButton = app.buttons["\(rootA11yId)SegmentedButton.Light"]
        let darkButton = app.buttons["\(rootA11yId)SegmentedButton.Dark"]

        BaseTestCase().mozWaitForElementToExist(primary)
        XCTAssertTrue(title.exists, "Theme title should exist")
        XCTAssertTrue(primary.exists, "Primary button should exist")
        XCTAssertTrue(lightButton.exists, "Light theme option should exist")
        XCTAssertTrue(darkButton.exists, "Dark theme option should exist")

        // The "System Auto" / "Automatic" label is different between the two modern flows
        var systemButton: XCUIElement?
        if case .modernOrangeAndBlue = flowType {
            systemButton = app.buttons["\(rootA11yId)SegmentedButton.System Auto"]
        } else if case .modernKit = flowType {
            systemButton = app.buttons["\(rootA11yId)SegmentedButton.Automatic"]
        }
        XCTAssertEqual(systemButton?.exists, true, "System Auto theme option should exist")
    }

    func assertSyncScreen() {
        let title = sel.titleLabel(rootId: rootA11yId).element(in: app)
        let primary = sel.primaryButton(rootId: rootA11yId).element(in: app)
        let secondary = sel.secondaryButton(rootId: rootA11yId).element(in: app)

        BaseTestCase().mozWaitForElementToExist(primary)
        XCTAssertTrue(title.exists, "Sync title should exist")
        XCTAssertTrue(primary.exists, "Primary button should exist")
        XCTAssertTrue(secondary.exists, "Secondary button should exist")

        if flowType.isModernFlow {
            // There are textual differences between the flows for the description
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

            assertTextsOnCurrentScreen(
                expectedTitle: "Instantly pick up where you left off",
                expectedDescription: expectedDescription,
                expectedPrimary: "Start Syncing",
                expectedSecondary: expectedSecondary
            )
        } else {
            assertTextsOnCurrentScreen(
                expectedTitle: "Stay encrypted when you hop between devices",
                expectedDescription: "Firefox encrypts your passwords, bookmarks, and more when you’re synced.",
                expectedPrimary: "Sign In",
                expectedSecondary: "Skip"
            )
        }
    }

    // MARK: Card interactions

    func selectToolbarPosition(_ position: String) {
        let button = app.buttons["\(rootA11yId)SegmentedButton.\(position)"]
        BaseTestCase().mozWaitForElementToExist(button)
        button.tap()
    }

    func selectTheme(_ theme: String) {
        let button = app.buttons["\(rootA11yId)SegmentedButton.\(theme)"]
        BaseTestCase().mozWaitForElementToExist(button)
        button.tap()
    }

    /// Returns the legacy ToS "Agree and Continue" button.
    func agreeAndContinueButton() -> XCUIElement {
        return sel.AGREE_AND_CONTINUE_BUTTON.element(in: app)
    }

    /// Returns the modern onboarding primary button (used by modern flows).
    func onboardingPrimaryButton() -> XCUIElement {
        return sel.ONBOARDING_PRIMARY_BUTTON.element(in: app)
    }
}
