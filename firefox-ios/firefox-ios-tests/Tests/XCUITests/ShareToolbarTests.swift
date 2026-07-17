// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Common

let sendLinkMsg1 = "You are not signed in to your account."
let sendLinkMsg2 = "Please open Firefox, go to Settings and sign in to continue."

class ShareToolbarTests: FeatureFlaggedTestBase {
    // https://mozilla.testrail.io/index.php?/cases/view/2864270
    func testShareNormalWebsiteTabReminders() {
        app.launch()
        if #available(iOS 17, *) {
            tapToolbarShareButtonAndSelectOption(option: "Reminders")
            // The URL of the website is added in a new reminder
            waitForElementsToExist(
                [
                    app.navigationBars["Reminders"],
                    app.links["http://" + url_3]
                ]
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864279
    func testShareNormalWebsitePrint() {
        app.launch()
        tapToolbarShareButtonAndSelectOption(option: "Print")
        validatePrintLayout()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864277
    func testShareNormalWebsiteSendLinkToDevice() {
        app.launch()
        tapToolbarShareButtonAndSelectOption(option: "Send Link to Device")
        // If not signed in, the browser prompts you to sign in
        waitForElementsToExist(
            [
                app.staticTexts[sendLinkMsg1],
                app.staticTexts[sendLinkMsg2]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864278
    func testShareNormalWebsiteMarkup() {
        app.launch()
        tapToolbarShareButtonAndSelectOption(option: "Markup")
        validateMarkupTool()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864276
    func testShareNormalWebsiteCopyUrl() {
        app.launch()
        tapToolbarShareButtonAndSelectOption(option: "Copy")
        openNewTabAndValidateURLisPaste(url: url_3)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864301
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
                ]
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864310
    func testShareWebsiteReaderModePrint() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launchArguments.append(LaunchArguments.SkipAppleIntelligence)
        app.launch()
        reachReaderModeShareMenuLayoutAndSelectOption(option: "Print")
        validatePrintLayout()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864307
    func testShareWebsiteReaderModeCopy() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launchArguments.append(LaunchArguments.SkipAppleIntelligence)
        app.launch()
        reachReaderModeShareMenuLayoutAndSelectOption(option: "Copy")
        openNewTabAndValidateURLisPaste(url: TestPages.mozillaBook)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864308
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
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864309
    func testShareWebsiteReaderModeMarkup() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launchArguments.append(LaunchArguments.SkipAppleIntelligence)
        app.launch()
        reachReaderModeShareMenuLayoutAndSelectOption(option: "Markup")
        validateMarkupTool()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864293
    func testSharePdfFilePrint() {
        app.launch()
        tapToolbarShareButtonAndSelectOption(option: "Print", url: pdfUrl)
        validatePrintLayout()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864292
    func testSharePdfFileMarkup() {
        app.launch()
        tapToolbarShareButtonAndSelectOption(option: "Markup", url: pdfUrl)
        validateMarkupTool()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864294
    func testSharePdfFileSaveToFile() {
        app.launch()
        if #available(iOS 17, *) {
            tapToolbarShareButtonAndSelectOption(option: "Save to Files", url: pdfUrl)
            // Anchor on the Files picker's own Save button rather than a location label such as
            // "On My iPhone": the picker opens on whichever location was last used (iCloud Drive,
            // On My iPhone, …), so the label is not reliably present, whereas Save always is.
            // The share-sheet tap does not always open the picker on CI, so re-tap it if needed.
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
        // The Print dialog appears
        waitForElementsToExist(
            [
                app.staticTexts["Printer"],
                app.staticTexts["Paper Size"]
            ]
        )
        if #available(iOS 16, *) {
            mozWaitForElementToExist(app.staticTexts["Layout"])
        }
        if #available(iOS 17, *) {
            mozWaitForElementToExist(app.staticTexts["Options"])
        } else {
            mozWaitForElementToExist(app.staticTexts["Print Options"])
        }
    }

    private func validateMarkupTool() {
        // The Markup tool opens
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
                mozWaitForElementToExist(app.buttons["Markup"])
                mozWaitForElementToExist(app.buttons["Close"])
                mozWaitForElementToExist(app.otherElements["Drawing-Palette"])
            } else {
                mozWaitForElementToExist(app.switches["Markup"])
                mozWaitForElementToExist(app.buttons["close"])
            }
        } else {
            mozWaitForElementToExist(app.switches["Markup"])
            mozWaitForElementToExist(app.buttons["Done"])
        }
    }

    private func reachReaderModeShareMenuLayoutAndSelectOption(option: String) {
        navigator.openURL(path(forTestPage: TestPages.mozillaBook))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        mozWaitForElementToNotExist(app.staticTexts["Fennec pasted from XCUITests-Runner"])
        app.buttons["Reader View"].waitAndTap()
        app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].waitAndTap()
        selectShareSheetOption(option)
    }

    private func tapToolbarShareButtonAndSelectOption(option: String, url: String = url_3) {
        if !iPad() {
            navigator.nowAt(HomePanelsScreen)
            navigator.goto(URLBarOpen)
        }
        navigator.openURL(url)
        waitUntilPageLoad()
        app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].waitAndTap()
        selectShareSheetOption(option)
    }

    /// Selects `option` from the system share sheet, expanding via "View More" only when needed.
    ///
    /// The instant `.exists` check used previously raced the share-sheet presentation animation:
    /// when the option was about to appear directly, the check was still false and the helper went
    /// hunting for a "View More" expander that never showed, timing out. Wait for the option first
    /// and only fall back to expanding the sheet when it genuinely isn't in the collapsed layout.
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
