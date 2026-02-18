// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class BrowserScreen {
    private let app: XCUIApplication
    private let sel: BrowserSelectorsSet

    init(app: XCUIApplication, selectors: BrowserSelectorsSet = BrowserSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var addressBar: XCUIElement { sel.ADDRESS_BAR.element(in: app) }
    private var cancelButton: XCUIElement { sel.CANCEL_BUTTON_URL_BAR.element(in: app) }
    private var bookText: XCUIElement { sel.BOOK_OF_MOZILLA_TEXT.element(in: app) }
    private var bookTextInTable: XCUIElement { sel.BOOK_OF_MOZILLA_TEXT_IN_TABLE.element(in: app) }

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

    func dismissKeyboardIfVisible(maxTaps: Int = 3) {
        let keyboard = app.keyboards.firstMatch
        var remainingTaps = maxTaps

        BaseTestCase().mozWaitForElementToExist(cancelButton)

        while keyboard.exists && remainingTaps > 0 {
            cancelButton.waitAndTap()
            remainingTaps -= 1
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

    func typeOnSearchBar(text: String) {
        addressBar.typeText(text)
    }

    func assertCancelButtonOnUrlBarExists() {
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

    func tapOnBookOfMozilla() {
        bookText.waitAndTap()
    }

    func waitForBookOfMozillaToDisappear(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToNotExist(bookTextInTable, timeout: timeout)
    }

    func assertAddressBar_LockIconExist(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(sel.ADDRESSTOOLBAR_LOCKICON.element(in: app))
    }

    func assertAddressBarHasKeyboardFocus() {
        let addressBar = sel.ADDRESS_BAR.element(in: app)
        BaseTestCase().mozWaitForElementToExist(addressBar)

        let hasFocus = addressBar.value(forKey: "hasKeyboardFocus") as? Bool ?? false
        XCTAssertTrue(hasFocus, "Expected the address bar to have keyboard focus, but it doesn't.")
    }

    func longPressLink(named linkName: String, duration: TimeInterval = 2.0) {
        let link = sel.linkElement(named: linkName).element(in: app)
        BaseTestCase().mozWaitForElementToExist(link)
        link.press(forDuration: duration)
    }

    func waitForLinkPreview(named preview: String) {
        let previewLabel = sel.linkPreview(named: preview).element(in: app)
        BaseTestCase().mozWaitForElementToExist(previewLabel)
    }

    func longPressFirstLink() {
        let firstLink = app.webViews.links.firstMatch
        BaseTestCase().mozWaitForElementToExist(firstLink)
        firstLink.press(forDuration: 1)
    }

    func assertTypeSuggestText(text: String) {
        let suggestedText = app.tables.firstMatch.cells.staticTexts[text]
        BaseTestCase().mozWaitForElementToExist(suggestedText)
    }

    func assertNumberOfSuggestedLines(expectedLines: Int) {
        let suggestedLines = app.tables.firstMatch.cells
        XCTAssertEqual(suggestedLines.count, expectedLines)
    }

    func assertAddressBarExists(duration: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(addressBar, timeout: duration)
    }

    func getAddressBarElement() -> XCUIElement {
        BaseTestCase().mozWaitForElementToExist(addressBar)
        return addressBar
    }

    func tapCancelButtonOnUrlWithRetry() {
        cancelButton.tapWithRetry()
    }

    func assertWebPageText(with text: String) {
        let text = sel.webPageElement(with: text).element(in: app)
        BaseTestCase().mozWaitForElementToExist(text)
    }

    func tapWebViewTextIfExists(text: String) {
        app.webViews.staticTexts[text].tapIfExists()
    }

    func dismissMicrosurveyIfExists() {
        let microsurveyCloseButton = sel.MICROSURVEY_CLOSE_BUTTON.element(in: app)
        microsurveyCloseButton.tapIfExists()
    }

    func assertWebViewLoaded(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(app.webViews.firstMatch, timeout: timeout)
    }

    func tapWebViewButton(buttonText: String) {
        app.webViews.buttons[buttonText].waitAndTap()
    }

    func assertWebElements(shouldExist: Bool = true, _ elements: XCUIElement..., timeout: TimeInterval = TIMEOUT) {
        let base = BaseTestCase()
        for element in elements {
            if shouldExist {
                base.mozWaitForElementToExist(element, timeout: timeout)
            } else {
                base.mozWaitForElementToNotExist(element, timeout: timeout)
            }
        }
    }

    func assertSuggestedLinesNotEmpty() {
        let suggestedLines = app.tables.firstMatch.cells
        XCTAssertNotEqual(suggestedLines.count, 0, "Expected suggestions to appear")
    }

    func tapSaveButtonIfExist() {
        let saveButton = sel.SAVE_BUTTON.element(in: app)
        saveButton.tapIfExists()
    }
 }
