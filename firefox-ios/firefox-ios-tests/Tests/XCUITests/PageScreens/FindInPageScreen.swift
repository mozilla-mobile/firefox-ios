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

    private var doneButton: XCUIElement {
        return sel.FIND_DONE_BUTTON.element(in: app)
    }

    private var firstPageText: XCUIElement {
        return BrowserSelectors().WEB_VIEW.element(in: app).staticTexts.firstMatch
    }

    /// Asserts the bar is shown with the search field focused and the keyboard up, without tapping it.
    func assertFindInPageBarIsReadyForInput(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().waitForElementsToExist([nextButton, previousButton, searchField], timeout: timeout)
        XCTAssertTrue(searchField.waitForKeyboardFocus(timeout: timeout), "The search field should have keyboard focus.")
        BaseTestCase().mozWaitForElementToExist(app.keyboards.element, timeout: timeout)
    }

    func tapDone() {
        doneButton.waitAndTap()
    }

    func firstPageTextOriginY() -> CGFloat {
        BaseTestCase().mozWaitForElementToExist(firstPageText)
        return firstPageText.frame.minY
    }

    /// Asserts the web content moved up from `originY`, i.e. the page scrolled down to a later match.
    func assertPageScrolledDown(from originY: CGFloat, timeout: TimeInterval = TIMEOUT) {
        let element = firstPageText
        let predicate = NSPredicate { _, _ in element.frame.minY < originY }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "The page did not scroll to the selected match.")
    }

    func assertKeyboardIsDismissed(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToNotExist(app.keyboards.element, timeout: timeout)
    }

    func assertSearchBarDisappeared(searchKeyword: String, timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToNotExist(searchField, timeout: timeout)
    }
}
