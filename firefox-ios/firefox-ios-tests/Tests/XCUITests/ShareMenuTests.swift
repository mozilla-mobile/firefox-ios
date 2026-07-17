// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Common

let pdfUrl = "https://storage.googleapis.com/mobile_test_assets/public/lorem_ipsum.pdf"

class ShareMenuTests: FeatureFlaggedTestBase {
    // https://mozilla.testrail.io/index.php?/cases/view/2863631
    func testShareNormalWebsiteTabViaReminders() {
        app.launch()
        // Couldn't find a way to tap on reminders on iOS 16
        if #available(iOS 17, *) {
            reachShareMenuLayoutAndSelectOption(option: "Reminders")
            // The URL of the website is added in a new reminder
            waitForElementsToExist(
                [
                    app.navigationBars["Reminders"],
                    app.links["http://" + url_3]
                ],
                timeout: TIMEOUT_LONG
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864049
    func testShareNormalWebsitePrint() {
        app.launch()
        reachShareMenuLayoutAndSelectOption(option: "Print")
        validatePrintLayout()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864047
    func testShareNormalWebsiteSendLinkToDevice() {
        app.launch()
        reachShareMenuLayoutAndSelectOption(option: "Send Link to Device")
        // If not signed in, the browser prompts you to sign in
        waitForElementsToExist(
            [
                app.staticTexts[sendLinkMsg1],
                app.staticTexts[sendLinkMsg2]
            ],
            timeout: TIMEOUT_LONG
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864048
    func testShareNormalWebsiteMarkup() {
        app.launch()
        reachShareMenuLayoutAndSelectOption(option: "Markup")
        validateMarkupTool()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864046
    func testShareNormalWebsiteCopyUrl() {
        app.launch()
        reachShareMenuLayoutAndSelectOption(option: "Copy")
        openNewTabAndValidateURLisPaste(url: url_3)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864073
    func testShareWebsiteReaderModeReminders() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launchArguments.append(LaunchArguments.SkipAppleIntelligence)
        app.launch()
        if #available(iOS 17, *) {
            reachReaderModeShareMenuLayoutAndSelectOption(option: "Reminders")
            // The URL of the website is added in a new reminder
            waitForElementsToExist(
                [
                    app.navigationBars["Reminders"],
                    app.links.elementContainingText(TestPages.mozillaBook)
                ],
                timeout: TIMEOUT_LONG
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864082
    func testShareWebsiteReaderModePrint() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launchArguments.append(LaunchArguments.SkipAppleIntelligence)
        app.launch()
        reachReaderModeShareMenuLayoutAndSelectOption(option: "Print")
        validatePrintLayout()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864079
    func testShareWebsiteReaderModeCopy() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launchArguments.append(LaunchArguments.SkipAppleIntelligence)
        app.launch()
        reachReaderModeShareMenuLayoutAndSelectOption(option: "Copy")
        openNewTabAndValidateURLisPaste(url: TestPages.mozillaBook)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864080
    func testShareWebsiteReaderModeSendLink() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launchArguments.append(LaunchArguments.SkipAppleIntelligence)
        app.launch()
        reachReaderModeShareMenuLayoutAndSelectOption(option: "Send Link to Device")
        // If not signed in, the browser prompts you to sign in
        waitForElementsToExist(
            [
                app.staticTexts[sendLinkMsg1],
                app.staticTexts[sendLinkMsg2]
            ],
            timeout: TIMEOUT_LONG
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864081
    func testShareWebsiteReaderModeMarkup() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launchArguments.append(LaunchArguments.SkipAppleIntelligence)
        app.launch()
        reachReaderModeShareMenuLayoutAndSelectOption(option: "Markup")
        validateMarkupTool()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864065
    func testSharePdfFilePrint() {
        app.launch()
        reachShareMenuLayoutAndSelectOption(option: "Print", url: pdfUrl)
        validatePrintLayout()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864064
    func testSharePdfFileMarkup() {
        app.launch()
        reachShareMenuLayoutAndSelectOption(option: "Markup", url: pdfUrl)
        validateMarkupTool()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864066
    func testSharePdfFileSaveToFile() {
        app.launch()
        if #available(iOS 17, *) {
            reachShareMenuLayoutAndSelectOption(option: "Save to Files", url: pdfUrl)
            let saveButton = app.buttons["Save"]
            var attempts = 2
            while !saveButton.mozWaitForElementToExist(timeout: TIMEOUT, failOnTimeout: false) && attempts > 0 {
                let saveToFilesCell = app.collectionViews.cells["Save to Files"]
                guard saveToFilesCell.exists else { break }
                saveToFilesCell.tapOnApp()
                attempts -= 1
            }
            mozWaitForElementToExist(saveButton, timeout: TIMEOUT_LONG)
            saveButton.waitAndTap()
            waitForTabsButton()
        }
    }

    private func validatePrintLayout() {
        // The Print dialog appears. It can take a little longer to load, so wait longer.
        waitForElementsToExist(
            [
                app.staticTexts["Printer"],
                app.staticTexts["Paper Size"]
            ],
            timeout: TIMEOUT_LONG
        )
        if #available(iOS 16, *) {
            mozWaitForElementToExist(app.staticTexts["Layout"], timeout: TIMEOUT_LONG)
        }
        if #available(iOS 17, *) {
            mozWaitForElementToExist(app.staticTexts["Options"], timeout: TIMEOUT_LONG)
        } else {
            mozWaitForElementToExist(app.staticTexts["Print Options"], timeout: TIMEOUT_LONG)
        }
    }

    private func validateMarkupTool() {
        // The Markup tool opens. It can take a little longer to load, so wait longer.
        if #available(iOS 26, *) {
            if !iPad() {
                // The navbar overflow label varies ("More" -> "View More", MTE-5253) and the
                // palette sometimes opens without one; only tap the label that's actually present.
                if !app.buttons["Markup"].mozWaitForElementToExist(timeout: TIMEOUT, failOnTimeout: false) {
                    let overflow = app.navigationBars.buttons["More"].exists
                        ? app.navigationBars.buttons["More"]
                        : app.navigationBars.buttons["View More"]
                    if overflow.exists {
                        overflow.waitAndTap()
                    }
                }
                mozWaitForElementToExist(app.buttons["Markup"], timeout: TIMEOUT_LONG)
                mozWaitForElementToExist(app.buttons["Close"], timeout: TIMEOUT_LONG)
                mozWaitForElementToExist(app.otherElements["Drawing-Palette"], timeout: TIMEOUT_LONG)
            } else {
                // On iPad the Markup palette renders inline with no navbar overflow button;
                // the Markup control is a switch, not a button.
                mozWaitForElementToExist(app.switches["Markup"], timeout: TIMEOUT_LONG)
                mozWaitForElementToExist(app.buttons["close"], timeout: TIMEOUT_LONG)
            }
        } else {
            if !app.switches["Markup"].mozWaitForElementToExist(timeout: TIMEOUT_LONG, failOnTimeout: false) {
                mozWaitForElementToExist(app.buttons["Markup"], timeout: TIMEOUT_LONG)
            }
        }
    }

    private func reachReaderModeShareMenuLayoutAndSelectOption(option: String) {
        navigator.openURL(path(forTestPage: TestPages.mozillaBook))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        mozWaitForElementToNotExist(app.staticTexts["Fennec pasted from XCUITests-Runner"])
        app.buttons["Reader View"].waitAndTap()
        // Open the main menu and tap the Share option
        navigator.performAction(Action.ShareBrowserTabMenuOption)
        selectShareSheetOption(option)
    }

    private func reachShareMenuLayoutAndSelectOption(option: String, url: String = url_3) {
        if !iPad() {
            navigator.nowAt(HomePanelsScreen)
            navigator.goto(URLBarOpen)
        }
        // Open a website in the browser
        navigator.openURL(url)
        waitUntilPageLoad()
        // Open the main menu and tap the Share option
        navigator.performAction(Action.ShareBrowserTabMenuOption)
        selectShareSheetOption(option)
    }

    private func selectShareSheetOption(_ option: String) {
        if #available(iOS 26, *) {
            let optionCell = app.collectionViews.cells[option]
            if !optionCell.mozWaitForElementToExist(timeout: TIMEOUT, failOnTimeout: false) {
                app.scrollViews.cells["View More"].waitAndTap(timeout: 10)
            }
        }
        if #available(iOS 16, *) {
            mozWaitForElementToExist(app.collectionViews.cells[option])
            app.collectionViews.cells[option].tapOnApp()
        } else {
            app.buttons[option].waitAndTap()
        }
    }
}
