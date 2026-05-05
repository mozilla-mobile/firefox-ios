// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

class StoryTests: BaseTestCase {
    enum SwipeDirection {
        case up, down, left, right
    }

    func validateNewsStoriesCount() {
        let numNewsStories = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.Pocket.itemCell)
            .staticTexts.count
        XCTAssertTrue(numNewsStories > 1, "Expected at least 2 stories.")
    }

    func toggleStories(shouldEnable: Bool) {
        navigator.performAction(shouldEnable ? Action.ToggleStoriesInNewTab : Action.ToggleStoriesInNewTab)
        navigator.goto(NewTabScreen)
    }

    func scrollToElement(_ element: XCUIElement, direction: SwipeDirection, maxSwipes: Int = 5) {
        var swipeCount = 0
        while !element.exists && swipeCount < maxSwipes {
            switch direction {
            case .up:
                app.swipeUp()
            case .down:
                app.swipeDown()
            case .left:
                app.swipeLeft()
            case .right:
                app.swipeRight()
            }
            swipeCount += 1
        }
        XCTAssertTrue(element.exists, "Element \(element) not found after \(maxSwipes) swipes.")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306924
    func testNewsStoriesEnabledByDefault() {
        navigator.goto(NewTabScreen)
        app.partialSwipeUp(distance: 0.2)
        mozWaitForElementToExist(app.otherElements["News"])

        validateNewsStoriesCount()

        // Disable Stories
        toggleStories(shouldEnable: false)
        mozWaitForElementToNotExist(app.staticTexts[AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.merino])

        // Enable it again
        toggleStories(shouldEnable: true)
        app.partialSwipeUp(distance: 0.2)
        mozWaitForElementToExist(app.otherElements["News"])

        // Tap on the first News element
        app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.Pocket.itemCell)
            .staticTexts.firstMatch.tap()
        waitUntilPageLoad()
        // The url textField is not empty
        let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        XCTAssertNotEqual(url.value as? String, "", "The url textField is empty")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2855360
    func testValidateNewsContextMenu() {
        navigator.goto(NewTabScreen)
        app.partialSwipeUp(distance: 0.2)
        mozWaitForElementToExist(app.otherElements["News"])
        // Long tap on one of the stories
        let newsCell = AccessibilityIdentifiers.FirefoxHomepage.Pocket.itemCell
        app.collectionViews.cells.matching(identifier: newsCell).staticTexts.firstMatch.press(forDuration: 1.5)
        // Validate Context menu
        let contextMenuTable = app.tables["Context Menu"]
        waitForElementsToExist(
            [
                contextMenuTable.otherElements.staticTexts.firstMatch,
                contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.plus],
                contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.privateMode],
                contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.bookmark],
                contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.share]
            ]
        )
    }
}
