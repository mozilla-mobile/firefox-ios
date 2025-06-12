// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

let testFileName = "Download smallZip.zip"
let testFileNameDownloadPanel = "smallZip.zip"
let testFileSize = "178 bytes"
let testURL = "https://storage.googleapis.com/mobile_test_assets/test_app/downloads.html"
let testBLOBURL = "http://bennadel.github.io/JavaScript-Demos/demos/href-download-text-blob/"
let testBLOBFileSize = "35 bytes"

class DownloadsTests: BaseTestCase {
    override func tearDown() {
        defer { super.tearDown() }

            guard let navigator = navigator else {
                print("⚠️ Navigator is nil in tearDown — skipping cleanup.")
                return
            }
        // The downloaded file has to be removed between tests
        app.terminate()
        app.launch()
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_Downloads)
        mozWaitForElementToExist(app.tables["DownloadsTable"])
        let list = app.tables["DownloadsTable"].cells.count
        if list != 0 {
            for _ in 0...list-1 {
                mozWaitForElementToExist(app.tables["DownloadsTable"].cells.element(boundBy: 0))
                app.tables["DownloadsTable"].cells.element(boundBy: 0).swipeLeft(velocity: 200)
                app.tables.cells.buttons["Delete"].waitAndTap()
            }
        }
        super.tearDown()
    }

    private func deleteItem(itemName: String) {
        app.tables.cells.staticTexts[itemName].swipeLeft(velocity: 200)
        app.tables.cells.buttons["Delete"].waitAndTap()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306896
    func testDownloadFilesAppMenuFirstTime() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_Downloads)
        mozWaitForElementToExist(app.tables["DownloadsTable"])
        // Check that there is not any items and the default text shown is correct
        checkTheNumberOfDownloadedItems(items: 0)
        mozWaitForElementToExist(app.staticTexts["Downloaded files will show up here."])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306897
    func testDownloadFileContextMenu() {
        navigator.openURL(testURL)
        waitUntilPageLoad()
        // Verify that the context menu prior to download a file is correct
        if !iPad() {
            app.webViews.links.firstMatch.swipeLeft(velocity: 1000)
            app.webViews.links.firstMatch.swipeLeft(velocity: 1000)
        }
        app.webViews.links[testFileName].firstMatch.waitAndTap()

        waitForElementsToExist(
            [
                app.tables["Context Menu"],
                app.tables["Context Menu"].staticTexts[testFileNameDownloadPanel],
                app.tables["Context Menu"].buttons[StandardImageIdentifiers.Large.download]
            ]
        )
        app.buttons["Cancel"].waitAndTap()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        checkTheNumberOfDownloadedItems(items: 0)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306898
    // Smoketest
    func testDownloadFile() {
        downloadFile(fileName: testFileName, numberOfDownloads: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        mozWaitForElementToExist(app.tables["DownloadsTable"])
        // There should be one item downloaded. It's name and size should be shown
        checkTheNumberOfDownloadedItems(items: 1)
        waitForElementsToExist(
            [
                app.tables.cells.staticTexts[testFileNameDownloadPanel],
                app.tables.cells.staticTexts[testFileSize]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306899
    func testDownloadBLOBFile() {
        downloadBLOBFile()
        mozWaitForElementToExist(app.buttons["Downloads"])
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        mozWaitForElementToExist(app.tables["DownloadsTable"])
        // There should be one item downloaded. It's name and size should be shown
        checkTheNumberOfDownloadedItems(items: 1)
        // We can only check for the BLOB file size since the name is generated
        mozWaitForElementToExist(app.tables.cells.staticTexts[testBLOBFileSize])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306900
    func testDeleteDownloadedFile() throws {
        downloadFile(fileName: testFileName, numberOfDownloads: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        mozWaitForElementToExist(app.tables["DownloadsTable"])
        deleteItem(itemName: testFileNameDownloadPanel)
        mozWaitForElementToNotExist(app.tables.cells.staticTexts[testFileNameDownloadPanel])
        // After removing the number of items should be 0
        checkTheNumberOfDownloadedItems(items: 0)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306901
    func testShareDownloadedFile() throws {
        downloadFile(fileName: testFileName, numberOfDownloads: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        let shareButton = app.tables.buttons.staticTexts["Share"]
        app.tables.cells.staticTexts[testFileNameDownloadPanel].swipeLeft(velocity: 200)
        waitForElementsToExist(
            [
                shareButton,
                app.tables.buttons.staticTexts["Delete"]
            ]
        )
        shareButton.tap(force: true)
        waitForElementsToExist(
            [
                app.tables["DownloadsTable"],
                app.tables["DownloadsTable"].staticTexts[testFileNameDownloadPanel]
            ]
        )
        if #available(iOS 17, *) {
            waitForElementsToExist(
                [
                    app.collectionViews.cells["Copy"],
                    app.collectionViews.cells["Add Tags"],
                    app.collectionViews.cells["Save to Files"]
                ]
            )
        } else if #available(iOS 16, *) {
            mozWaitForElementToExist(app.collectionViews.cells["Copy"])
        } else {
            mozWaitForElementToExist(app.collectionViews.buttons["Copy"])
        }
        if !iPad() {
            app.navigationBars["UIActivityContentView"].buttons["Close"].waitAndTap()
        } else {
            // Workaround to close the context menu.
            // XCUITest does not allow me to click the greyed out portion of the app without the force option.
            app.buttons["Done"].tap(force: true)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306902
    func testLongPressOnDownloadedFile() {
        downloadFile(fileName: testFileName, numberOfDownloads: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        mozWaitForElementToExist(app.tables["DownloadsTable"])
        // Commenting out until share sheet can be managed with automated tests issue #5477
        app.tables.cells.staticTexts[testFileNameDownloadPanel].press(forDuration: 2)
        waitForElementsToExist(
            [
                app.otherElements["ActivityListView"],
                app.tables["DownloadsTable"].staticTexts[testFileNameDownloadPanel]
            ]
        )
        if #available(iOS 17, *) {
            waitForElementsToExist(
                [
                    app.collectionViews.cells["Copy"],
                    app.collectionViews.cells["Add Tags"],
                    app.collectionViews.cells["Save to Files"]
                ]
            )
        } else if #available(iOS 16, *) {
            mozWaitForElementToExist(app.collectionViews.cells["Copy"])
        } else {
            mozWaitForElementToExist(app.collectionViews.buttons["Copy"])
        }
        if !iPad() {
            app.navigationBars["UIActivityContentView"].buttons["Close"].waitAndTap()
        } else {
            // Workaround to close the context menu.
            // XCUITest does not allow me to click the greyed out portion of the app without the force option.
            app.buttons["Done"].tap(force: true)
        }
     }

    private func downloadFile(fileName: String, numberOfDownloads: Int) {
        navigator.openURL(testURL)
        waitUntilPageLoad()
        app.webViews.firstMatch.swipeLeft()
        for _ in 0..<numberOfDownloads {
            app.webViews.links[testFileName].firstMatch.waitAndTap()

            mozWaitForElementToExist(
                app.tables["Context Menu"].buttons[StandardImageIdentifiers.Large.download]
            )
            app.tables["Context Menu"].buttons[StandardImageIdentifiers.Large.download].waitAndTap()
        }
        waitForTabsButton()
    }

    private func downloadBLOBFile() {
        navigator.openURL(testBLOBURL)
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.links["Download Text"])
        app.webViews.links["Download Text"].press(forDuration: 1)
        app.buttons["Download Link"].waitAndTap()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306903
    func testDownloadMoreThanOneFile() {
        downloadFile(fileName: testFileName, numberOfDownloads: 2)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        mozWaitForElementToExist(app.tables["DownloadsTable"])
        checkTheNumberOfDownloadedItems(items: 2)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306904
    func testRemoveUserDataRemovesDownloadedFiles() {
        navigator.nowAt(NewTabScreen)
        // The option to remove downloaded files from clear private data is off by default
        navigator.goto(ClearPrivateDataSettings)
        mozWaitForElementToExist(app.cells.switches["Downloaded Files"])
        XCTAssertTrue(app.cells.switches["Downloaded Files"].isEnabled, "The switch is not set correctly by default")

        // Change the value of the setting to on (make an action for this)
        downloadFile(fileName: testFileName, numberOfDownloads: 1)

        // Check there is one item
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        mozWaitForElementToExist(app.tables["DownloadsTable"])
        checkTheNumberOfDownloadedItems(items: 1)

        // Remove private data once the switch to remove downloaded files is enabled
        navigator.goto(NewTabScreen)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(ClearPrivateDataSettings)
        app.cells.switches["Downloaded Files"].waitAndTap()
        navigator.performAction(Action.AcceptClearPrivateData)

        navigator.goto(HomePanelsScreen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_Downloads)
        // Check the item has been removed
        checkTheNumberOfDownloadedItems(items: 0)
    }

    private func checkTheNumberOfDownloadedItems(items: Int) {
        mozWaitForElementToExist(app.tables["DownloadsTable"])
        let list = app.tables["DownloadsTable"].cells.count
        XCTAssertEqual(list, items, "The number of items in the downloads table is not correct")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306895
    // Smoketest
    func testToastButtonToGoToDownloads() {
        downloadFile(fileName: testFileName, numberOfDownloads: 1)
        app.buttons["Downloads"].waitAndTap()
        mozWaitForElementToExist(app.tables["DownloadsTable"])
        checkTheNumberOfDownloadedItems(items: 1)
    }
}
