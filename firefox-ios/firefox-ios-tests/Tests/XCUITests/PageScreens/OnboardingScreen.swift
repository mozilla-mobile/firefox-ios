// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class OnboardingScreen {
    private let app: XCUIApplication
    private let sel: OnboardingSelectorsSet

    var currentScreen = 0
    var rootA11yId: String {
        return "\(AccessibilityIdentifiers.Onboarding.onboarding)\(currentScreen)"
    }

    init(app: XCUIApplication, selectors: OnboardingSelectorsSet = OnboardingSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func agreeAndContinue() {
        let button = sel.AGREE_AND_CONTINUE_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(button)
        button.tap()
    }

    func assertContinueButtonIsOnTheBottom() {
        let continueButton = sel.AGREE_AND_CONTINUE_BUTTON.element(in: app)
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
        let primary = sel.primaryButton(rootId: rootA11yId).element(in: app)
        let secondary = sel.secondaryButton(rootId: rootA11yId).element(in: app)

        BaseTestCase().mozWaitForElementToExist(title)
        XCTAssertEqual(title.label, expectedTitle)
        XCTAssertEqual(description.label, expectedDescription)
        XCTAssertEqual(primary.label, expectedPrimary)
        XCTAssertEqual(secondary.label, expectedSecondary)
    }

    func tapSignIn() {
        sel.primaryButton(rootId: rootA11yId).element(in: app).waitAndTap()
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
        // Generic Popup “Close”
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
        let primary = sel.primaryButton(rootId: rootA11yId).element(in: app)
        let secondary = sel.secondaryButton(rootId: rootA11yId).element(in: app)

        if waitForImage {
            let img = app.images["\(rootA11yId)ImageView"]
            BaseTestCase().waitForElementsToExist([img, title, desc, primary])
        } else {
            BaseTestCase().waitForElementsToExist([title, desc, primary])
        }

        var elementsToCheck = [img, title, desc, primary]

        if checkCloseButton {
            let closeBtn = sel.CLOSE_TOUR_BUTTON.element(in: app)
            elementsToCheck.append(closeBtn)
        }

        if checkPageControl {
            let pageCtrl = sel.PAGE_CONTROL.element(in: app)
            elementsToCheck.append(pageCtrl)
        }

        BaseTestCase().waitForElementsToExist(elementsToCheck)
        // The secundary button only exists in some screens
        if secondary.exists { BaseTestCase().mozWaitForElementToExist(secondary) }
    }

    func assertCurrentScreenElements(primaryExists: Bool = true, secondaryExists: Bool = true) {
        let img = app.images["\(rootA11yId)ImageView"]
        let title = sel.titleLabel(rootId: rootA11yId).element(in: app)
        let desc = sel.descriptionLabel(rootId: rootA11yId).element(in: app)
        let primary = sel.primaryButton(rootId: rootA11yId).element(in: app)
        let secondary = sel.secondaryButton(rootId: rootA11yId).element(in: app)

        XCTAssertTrue(img.exists)
        XCTAssertTrue(title.exists)
        XCTAssertTrue(desc.exists)
        XCTAssertEqual(primary.exists, primaryExists)
        XCTAssertEqual(secondary.exists, secondaryExists)
    }

    func finishOnboarding() {
        let primary = sel.primaryButton(rootId: rootA11yId).element(in: app)
        primary.waitAndTap()
        // Dismiss “new changes” popup if present
        let closePopup = app.buttons["Close"]
        if closePopup.exists { closePopup.tap() }
    }

    // Navigation
    func goToNextScreen() {
        let secondary = sel.secondaryButton(rootId: rootA11yId).element(in: app)
        BaseTestCase().mozWaitForElementToExist(secondary)
        secondary.waitAndTap()
        currentScreen += 1
    }

    func goToNextScreenViaPrimary() {
        let primary = sel.primaryButton(rootId: rootA11yId).element(in: app)
        BaseTestCase().mozWaitForElementToExist(primary)
        primary.waitAndTap()
        currentScreen += 1
    }

    func swipeToNextScreen() {
        let next = sel.secondaryButton(rootId: rootA11yId).element(in: app)
        BaseTestCase().mozWaitForElementToExist(next)
        next.waitAndTap()
        currentScreen += 1
    }

    // MARK: - Channel-specific flows

    /// Handles the initial gate based on app channel (Firefox Beta, Firefox, Fennec)
    func handleFirstRunGate(isFirefoxBeta: Bool, isFirefox: Bool) {
        if !isFirefoxBeta && !isFirefox {
            // Fennec: Shows Terms of Service with "Agree and Continue" button
            agreeAndContinue()
        } else {
            // Firefox/Firefox Beta: Shows "Continue" button
            let continueButton = sel.CONTINUE_BUTTON.element(in: app)
            BaseTestCase().mozWaitForElementToExist(continueButton)
            continueButton.tap()
        }
    }

    /// Completes the Firefox Beta onboarding flow
    /// Beta has a different flow with specific screen IDs
    func completeBetaOnboardingFlow() {
        // Screen 0: Skip (secondary button)
        let screen0Secondary = sel.betaSecondaryButton(screenIndex: 0).element(in: app)
        BaseTestCase().mozWaitForElementToExist(screen0Secondary)
        screen0Secondary.tap()

        // Screen 1: Continue (primary button)
        let screen1Primary = sel.betaPrimaryButton(screenIndex: 1).element(in: app)
        BaseTestCase().mozWaitForElementToExist(screen1Primary)
        screen1Primary.tap()

        // Screen 2: Continue (primary button)
        let screen2Primary = sel.betaPrimaryButton(screenIndex: 2).element(in: app)
        BaseTestCase().mozWaitForElementToExist(screen2Primary)
        screen2Primary.tap()

        // Screen 3: Not now (secondary button)
        let screen3Secondary = sel.betaSecondaryButton(screenIndex: 3).element(in: app)
        BaseTestCase().mozWaitForElementToExist(screen3Secondary)
        screen3Secondary.tap()

        // After Beta flow, we're at the first standard onboarding screen
        currentScreen = 0
    }

    /// Completes the standard onboarding tour (for Firefox and Fennec)
    /// - Parameters:
    ///   - isIPad: Whether running on iPad (skips fifth screen)
    ///   - afterBetaFlow: If true, the first screen may not have an image
    func completeStandardOnboardingFlow(isIPad: Bool, afterBetaFlow: Bool = false) {
        // First screen - already shown after gate
        // After Beta flow, the first standard screen may not have an image
        waitForCurrentScreenElements(waitForImage: !afterBetaFlow)

        // Navigate to second screen
        goToNextScreen()
        waitForCurrentScreenElements(checkCloseButton: true, checkPageControl: true)

        // Navigate to third screen
        goToNextScreen()
        assertCurrentScreenElements()

        // Navigate to fourth screen
        goToNextScreen()
        assertCurrentScreenElements(secondaryExists: false)

        // Fifth screen (iPhone only)
        if !isIPad {
            goToNextScreenViaPrimary()
            assertCurrentScreenElements(secondaryExists: false)
        }

        // Finish onboarding
        finishOnboarding()
    }

    // MARK: - Modern Onboarding Flow

    /// Accepts the modern Terms of Service card
    func acceptModernTermsOfService() {
        let tosRoot = AccessibilityIdentifiers.TermsOfService.root
        let button = app.buttons["\(tosRoot)PrimaryButton"]
        BaseTestCase().mozWaitForElementToExist(button)
        button.tap()
    }

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
            acceptModernTermsOfService()
        }

        assertModernWelcomeScreen()
        goToNextScreen()

        if !isIPad {
            assertToolbarCustomizationScreen()
            selectToolbarPosition("Bottom")
            goToNextScreenViaPrimary()
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
