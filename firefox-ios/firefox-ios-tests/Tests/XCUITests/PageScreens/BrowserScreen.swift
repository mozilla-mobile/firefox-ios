// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class BrowserScreen {
    private let app: XCUIApplication
    private let sel: BrowserSelectorsSet

    init(app: XCUIApplication, selectors: BrowserSelectorsSet = BrowserSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var addressBar: XCUIElement { sel.ADDRESS_BAR.element(in: app) }
    private var cancelButton: XCUIElement { sel.CANCEL_BUTTON_URL_BAR.element(in: app) }

    func assertAddressBarContains(value: String, timeout: TimeInterval = TIMEOUT) {
        let addressBar = sel.ADDRESS_BAR.element(in: app)
        BaseTestCase().mozWaitForValueContains(addressBar, value: value, timeout: timeout)
    }

    func handleHumanVerification() {
        let checkboxValidation = app.webViews["Web content"].staticTexts["Verify you are human"]
        if checkboxValidation.exists {
            checkboxValidation.waitAndTap()
        }
    }

    func tapBackButton() {
        let backButton = sel.BACK_BUTTON.element(in: app)
        backButton.waitAndTap()
    }

    func assertAutofillOptionNotAvailable(
            forFieldsCount count: Int,
            autofillButtonID: String,
            timeout: TimeInterval = TIMEOUT) {
        let textFieldsQuery = app.webViews.textFields
        let addressAutofillButton = app.buttons[autofillButtonID]

        for index in 0..<count {
            let textField = textFieldsQuery.element(boundBy: index)

            BaseTestCase().mozWaitForElementToExist(textField)
            textField.waitAndTap()

            BaseTestCase().mozWaitForElementToNotExist(addressAutofillButton, timeout: timeout)
        }
    }

    private func assertUserAgentTextExists(_ text: String, timeout: TimeInterval = TIMEOUT) {
        let pred = NSPredicate(
            format: "elementType == %d AND label == %@",
            XCUIElement.ElementType.staticText.rawValue,
            text
        )
        let query = app.webViews.descendants(matching: .staticText).matching(pred)
        let element = query.firstMatch

        BaseTestCase().mozWaitForElementToExist(element, timeout: timeout)
        XCTAssertTrue(element.exists, "Expected UA text '\(text)' was not found in the web view.")
    }

    func assertDesktopUserAgentIsDisplayed(timeout: TimeInterval = TIMEOUT) {
        assertUserAgentTextExists("DESKTOP_UA", timeout: timeout)
    }

    func assertMobileUserAgentIsDisplayed(timeout: TimeInterval = TIMEOUT) {
        assertUserAgentTextExists("MOBILE_UA", timeout: timeout)
    }

    func handleIos15ToastIfNecessary() {
        if #unavailable(iOS 16) {
            // iOS 15 displays a toast that covers the reload button
            sleep(2)
        }
    }

    func tapDownloadsToastButton() {
        let downloadsButton = sel.DOWNLOADS_TOAST_BUTTON.element(in: app)
        downloadsButton.waitAndTap()
    }

    func assertMozillaPageLoaded(urlField: XCUIElement) {
        BaseTestCase().mozWaitForElementToExist(sel.MENU_BUTTON.element(in: app))
        BaseTestCase().mozWaitForElementToExist(sel.STATIC_TEXT_MOZILLA.element(in: app))
        BaseTestCase().mozWaitForValueContains(urlField, value: "mozilla.org")
    }

    func assertExampleDomainLoaded(urlField: XCUIElement) {
        BaseTestCase().mozWaitForElementToExist(sel.STATIC_TEXT_EXAMPLE_DOMAIN.element(in: app))
        BaseTestCase().mozWaitForValueContains(urlField, value: "example.com")
    }

    func clearURL() {
        let clearButton = sel.CLEAR_TEXT_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(clearButton)
        clearButton.waitAndTap()
    }

    func assertFirefoxHomepageElementsCached() {
        let topSitesLinkID = "FirefoxHomepage.TopSites.itemCell"
        let youTubeLinkText = "YouTube"

        let topSitesLink = app.links[topSitesLinkID]
        let youTubeText = app.links.staticTexts[youTubeLinkText]

        BaseTestCase().mozWaitForElementToExist(topSitesLink)
        BaseTestCase().mozWaitForElementToExist(youTubeText)
    }

    func assertKeyboardFocusState(isFocusedOniPad: Bool) {
        var addressBar: XCUIElement { sel.ADDRESS_BAR.element(in: app) }
        if UIDevice.current.userInterfaceIdiom == .pad {
            let hasFocus = addressBar.value(forKey: "hasKeyboardFocus") as? Bool ?? false
            XCTAssertEqual(hasFocus, isFocusedOniPad, "The keyboard focus state on iPad is incorrect.")

            let keyboardCount = app.keyboards.count
                XCTAssertEqual(keyboardCount, 1, "The keyboard should be shown on iPad")
            } else {
                let hasFocus = addressBar.value(forKey: "hasKeyboardFocus") as? Bool ?? false
                XCTAssertEqual(hasFocus, false, "The keyboard focus state on iPhone should be false.")

                let keyboardCount = app.keyboards.count
                XCTAssertEqual(keyboardCount, 0, "The keyboard should not show on iPhone")
            }
    }

    func assertKeyboardBehaviorOnNewTab() {
        let addressBarElement = addressBar
        BaseTestCase().mozWaitForElementToExist(addressBarElement)

        XCTAssertFalse(addressBarElement.isSelected, "The URL should not have focus when tab is opened.")

        if UIDevice.current.userInterfaceIdiom == .pad {
            let keyboardVisible = app.keyboards.element.isVisible()
            XCTAssertTrue(keyboardVisible, "The keyboard should be shown on iPad for a new tab.")
        } else {
            let keyboardVisible = app.keyboards.element.isVisible()
            XCTAssertFalse(keyboardVisible, "The keyboard should not be shown on iPhone for a new tab.")
        }
    }

    func assertURLAndKeyboardUnfocused(expectedURLValue: String) {
        let urlElement = addressBar

        BaseTestCase().mozWaitForValueContains(urlElement, value: expectedURLValue)

        XCTAssertFalse(urlElement.isSelected, "The URL should not have focus when custom page is loaded.")
        XCTAssertFalse(app.keyboards.element.isVisible(), "The keyboard is shown.")
    }

    func tapOnAddressBar() {
        let urlElement = addressBar
        urlElement.waitAndTap()
    }

    func assertCancelButtonOnUrlBarExist() {
        BaseTestCase().mozWaitForElementToExist(cancelButton)
    }

    func assertPrivateBrowsingLabelExist() {
        let privateBrowsing = sel.PRIVATE_BROWSING.element(in: app)
        BaseTestCase().mozWaitForElementToExist(privateBrowsing)
    }

    func tapCancelButtonOnUrlBarExist() {
        cancelButton.waitAndTap()
    }

    func tapCancelButtonIfExist() {
        sel.CANCEL_BUTTON.element(in: app).tapIfExists()
    }

    func assertRFCLinkExist(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(sel.LINK_RFC_2606.element(in: app), timeout: timeout)
    }

    func addressToolbarContainValue(value: String) {
        BaseTestCase().mozWaitForValueContains(addressBar, value: value)
    }
}
