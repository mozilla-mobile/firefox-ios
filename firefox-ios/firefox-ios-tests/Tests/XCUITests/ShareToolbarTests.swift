// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Common

let sendLinkMsg1 = "You are not signed in to your account."
let sendLinkMsg2 = "Please open Firefox, go to Settings and sign in to continue."

let saveToFilesOption = "Save to Files"
// The share sheet names a shared file by its file name; the picker pre-fills the name without extension.
let pdfTestPdfName = PDF_website["tabTitle"]!
let loremIpsumPdfName = PDF_website["secondTabTitle"]!
let pdfTestPdfBaseName = (pdfTestPdfName as NSString).deletingPathExtension
let loremIpsumPdfBaseName = (loremIpsumPdfName as NSString).deletingPathExtension

class ShareToolbarTests: FeatureFlaggedTestBase {
    private var browser: BrowserScreen!
    private var toolbar: ToolbarScreen!
    private var shareSheet: PhotonActionSheetScreen!
    private var documentPicker: DocumentPickerScreen!
    private var history: HistoryScreen!
    private var downloads: DownloadsScreen!
    private var tabTray: TabTrayScreen!

    override func setUp() async throws {
        try await super.setUp()

        browser = BrowserScreen(app: app)
        toolbar = ToolbarScreen(app: app)
        shareSheet = PhotonActionSheetScreen(app: app)
        documentPicker = DocumentPickerScreen(app: app)
        history = HistoryScreen(app: app)
        downloads = DownloadsScreen(app: app)
        tabTray = TabTrayScreen(app: app)
    }

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
    // Regression
    func testShareNormalWebsitePrint() {
        app.launch()
        tapToolbarShareButtonAndSelectOption(option: "Print")
        validatePrintLayout()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864277
    // Regression
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
    // Regression
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
    // Regression
    func testShareWebsiteReaderModePrint() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launchArguments.append(LaunchArguments.SkipAppleIntelligence)
        app.launch()
        reachReaderModeShareMenuLayoutAndSelectOption(option: "Print")
        validatePrintLayout()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864307
    // Regression
    func testShareWebsiteReaderModeCopy() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launchArguments.append(LaunchArguments.SkipAppleIntelligence)
        app.launch()
        reachReaderModeShareMenuLayoutAndSelectOption(option: "Copy")
        openNewTabAndValidateURLisPaste(url: TestPages.mozillaBook)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864308
    // Regression
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
    // Regression
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
    // Regression
    func testSharePdfFileSaveToFile() {
        app.launch()
        if #available(iOS 17, *) {
            openShareSheetFromToolbar(url: pdfUrl)
            openSaveToFilesPicker()
            documentPicker.save()
            waitForTabsButton()
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4381151
    // Smoketest
    func testSavePdfToFilesOffersTheDocumentAndKeepsBothCopies() {
        app.launch()
        guard #available(iOS 17, *) else { return }

        openShareSheetFromToolbar(url: pdfUrl)
        shareSheet.assertShareSheetDocumentName(loremIpsumPdfBaseName)
        shareSheet.assertShareSheetOffersPdfDocument()
        saveCurrentDocumentToFiles(named: loremIpsumPdfBaseName)

        // Saving the same document a second time succeeds: iOS keeps both copies rather than failing
        toolbar.tapShareButton()
        saveCurrentDocumentToFiles(named: loremIpsumPdfBaseName)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4381155
    // Regression
    func testSharingPdfRepeatedlyAndAcrossDocumentsNeverOffersAStaleFile() {
        app.launch()
        guard #available(iOS 17, *) else { return }

        openShareSheetFromToolbar(url: PDF_website["url"]!)
        assertShareSheetNamesDocumentThenDismiss(pdfTestPdfBaseName)

        // Reopening the sheet keeps naming the same document, with no duplicated sheet left behind
        for _ in 1...2 {
            toolbar.tapShareButton()
            assertShareSheetNamesDocumentThenDismiss(pdfTestPdfBaseName)
        }

        navigator.nowAt(BrowserTab)
        navigator.openURL(PDF_website["secondUrl"]!)
        waitUntilPageLoad()

        toolbar.tapShareButton()
        shareSheet.assertShareSheetDocumentName(loremIpsumPdfBaseName)
        shareSheet.assertShareSheetOffersPdfDocument()
        shareSheet.assertShareSheetDocumentNameIsNot(pdfTestPdfBaseName)

        // The picker offers the document now on screen, not a stale temporary file from the first share
        saveCurrentDocumentToFiles(named: loremIpsumPdfBaseName)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4381157
    // Regression
    func testSharePdfInPrivateBrowsingLeavesNoResidue() {
        app.launch()
        guard #available(iOS 17, *) else { return }

        navigator.nowAt(NewTabScreen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        if userState.isPrivate {
            app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].waitAndTap()
            navigator.nowAt(BrowserTab)
        }

        navigator.openURL(pdfUrl)
        waitUntilPageLoad()
        browser.assertAddressBarContains(value: PDF_website["pdfValue"]!, timeout: PDF_TIMEOUT)

        // An explicit user-initiated save is allowed in a Private tab
        toolbar.tapShareButton()
        shareSheet.assertShareSheetDocumentName(loremIpsumPdfBaseName)
        shareSheet.assertShareSheetOffersPdfDocument()
        saveCurrentDocumentToFiles(named: loremIpsumPdfBaseName)

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.goto(TabTray)
        tabTray.closeFirstTab()
        browser.assertPrivateBrowsingLabelExist()

        // Return to the regular tab opened at launch rather than closing all tabs to reach the homepage
        navigator.toggleOff(userState.isPrivate, withAction: Action.ToggleExperimentRegularMode)
        tabTray.tapTabAtIndex(index: 0)
        navigator.nowAt(NewTabScreen)

        // The private session leaves neither a history entry nor an in-app download entry
        navigator.goto(LibraryPanel_History)
        history.waitForHistoryEntriesNotExist([loremIpsumPdfName])
        navigator.goto(LibraryPanel_Downloads)
        downloads.assertNumberOfDownloadedItems(expectedCount: 0)
    }

    /// Asserts the open share sheet names the given document, then closes it and waits for it to go.
    private func assertShareSheetNamesDocumentThenDismiss(_ documentName: String) {
        shareSheet.assertShareSheetDocumentName(documentName)
        shareSheet.dismissShareSheet()
        shareSheet.assertShareSheetDismissed()
    }

    /// Saves the document behind the open share sheet, asserting the picker offers it by name, and
    /// waits until the picker has gone and the rendered PDF is back.
    private func saveCurrentDocumentToFiles(named baseName: String) {
        openSaveToFilesPicker()
        documentPicker.assertFileNameIsPrefilled(baseName)
        documentPicker.save()
        documentPicker.assertDismissed()
        shareSheet.dismissShareSheetIfPresented()
        // The toolbar is only hittable once the sheet is really gone, so this proves the save
        // returned to the rendered PDF rather than leaving the sheet on screen.
        toolbar.assertToolbarIsVisible()
        browser.assertAddressBarContains(value: PDF_website["pdfValue"]!, timeout: PDF_TIMEOUT)
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
                // Share "Markup" sometimes opens QuickLook in preview mode (a "Markup" pen button, no
                // palette); tap it to enter markup, then verify the PencilKit Drawing-Palette + Pen.
                let palette = app.otherElements["Drawing-Palette"]
                if !palette.mozWaitForElementToExist(timeout: TIMEOUT_LONG, failOnTimeout: false) {
                    app.buttons["Markup"].waitAndTap()
                }
                mozWaitForElementToExist(palette, timeout: TIMEOUT_LONG)
                mozWaitForElementToExist(app.buttons["Pen"], timeout: TIMEOUT_LONG)
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
        openShareSheetFromToolbar(url: url)
        selectShareSheetOption(option)
    }

    private func openShareSheetFromToolbar(url: String = url_3) {
        if !iPad() {
            navigator.nowAt(HomePanelsScreen)
            navigator.goto(URLBarOpen)
        }
        navigator.openURL(url)
        waitUntilPageLoad()
        app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].waitAndTap()
    }

    /// Reveals the activities hidden behind the share sheet's expander, which is a "View More"
    /// scroll-view cell on some iOS versions and a "More" action cell on others.
    private func expandShareSheetActions() {
        let viewMore = app.scrollViews.cells["View More"]
        if viewMore.mozWaitForElementToExist(timeout: TIMEOUT_PICKER_PROBE, failOnTimeout: false) {
            viewMore.waitAndTap(timeout: 10)
            return
        }
        app.collectionViews.cells
            .matching(NSPredicate(format: "identifier == %@ AND label == %@", "actionGroupCell", "More"))
            .firstMatch
            .waitAndTap(timeout: 10)
    }

    /// Selects Save to Files from the open share sheet and waits for the document picker.
    /// The share-sheet tap does not always open the picker on CI, so re-tap it when it doesn't.
    private func openSaveToFilesPicker() {
        selectShareSheetOption(saveToFilesOption)
        let saveButton = app.buttons["Save"]
        var attempts = 2
        while !saveButton.mozWaitForElementToExist(timeout: TIMEOUT, failOnTimeout: false) && attempts > 0 {
            let saveToFilesCell = app.collectionViews.cells[saveToFilesOption]
            guard saveToFilesCell.exists else { break }
            saveToFilesCell.tapOnApp()
            attempts -= 1
        }
        documentPicker.assertOpened()
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
                expandShareSheetActions()
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
