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

    /// A tappable legal link on the Terms of Service card. Each opens an overlay dismissed via a Done
    /// button: a web pop up for Terms of Use / Privacy Notice, a bottom sheet for Manage.
    enum ToSLink {
        case termsOfUse
        case privacyNotice
        case manage

        var name: String {
            switch self {
            case .termsOfUse: return "Terms of Use"
            case .privacyNotice: return "Privacy Notice"
            case .manage: return "Manage"
            }
        }

        /// Accessibility identifier applied to the rendered link, matching the ids set in `TermsOfServiceManager`.
        var identifier: String {
            switch self {
            case .termsOfUse: return AccessibilityIdentifiers.TermsOfService.termsOfServiceAgreement
            case .privacyNotice: return AccessibilityIdentifiers.TermsOfService.privacyNoticeAgreement
            case .manage: return AccessibilityIdentifiers.TermsOfService.manageDataCollectionAgreement
            }
        }

        var overlayName: String {
            switch self {
            case .termsOfUse, .privacyNotice: return "link pop up"
            case .manage: return "Manage bottom sheet"
            }
        }
    }

    /// A data-collection toggle on the Manage bottom sheet. Each maps to its switch and description
    /// (the description carries the toggle's Learn more link).
    enum ManageToggle {
        case crashReports
        case technicalData

        var name: String {
            switch self {
            case .crashReports: return "Automatically send crash reports"
            case .technicalData: return "Send technical and interaction data to Mozilla"
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
        let continueButton = tosContinueButton
        BaseTestCase().mozWaitForElementToExist(continueButton, timeout: TIMEOUT_LONG)
        // The ToS is presented over full screen with a cross-dissolve transition, so the button
        // can exist before it is hittable and an early tap gets absorbed. Wait for it to be
        // hittable, then tap again if the screen has not advanced past the button.
        BaseTestCase().mozWaitElementHittable(element: continueButton, timeout: TIMEOUT)
        continueButton.tap()
        if continueButton.exists {
            continueButton.tap()
        }
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

    /// Asserts the copy of a primary-only onboarding card, verifying no secondary button is present.
    func assertTextsOnCurrentScreen(expectedTitle: String,
                                    expectedDescription: String,
                                    expectedPrimary: String) {
        let title = sel.titleLabel(rootId: rootA11yId).element(in: app)
        let description = sel.descriptionLabel(rootId: rootA11yId).element(in: app)

        BaseTestCase().mozWaitForElementToExist(title)
        XCTAssertEqual(title.label, expectedTitle)
        XCTAssertEqual(description.label, expectedDescription)
        XCTAssertEqual(primaryButton.label, expectedPrimary)
        XCTAssertFalse(secondaryButton.exists, "No secondary button should be present on this card")
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

    /// Asserts the given address bar position button is selected on the modern flow's segmented control.
    func assertAddressBarPositionSelected(position: AddressBarPosition) {
        let button = sel.addressBarTopButton(rootId: rootA11yId, position: position).element(in: app)
        BaseTestCase().mozWaitForElementToExist(button)
        XCTAssertTrue(button.isSelected, "\(position.rawValue) address bar position button should be selected")
    }

    /// Exercises the multiple choice buttons on the card to choose your theme.
    func selectThemeButtons() {
        var themes = ["Light", "Dark"]

        // The "System Auto" / "Automatic" label is different between the flows
        switch flowType {
        case .legacy:
            themes.append("System Auto")
        case .modernOrangeAndBlue:
            if BaseTestCase().isFennec {
                themes.append("System Auto")
            } else {
                themes.append("Automatic")
            }
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

    /// Asserts the given link is displayed on the ToS card.
    func assertLinkIsDisplayed(_ link: ToSLink) {
        let element = linkElement(link)
        BaseTestCase().mozWaitForElementToExist(element)
        XCTAssertTrue(element.exists, "The \(link.name) link should be displayed on the ToS card")
    }

    /// Taps the given link to open its overlay. The link is a single hittable control, so a plain tap
    /// on its accessibility identifier is reliable.
    func tapLink(_ link: ToSLink) {
        linkElement(link).waitAndTap()
    }

    /// Asserts the overlay opened by the given link (web pop up or bottom sheet) is displayed.
    func assertOverlayIsDisplayed(for link: ToSLink) {
        let doneButton = overlayDoneButton(link).element(in: app)
        BaseTestCase().mozWaitForElementToExist(doneButton, timeout: TIMEOUT_LONG)
        XCTAssertTrue(doneButton.exists, "The \(link.overlayName) should be displayed")
    }

    /// Asserts the overlay opened by the given link is no longer displayed.
    func assertOverlayIsClosed(for link: ToSLink) {
        let doneButton = overlayDoneButton(link).element(in: app)
        BaseTestCase().mozWaitForElementToNotExist(doneButton)
        XCTAssertFalse(doneButton.exists, "The \(link.overlayName) should be closed")
    }

    /// Dismisses the overlay opened by the given link via its Done button, returning to the ToS card.
    func dismissOverlay(for link: ToSLink) {
        overlayDoneButton(link).element(in: app).waitAndTap()
    }

    /// Asserts the Manage data-collection bottom sheet shows all its content: title, Done button, and
    /// both data toggles with their titles, descriptions and embedded Learn more links.
    func assertManageBottomSheetContents() {
        let title = sel.MANAGE_SHEET_TITLE.element(in: app)
        let doneButton = sel.MANAGE_SHEET_DONE_BUTTON.element(in: app)
        let technicalTitle = sel.MANAGE_SHEET_TECHNICAL_DATA_TITLE.element(in: app)
        let technicalSwitch = sel.MANAGE_SHEET_TECHNICAL_DATA_SWITCH.element(in: app)
        let technicalDescription = sel.MANAGE_SHEET_TECHNICAL_DATA_DESCRIPTION.element(in: app)
        let crashTitle = sel.MANAGE_SHEET_CRASH_REPORTS_TITLE.element(in: app)
        let crashSwitch = sel.MANAGE_SHEET_CRASH_REPORTS_SWITCH.element(in: app)
        let crashDescription = sel.MANAGE_SHEET_CRASH_REPORTS_DESCRIPTION.element(in: app)

        BaseTestCase().waitForElementsToExist([
            title, doneButton,
            technicalTitle, technicalSwitch, technicalDescription,
            crashTitle, crashSwitch, crashDescription
        ])

        XCTAssertEqual(title.label, "Help us make Firefox better")
        XCTAssertEqual(doneButton.label, "Done")

        XCTAssertEqual(technicalTitle.label, "Send technical and interaction data to Mozilla")
        XCTAssertTrue(technicalDescription.label.contains(
            "Data about your device, hardware configuration, and how you use Firefox helps improve"),
                      "Technical data description text is missing")
        XCTAssertTrue(technicalDescription.label.contains("Learn more"),
                      "Technical data description should contain the Learn more link")

        XCTAssertEqual(crashTitle.label, "Automatically send crash reports")
        XCTAssertTrue(crashDescription.label.contains(
            "Crash reports allow us to diagnose and fix issues with the browser"),
                      "Crash reports description text is missing")
        XCTAssertTrue(crashDescription.label.contains("Learn more"),
                      "Crash reports description should contain the Learn more link")
    }

    /// Asserts the given Manage sheet toggle is displayed and turned on. Switch state is read from the
    /// element's value, which is "1" when on and "0" when off.
    func assertManageToggleIsOn(_ toggle: ManageToggle) {
        let element = manageToggleSwitch(toggle)
        BaseTestCase().mozWaitForElementToExist(element)
        XCTAssertEqual(element.value as? String, "1", "The \(toggle.name) toggle should be enabled")
    }

    /// Asserts the given Manage sheet toggle is displayed and turned off.
    func assertManageToggleIsOff(_ toggle: ManageToggle) {
        let element = manageToggleSwitch(toggle)
        BaseTestCase().mozWaitForElementToExist(element)
        XCTAssertEqual(element.value as? String, "0", "The \(toggle.name) toggle should be disabled")
    }

    /// Taps the given Manage sheet toggle to flip its on/off state.
    func tapManageToggle(_ toggle: ManageToggle) {
        manageToggleSwitch(toggle).waitAndTap()
    }

    /// Taps the Learn more link below the given Manage sheet toggle. The link spans the whole
    /// description label, so tapping the label opens the SUMO support page.
    func tapManageToggleLearnMore(_ toggle: ManageToggle) {
        manageToggleDescription(toggle).waitAndTap()
    }

    private func manageToggleSwitch(_ toggle: ManageToggle) -> XCUIElement {
        switch toggle {
        case .crashReports: return sel.MANAGE_SHEET_CRASH_REPORTS_SWITCH.element(in: app)
        case .technicalData: return sel.MANAGE_SHEET_TECHNICAL_DATA_SWITCH.element(in: app)
        }
    }

    private func manageToggleDescription(_ toggle: ManageToggle) -> XCUIElement {
        switch toggle {
        case .crashReports: return sel.MANAGE_SHEET_CRASH_REPORTS_DESCRIPTION.element(in: app)
        case .technicalData: return sel.MANAGE_SHEET_TECHNICAL_DATA_DESCRIPTION.element(in: app)
        }
    }

    /// Asserts a SUMO support page opened after tapping a Learn more link, confirmed by its web view
    /// and the presenting navigation controller's Done button (the shared ToS page Done identifier).
    func assertSumoPageOpened() {
        let doneButton = sel.TOS_PAGE_DONE_BUTTON.element(in: app)
        let webView = app.webViews.firstMatch
        BaseTestCase().waitForElementsToExist([doneButton, webView], timeout: TIMEOUT_LONG)
        XCTAssertTrue(doneButton.exists, "The SUMO support page Done button should be displayed")
        XCTAssertTrue(webView.exists, "The SUMO support page web view should be displayed")
    }

    /// Locates the embedded ToS link by its accessibility identifier. Matched across any element type
    /// since the link carries both button and link traits.
    private func linkElement(_ link: ToSLink) -> XCUIElement {
        return app.descendants(matching: .any).matching(identifier: link.identifier).firstMatch
    }

    private func overlayDoneButton(_ link: ToSLink) -> Selector {
        switch link {
        case .termsOfUse, .privacyNotice: return sel.TOS_PAGE_DONE_BUTTON
        case .manage: return sel.MANAGE_SHEET_DONE_BUTTON
        }
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

    /// Taps the first card's "Set as Default Browser" primary button, opening the "Switch Your Default
    /// Browser" bottom sheet. Does not advance the carousel, so `currentScreen` is left unchanged.
    func tapSetAsDefaultBrowser() {
        BaseTestCase().mozWaitForElementToExist(primaryButton)
        primaryButton.waitAndTap()
    }

    /// Asserts the "Switch Your Default Browser" instructions bottom sheet is displayed, verifying both
    /// its title and the "Go to Settings" primary button.
    func assertDefaultBrowserBottomSheet() {
        let title = sel.DEFAULT_BROWSER_SHEET_TITLE.element(in: app)
        let goToSettings = sel.DEFAULT_BROWSER_SHEET_GO_TO_SETTINGS_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(goToSettings)
        XCTAssertTrue(title.exists, "Default browser bottom sheet title should exist")
        XCTAssertTrue(goToSettings.exists, "Default browser bottom sheet Go to Settings button should exist")
    }

    /// Taps the "Go to Settings" button on the bottom sheet. This backgrounds the app and opens the iOS
    /// Settings app on the Firefox page.
    func tapGoToSettingsOnBottomSheet() {
        sel.DEFAULT_BROWSER_SHEET_GO_TO_SETTINGS_BUTTON.element(in: app).waitAndTap()
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
        XCTAssertTrue(systemThemeButton.exists, "System Auto theme option should exist")
    }

    /// Asserts the theme card defaults to the System Auto / Automatic option, with Light and Dark
    /// unselected. Selection is read from the button's accessibility selected state.
    func assertDefaultThemeIsSystemAuto() {
        let lightButton = app.buttons["\(rootA11yId)SegmentedButton.Light"]
        let darkButton = app.buttons["\(rootA11yId)SegmentedButton.Dark"]

        BaseTestCase().waitForElementsToExist([systemThemeButton, lightButton, darkButton])
        XCTAssertTrue(systemThemeButton.isSelected, "System Auto should be the default selected theme")
        XCTAssertFalse(lightButton.isSelected, "Light theme should not be selected by default")
        XCTAssertFalse(darkButton.isSelected, "Dark theme should not be selected by default")
    }

    /// Asserts the given theme option on the theme card is the selected one. Selection is read from the
    /// button's accessibility selected state.
    func assertThemeIsSelected(_ theme: String) {
        let button = app.buttons["\(rootA11yId)SegmentedButton.\(theme)"]
        BaseTestCase().mozWaitForElementToExist(button)
        XCTAssertTrue(button.isSelected, "\(theme) theme should be the selected theme")
    }

    /// The System Auto / Automatic segmented button. Its label differs between the modern flows.
    private var systemThemeButton: XCUIElement {
        let label: String
        if BaseTestCase().isFennec, case .modernOrangeAndBlue = flowType {
            label = "System Auto"
        } else {
            label = "Automatic"
        }
        return app.buttons["\(rootA11yId)SegmentedButton.\(label)"]
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
            let longerDescription = "Grab bookmarks, passwords, and more on any device in a snap." +
            " Your personal data stays safe and secure with encryption."
            let shorterDescription = "Get your bookmarks, history, and passwords on any device."
            switch flowType {
            case .modernKit:
                // swiftlint:disable line_length
                expectedDescription = longerDescription
                expectedSecondary = "Not Now"
                // swiftlint:enable line_length
            case .modernOrangeAndBlue:
                if BaseTestCase().isFennec {
                    expectedDescription = shorterDescription
                    expectedSecondary = "Not now"
                } else {
                    expectedDescription = longerDescription
                    expectedSecondary = "Not Now"
                }
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
