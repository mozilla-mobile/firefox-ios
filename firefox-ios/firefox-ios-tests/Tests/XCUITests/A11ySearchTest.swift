// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

class A11ySearchTest: BaseTestCase {
    private func typeTextAndValidateSearchSuggestions(text: String, isSwitchOn: Bool) {
        typeOnSearchBar(text: text)
        // Search suggestions are shown
        if isSwitchOn {
            mozWaitForElementToExist(app.staticTexts.elementContainingText("google"))
            XCTAssertTrue(app.staticTexts.elementContainingText("google").exists)
            mozWaitForElementToExist(app.tables.cells.staticTexts["g"])
            XCTAssertTrue(app.tables.cells.count >= 4)
        } else {
            mozWaitForElementToNotExist(app.tables.buttons[StandardImageIdentifiers.Large.appendUpLeft])
            mozWaitForElementToExist(app.tables["SiteTable"].staticTexts["Firefox Suggest"])
            XCTAssertTrue(app.tables.cells.count <= 3)
        }
    }

    private func typeOnSearchBar(text: String) {
        app.textFields.firstMatch.waitAndTap()
        app.textFields.firstMatch.tapAndTypeText(text)
    }

    private func createNewTabAfterModifyingSearchSuggestions(turnOnSwitch: Bool) {
        navigator.goto(SearchSettings)
        turnOnOffSearchSuggestions(turnOnSwitch: turnOnSwitch)
        navigator.goto(NewTabScreen)
        navigator.createNewTab()
        navigator.nowAt(NewTabScreen)
    }

    private func turnOnOffSearchSuggestions(turnOnSwitch: Bool) {
        let showSearchSuggestions = app.switches[AccessibilityIdentifiers.Settings.Search.showSearchSuggestions]
        mozWaitForElementToExist(showSearchSuggestions)
        let switchValue = showSearchSuggestions.value
        if switchValue as? String == "0", true && turnOnSwitch == true {
            showSearchSuggestions.tap()
        } else if switchValue as? String == "1", true && turnOnSwitch == false {
            showSearchSuggestions.tap()
        }
    }

    func testA11ySearchSuggestions() throws {
            guard #available(iOS 17.0, *) else { return }

            // Tap on URL Bar and type "g"
            navigator.nowAt(NewTabScreen)
            typeTextAndValidateSearchSuggestions(text: "g", isSwitchOn: true)

            // Tap on the "Append Arrow button"
            app.tables.buttons[StandardImageIdentifiers.Large.appendUpLeft].firstMatch.tap()

            // The search suggestion fills the URL bar but does not conduct the search
            waitForValueContains(urlBarAddress, value: "g")

            // Check accessibility
            // swiftlint:disable empty_count
            guard iPad() == false else { return }
            try app.performAccessibilityAudit { issue in
                guard let element = issue.element else { return false }

                var shouldIgnore = false
                // number of tabs in navigation toolbar
                let isDynamicTypeTabButton = element.label == "1" &&
                issue.auditType == .dynamicType

                // clipped text on homepage
                let homepage = self.app.collectionViews[AccessibilityIdentifiers.FirefoxHomepage.collectionView]
                    .firstMatch
                let isDescendantOfHomepage = homepage.descendants(matching: element.elementType)
                    .containing(NSPredicate(format: "label CONTAINS[c] '\(element.label)'")).count > 0
                let isClippedTextOnHomepage = issue.auditType == .textClipped && isDescendantOfHomepage

                // clipped text in search suggestions
                let suggestions = self.app.tables["SiteTable"].firstMatch
                let isDescendantOfSuggestions = suggestions.descendants(matching: element.elementType)
                    .containing(NSPredicate(format: "label CONTAINS[c] '\(element.label)'")).count > 0
                let isClippedTextInSuggestions = issue.auditType == .textClipped && isDescendantOfSuggestions

                // text in the address toolbar text field
                let isAddressField = element.elementType == .textField && issue.auditType == .textClipped

                if isDynamicTypeTabButton || isClippedTextOnHomepage || isClippedTextInSuggestions || isAddressField {
                    shouldIgnore = true
                }

                return shouldIgnore
            }
                // swiftlint:enable empty_count
        }
}
