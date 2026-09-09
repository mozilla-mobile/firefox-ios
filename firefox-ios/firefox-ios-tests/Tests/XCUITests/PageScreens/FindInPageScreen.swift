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

    /// `FindInPageBar` stops counting past this and renders the total as "500+".
    private static let legacyTotalCap = 500

    private func grouped(_ value: Int) -> String {
        return NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal)
    }

    /// The result counter's wording depends on which find UI is in use. iOS 16+ gets the system
    /// find interaction, which reads "1 of 6" and groups thousands ("1 of 1,000"). Earlier versions
    /// get Firefox's own `FindInPageBar`, which reads "1/6" and caps the total at "500+".
    private func resultsCountText(current: Int, total: Int) -> String {
        if #available(iOS 16, *) {
            return "\(grouped(current)) of \(grouped(total))"
        } else if total > Self.legacyTotalCap {
            return "\(current)/\(Self.legacyTotalCap)+"
        } else {
            return "\(current)/\(total)"
        }
    }

    func assertResultsCountIsDisplayed(current: Int, total: Int) {
        let countText = resultsCountText(current: current, total: total)
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
