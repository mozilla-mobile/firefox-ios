// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class FindInPageScreen {
    private let app: XCUIApplication
    private let sel: FindInPageSelectorsSet

    init(app: XCUIApplication, selectors: FindInPageSelectorsSet = FindInPageSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var searchField: XCUIElement {
        if #available(iOS 16, *) {
            return sel.FIND_SEARCH_FIELD_IOS.element(in: app)
        } else {
            return sel.FIND_SEARCH_FIELD_LEGACY.element(in: app)
        }
    }

    func waitForFindInPageBarToAppear(timeout: TimeInterval = TIMEOUT) {
        let requiredElements = [
            sel.FIND_NEXT_BUTTON.element(in: app),
            sel.FIND_PREVIOUS_BUTTON.element(in: app),
            searchField
        ]

        BaseTestCase().waitForElementsToExist(requiredElements, timeout: timeout)
        searchField.waitAndTap()
    }

    func searchForText(_ text: String) {
        searchField.waitAndTap()
        searchField.typeText(text)
    }

    func assertResultsCountIsDisplayed(_ countText: String) {
        let resultsLabel = sel.resultsCount(text: countText).element(in: app)

        BaseTestCase().mozWaitForElementToExist(resultsLabel)
        XCTAssertTrue(resultsLabel.exists, "Expected result count label '\(countText)' not found.")
    }

    private var nextButton: XCUIElement {
        return sel.FIND_NEXT_BUTTON.element(in: app)
    }

    private var previousButton: XCUIElement {
        return sel.FIND_PREVIOUS_BUTTON.element(in: app)
    }

    func tapNextResult() {
        nextButton.waitAndTap()
    }

    func tapPreviousResult() {
        previousButton.waitAndTap()
    }

    func assertSearchBarDisappeared(searchKeyword: String, timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToNotExist(searchField, timeout: timeout)
    }
}
