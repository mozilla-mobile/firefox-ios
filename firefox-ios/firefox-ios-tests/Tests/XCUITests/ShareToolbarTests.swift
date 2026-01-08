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
                    app.links.elementContainingText("test-mozilla-book.html")
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
        openNewTabAndValidateURLisPaste(url: "test-mozilla-book.html")
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
            if !iPad() {
                mozWaitForElementToExist(app.staticTexts["On My iPhone"])
            } else {
                mozWaitForElementToExist(app.staticTexts["On My iPad"])
            }
            app.buttons["Save"].waitAndTap()
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
            if iPad() {
                app.navigationBars.buttons["More"].waitAndTap()
            }
            // iOS 26: The markup isn't shown in debug description
            // https://github.com/mozilla-mobile/firefox-ios/issues/31552
        } else {
            mozWaitForElementToExist(app.switches["Markup"])
            mozWaitForElementToExist(app.buttons["Done"])
        }
    }

    private func reachReaderModeShareMenuLayoutAndSelectOption(option: String) {
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        mozWaitForElementToNotExist(app.staticTexts["Fennec pasted from XCUITests-Runner"])
        app.buttons["Reader View"].waitAndTap()
        app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].waitAndTap()
        if #available(iOS 26, *), !app.collectionViews.cells[option].exists {
            app.cells["actionGroupCell"].staticTexts["More"].waitAndTap(timeout: 10)
        }
        if #available(iOS 16, *) {
            mozWaitForElementToExist(app.collectionViews.cells[option])
            app.collectionViews.cells[option].tapOnApp()
        } else {
            app.buttons[option].waitAndTap()
        }
    }

    private func tapToolbarShareButtonAndSelectOption(option: String, url: String = url_3) {
        if !iPad() {
            navigator.nowAt(HomePanelsScreen)
            navigator.goto(URLBarOpen)
        }
        navigator.openURL(url)
        waitUntilPageLoad()
        app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].waitAndTap()
        if #available(iOS 26, *), !app.collectionViews.cells[option].exists {
            app.cells["actionGroupCell"].staticTexts["More"].waitAndTap(timeout: 10)
        }
        if #available(iOS 16, *) {
            mozWaitForElementToExist(app.collectionViews.cells[option])
            app.collectionViews.cells[option].tapOnApp()
        } else {
            app.buttons[option].waitAndTap()
        }
    }
}
