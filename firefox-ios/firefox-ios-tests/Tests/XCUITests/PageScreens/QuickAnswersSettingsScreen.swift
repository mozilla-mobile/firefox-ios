// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

/// Page object for Settings → Quick Answers. Its switch carries the Quick Answers pref key as its
/// accessibility identifier, and the "Learn more" link sits in the section footer.
@MainActor
final class QuickAnswersSettingsScreen {
    private let app: XCUIApplication
    private let sel: QuickAnswersSettingsSelectorsSet

    private var navBar: XCUIElement { sel.NAVBAR.element(in: app) }
    private var quickAnswersSwitch: XCUIElement { sel.QUICK_ANSWERS_SWITCH.element(in: app) }
    private var footer: XCUIElement { sel.FOOTER.element(in: app) }
    private var learnMoreButton: XCUIElement { sel.LEARN_MORE_BUTTON.element(in: app) }
    private var switchTitle: XCUIElement { sel.QUICK_ANSWERS_SWITCH_TITLE.element(in: app) }

    init(app: XCUIApplication, selectors: QuickAnswersSettingsSelectorsSet = QuickAnswersSettingsSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func assertScreenShown(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(navBar, timeout: timeout)
    }

    func assertQuickAnswersSwitchIsOn() {
        BaseTestCase().waitForElementsToExist([quickAnswersSwitch, switchTitle])
        let value = quickAnswersSwitch.value as? String
        XCTAssertEqual(value, "1", "Expected 'Quick Answers' switch to be ON (1), but got \(String(describing: value))")
    }

    /// Asserts the description and, on the line under it, the "Learn more" link drawn in blue.
    func assertDescriptionWithBlueLearnMoreLink(timeout: TimeInterval = TIMEOUT) {
        let link = learnMoreButton
        BaseTestCase().waitForElementsToExist([footer, link])
        XCTAssertTrue(link.isBelow(element: footer),
                      "'Learn more' (\(link.frame)) is not below the description (\(footer.frame))")

        let blueHues = 190.0...260.0
        let minimumTextShare = 0.005
        let isBlue = NSPredicate { _, _ in
            let blue = link.shareOfPixels(inHueRange: blueHues)
            let otherColours = link.saturatedPixelRatio(threshold: 0.2) - blue
            return blue > minimumTextShare && blue > otherColours
        }
        guard link.waitFor(isBlue, timeout: timeout) else {
            let blue = String(format: "%.3f", link.shareOfPixels(inHueRange: blueHues))
            let saturated = String(format: "%.3f", link.saturatedPixelRatio(threshold: 0.2))
            XCTFail("Expected the 'Learn more' link to be blue, blue share \(blue), coloured share \(saturated)")
            return
        }
    }

    func tapLearnMore() {
        learnMoreButton.waitAndTap()
    }

    /// The link opens the SUMO article in a web view pushed over this screen, which has no address bar
    /// to read, so the page is recognised by the Mozilla Support logo and the article heading.
    func assertSumoPageOpened(timeout: TimeInterval = TIMEOUT_LONG) {
        BaseTestCase().waitForElementsToExist(
            [sel.SUMO_LOGO_LINK.element(in: app), sel.SUMO_ARTICLE_HEADING.element(in: app)],
            timeout: timeout
        )
        BaseTestCase().mozWaitForElementToNotExist(quickAnswersSwitch)
    }
}
