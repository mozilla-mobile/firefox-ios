// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class OnboardingScreen {
    /// Describes the onboarding flow. A different flow is shown depending app channel (Fennec, FirefoxBeta, and Firefox).
    enum OnboardingFlowType {
        case old // The original onboarding with the first ToS screen. Simple backgrounds and hand-sketched imagery.
        case modernOrangeAndBlue // New modern onboarding built in 2025. Vivid orange/pink/blue backgrounds around cards.
        case modernKit // New modern onboarding built in 2026. Light pastel backgrounds with new Kit imagery.

        /// Firefox and FirefoxBeta show a new modern onboarding UI with an alternative card flow compared to Fennec.
        var isModernFlow: Bool {
            switch self {
            case .old:
                return false
            case .modernOrangeAndBlue, .modernKit:
                return true
            }
        }
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
        case .old:
            return sel.primaryButton(rootId: rootA11yId).element(in: app)
        case .modernOrangeAndBlue, .modernKit:
            return sel.betaPrimaryButton(screenIndex: currentScreen).element(in: app)
        }
    }

    /// Returns the primary button on the currentScreen.
    private var secondaryButton: XCUIElement {
        switch flowType {
        case .old:
            return sel.secondaryButton(rootId: rootA11yId).element(in: app)
        case .modernOrangeAndBlue, .modernKit:
            return sel.betaSecondaryButton(screenIndex: currentScreen).element(in: app)
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
        let button: XCUIElement

        // The modern onboarding flows have standardized the ToS primary button to match the other primary buttons.
        switch flowType {
        case .old:
            // Old onboarding shows the same "Continue" text, except with a different accessibility ID than modern flows.
            button = sel.AGREE_AND_CONTINUE_BUTTON.element(in: app)

        case .modernOrangeAndBlue, .modernKit:
            button = sel.ONBOARDING_PRIMARY_BUTTON.element(in: app)
        }

        BaseTestCase().mozWaitForElementToExist(button)
        button.tap()
    }

    func assertContinueButtonIsOnTheBottom() {
        let continueButton: XCUIElement

        // The modern onboarding flows have standardized the ToS primary button to match the other primary buttons.
        switch flowType {
        case .old:
            // Old onboarding shows the same "Continue" text, except with a different accessibility ID than modern flows.
            continueButton = sel.AGREE_AND_CONTINUE_BUTTON.element(in: app)

        case .modernOrangeAndBlue, .modernKit:
            continueButton = sel.ONBOARDING_PRIMARY_BUTTON.element(in: app)
        }

        let manageButton = sel.MANAGE_TEXT_BUTTON.element(in: app)
        XCTAssertTrue(continueButton.isBelow(element: manageButton),
                      "Continue button is not displayed at the bottom of The ToS card")
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

    func exitSignInFlow() {
        sel.DONE_BUTTON.element(in: app).waitAndTap()
        sel.CLOSE_BUTTON.element(in: app).waitAndTap()
    }

    func closeTourIfNeeded() {
        let closeButton = sel.CLOSE_TOUR_BUTTON.element(in: app)
        if closeButton.exists {
            closeButton.waitAndTap()
        }
        // Generic Popup "Close"
        let genericClose = app.buttons["Close"]
        if genericClose.exists {
            genericClose.waitAndTap()
        }
    }

    func waitForCurrentScreenElements(checkCloseButton: Bool = false,
                                      checkPageControl: Bool = false,
                                      waitForImage: Bool = true) {
        let img = app.images["\(rootA11yId)ImageView"]
        let title = sel.titleLabel(rootId: rootA11yId).element(in: app)
        let desc = sel.descriptionLabel(rootId: rootA11yId).element(in: app)

        if waitForImage {
            let img = app.images["\(rootA11yId)ImageView"]
            BaseTestCase().waitForElementsToExist([img, title, desc, primaryButton])
        } else {
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

    /// Dismisses the "new changes" popup on Home, if present.
    func dismissNewChangesPopup() {
        // Dismiss "new changes" popup if present
        let closePopup = app.buttons["Close"]
        if closePopup.exists { closePopup.tap() }
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

    // MARK: - Channel-specific flows

    /// Completes the Firefox Beta onboarding flow
    /// Beta has a different flow with specific screen IDs
    func completeFirefoxBetaOnboardingFlow() {
        // Screen 0: Skip (secondary button)
        goToNextScreenViaSecondary()

        // Screen 1: Continue (primary button)
        goToNextScreenViaPrimary()

        // Screen 2: Continue (primary button)
        goToNextScreenViaPrimary()

        // Screen 3: Not now (secondary button)
        goToNextScreenViaSecondary()
    }

    /// Completes the standard onboarding tour (for Firefox and Fennec)
    /// - Parameters:
    ///   - isIPad: Whether running on iPad (skips fifth screen)
    ///   - afterBetaFlow: If true, the first screen may not have an image
    func completeStandardOnboardingFlow(isIPad: Bool, afterBetaFlow: Bool = false) {
        // First screen - already shown after gate
        // After Beta flow, the first standard screen may not have an image
        waitForCurrentScreenElements(waitForImage: !afterBetaFlow)

        // Navigate to second screen: Skip (secondary button)
        goToNextScreenViaSecondary()
        waitForCurrentScreenElements(checkCloseButton: true, checkPageControl: true)

        // Navigate to third screen: Skip (secondary button)
        goToNextScreenViaSecondary()
        assertCurrentScreenElements()

        // Navigate to fourth screen: Skip (secondary button)
        goToNextScreenViaSecondary()
        assertCurrentScreenElements(secondaryExists: false)

        // Navigate to fifth screen (iPhone only): Save and Continue (primary button)
        if !isIPad {
            goToNextScreenViaPrimary()
            assertCurrentScreenElements(secondaryExists: false)
        }

        // End onboarding: Save and Start Browsing (primary button)
        goToNextScreenViaPrimary()
    }

    // MARK: - Modern Onboarding Flow

    func assertModernTermsOfServiceScreen() {
        let tosRoot = AccessibilityIdentifiers.TermsOfService.root
        let title = app.staticTexts["\(tosRoot)TitleLabel"]
        let description = app.staticTexts["\(tosRoot)DescriptionLabel"]
        let button = app.buttons["\(tosRoot)PrimaryButton"]

        BaseTestCase().mozWaitForElementToExist(title)
        XCTAssertTrue(title.exists)
        XCTAssertTrue(description.exists)
        XCTAssertTrue(button.exists)
        XCTAssertEqual(button.label, "Continue")
    }

    /// Verifies the welcome screen (shown after ToS acceptance)
    func assertModernWelcomeScreen() {
        let title = sel.titleLabel(rootId: rootA11yId).element(in: app)
        let desc = sel.descriptionLabel(rootId: rootA11yId).element(in: app)
        let primary = sel.primaryButton(rootId: rootA11yId).element(in: app)
        let secondary = sel.secondaryButton(rootId: rootA11yId).element(in: app)

        BaseTestCase().mozWaitForElementToExist(primary)
        XCTAssertTrue(title.exists, "Welcome title should exist")
        XCTAssertTrue(desc.exists, "Welcome description should exist")
        XCTAssertTrue(primary.exists, "Primary button should exist")
        XCTAssertTrue(secondary.exists, "Secondary button should exist")
    }

    func assertToolbarCustomizationScreen() {
        let title = sel.titleLabel(rootId: rootA11yId).element(in: app)
        let primary = sel.primaryButton(rootId: rootA11yId).element(in: app)
        let topButton = app.buttons["\(rootA11yId)SegmentedButton.Top"]
        let bottomButton = app.buttons["\(rootA11yId)SegmentedButton.Bottom"]

        BaseTestCase().mozWaitForElementToExist(primary)
        XCTAssertTrue(title.exists, "Toolbar title should exist")
        XCTAssertTrue(primary.exists, "Primary button should exist")
        XCTAssertTrue(topButton.exists, "Top toolbar option should exist")
        XCTAssertTrue(bottomButton.exists, "Bottom toolbar option should exist")
    }

    func assertThemeCustomizationScreen() {
        let title = sel.titleLabel(rootId: rootA11yId).element(in: app)
        let primary = sel.primaryButton(rootId: rootA11yId).element(in: app)
        let systemButton = app.buttons["\(rootA11yId)SegmentedButton.System Auto"]
        let lightButton = app.buttons["\(rootA11yId)SegmentedButton.Light"]
        let darkButton = app.buttons["\(rootA11yId)SegmentedButton.Dark"]

        BaseTestCase().mozWaitForElementToExist(primary)
        XCTAssertTrue(title.exists, "Theme title should exist")
        XCTAssertTrue(primary.exists, "Primary button should exist")
        XCTAssertTrue(systemButton.exists, "System Auto theme option should exist")
        XCTAssertTrue(lightButton.exists, "Light theme option should exist")
        XCTAssertTrue(darkButton.exists, "Dark theme option should exist")
    }

    func assertSyncScreen() {
        let title = sel.titleLabel(rootId: rootA11yId).element(in: app)
        let primary = sel.primaryButton(rootId: rootA11yId).element(in: app)
        let secondary = sel.secondaryButton(rootId: rootA11yId).element(in: app)

        BaseTestCase().mozWaitForElementToExist(primary)
        XCTAssertTrue(title.exists, "Sync title should exist")
        XCTAssertTrue(primary.exists, "Primary button should exist")
        XCTAssertTrue(secondary.exists, "Secondary button should exist")
    }

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

    /// Completes the modern onboarding flow
    /// - Parameters:
    ///   - isIPad: Whether running on iPad (skips toolbar screen)
    ///   - tosAccepted: Whether Terms of Service was already accepted
    func completeModernOnboardingFlow(isIPad: Bool, tosAccepted: Bool = false) {
        currentScreen = 0

        if !tosAccepted {
            assertModernTermsOfServiceScreen()
            handleTermsOfService()
        }

        assertModernWelcomeScreen()
        goToNextScreenViaSecondary()

        if !isIPad {
            assertToolbarCustomizationScreen()
            selectToolbarPosition("Bottom")
            goToNextScreenViaPrimary()
        } else {
            currentScreen += 1
        }

        assertThemeCustomizationScreen()
        selectTheme("System Auto")
        goToNextScreenViaPrimary()

        assertSyncScreen()
        let secondary = sel.secondaryButton(rootId: rootA11yId).element(in: app)
        secondary.waitAndTap()

        let closePopup = app.buttons["Close"]
        if closePopup.exists { closePopup.tap() }
    }
}
