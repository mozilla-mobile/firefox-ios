// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class NewTabSettingsScreen {
    private let app: XCUIApplication
    private let sel: NewTabSettingsSelectorsSet

    init(app: XCUIApplication, selectors: NewTabSettingsSelectorsSet = NewTabSettingsSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var customURLTextField: XCUIElement { sel.CUSTOM_URL_TEXT_FIELD.element(in: app) }

    func assertDefaultOptionsAreVisible(timeout: TimeInterval = TIMEOUT) {
        let requiredElements = [
            sel.NAVIGATION_BAR.element(in: app),
            sel.FIREFOX_HOME_CELL.element(in: app),
            sel.BLANK_PAGE_CELL.element(in: app),
            sel.CUSTOM_URL_CELL.element(in: app)
        ]

        BaseTestCase().waitForElementsToExist(requiredElements, timeout: timeout)
    }

    func tapBlankPageOption() {
        let blankPageCell = sel.BLANK_PAGE_CELL.element(in: app)
        blankPageCell.waitAndTap()
    }

    func assertNewTabNavigationBarIsVisible(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(sel.NAVIGATION_BAR.element(in: app))
    }

    func selectCustomURLOption() {
        let customURLCell = sel.CUSTOM_URL_CELL.element(in: app)
        customURLCell.waitAndTap()
    }

    func assertURLTextFieldPlaceholderContains(value: String) {
        let textField = customURLTextField
        BaseTestCase().mozWaitForValueContains(textField, value: value)
    }

    func typeCustomURL(_ url: String) {
        let textField = customURLTextField
        textField.waitAndTap()
        textField.typeText(url)
    }

    func assertURLTypedValueIsCorrect(_ expectedURL: String) {
        let textField = customURLTextField

        BaseTestCase().mozWaitForValueContains(textField, value: expectedURL)
        guard let actualValue = textField.value as? String else {
            XCTFail("Failed to retrieve the value from the custom URL text field")
            return
        }
        XCTAssertEqual(actualValue, expectedURL)
    }
}
