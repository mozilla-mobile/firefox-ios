// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class PocketTests: BaseTestCase {
    enum SwipeDirection {
        case up, down, left, right
    }

    func validatePocketStoriesCount() {
        let numPocketStories = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.Pocket.itemCell)
            .staticTexts.count
        if iPad() {
            XCTAssertTrue(numPocketStories > 7, "Expected at least 8 stories on iPad.")
        } else {
            XCTAssertTrue(numPocketStories > 6, "Expected at least 7 stories on iPhone.")
        }
    }

    func togglePocket(shouldEnable: Bool) {
        navigator.performAction(shouldEnable ? Action.TogglePocketInNewTab : Action.TogglePocketInNewTab)
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
    func testPocketEnabledByDefault() {
        navigator.goto(NewTabScreen)
        mozWaitForElementToExist(app.staticTexts[AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.pocket])
        XCTAssertEqual(
            app.staticTexts[AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.pocket].label,
            "Thought-Provoking Stories"
        )

        // There should be at least 8 stories on iPhone and 7 on iPad.
        // You can see more stories on iPhone by swiping left, but not all
        // stories are displayed at once.
        validatePocketStoriesCount()

        // Disable Pocket
        togglePocket(shouldEnable: false)
        mozWaitForElementToNotExist(app.staticTexts[AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.pocket])

        // Enable it again
        togglePocket(shouldEnable: true)
        mozWaitForElementToExist(app.staticTexts[AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.pocket])

        // Tap on the first Pocket element
        app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.Pocket.itemCell)
            .staticTexts.firstMatch.tap()
        waitUntilPageLoad()
        // The url textField is not empty
        let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        XCTAssertNotEqual(url.value as? String, "", "The url textField is empty")
        let backButton = app.buttons[AccessibilityIdentifiers.Toolbar.backButton]
        backButton.waitAndTap()
        if #unavailable(iOS 17) {
            backButton.waitAndTap()
        }

        scrollToElement(app.buttons[AccessibilityIdentifiers.FirefoxHomepage.Pocket.footerLearnMoreLabel],
                        direction: SwipeDirection.up,
                        maxSwipes: MAX_SWIPE)
        scrollToElement(app.cells.buttons["Discover more"], direction: .left, maxSwipes: MAX_SWIPE)

        app.cells.buttons["Discover more"].waitAndTap()
        waitUntilPageLoad()
        mozWaitForElementToExist(url)
        XCTAssertEqual(url.value as? String, "getpocket.com", "The url textField is empty")
    }
}
