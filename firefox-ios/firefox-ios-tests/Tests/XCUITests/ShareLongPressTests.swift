// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class ShareLongPressTests: BaseTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2864317
    func testShareNormalWebsiteTabReminders() {
        if #available(iOS 17, *) {
            longPressPocketAndReachShareOptions(option: "Reminders")
            // The URL of the website is added in a new reminder
            waitForElementsToExist(
                [
                    app.navigationBars["Reminders"],
                    app.links.elementContainingText("https://www")
                ]
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864324
    func testShareNormalWebsiteSendLinkToDevice() {
        longPressPocketAndReachShareOptions(option: "Send Link to Device")
        // If not signed in, the browser prompts you to sign in
        waitForElementsToExist(
            [
                app.staticTexts[sendLinkMsg1],
                app.staticTexts[sendLinkMsg2]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864323
    func testShareNormalWebsiteCopyUrl() {
        longPressPocketAndReachShareOptions(option: "Copy")
        app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.Pocket.itemCell)
            .staticTexts.firstMatch.waitAndTap()
        openNewTabAndValidateURLisPaste(url: "https://www")
    }

    private func longPressPocketAndReachShareOptions(option: String) {
        navigator.goto(NewTabScreen)
        // Long tap on the first Pocket element
        app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.Pocket.itemCell)
            .staticTexts.firstMatch.press(forDuration: 1.5)
        app.tables["Context Menu"].cells.otherElements["shareLarge"].waitAndTap()
        app.collectionViews.cells[option].waitAndTap()
    }
}
