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

    func waitForCurrentScreenElements() {
        let img = app.images["\(rootA11yId)ImageView"]
        let title = sel.titleLabel(rootId: rootA11yId).element(in: app)
        let desc = sel.descriptionLabel(rootId: rootA11yId).element(in: app)
        let primary = sel.primaryButton(rootId: rootA11yId).element(in: app)
        let secondary = sel.secondaryButton(rootId: rootA11yId).element(in: app)

        BaseTestCase().waitForElementsToExist([img, title, desc, primary])
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
}
