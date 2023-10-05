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
        // The downloaded file has to be removed between tests
        mozWaitForElementToExist(app.tables["DownloadsTable"])
        let list = app.tables["DownloadsTable"].cells.count
        if list != 0 {
            for _ in 0...list-1 {
                mozWaitForElementToExist(app.tables["DownloadsTable"].cells.element(boundBy: 0))
                app.tables["DownloadsTable"].cells.element(boundBy: 0).swipeLeft()
                mozWaitForElementToExist(app.tables.cells.buttons["Delete"])
                app.tables.cells.buttons["Delete"].tap()
            }
        }
        super.tearDown()
    }

    private func deleteItem(itemName: String) {
        app.tables.cells.staticTexts[itemName].swipeLeft()
        mozWaitForElementToExist(app.tables.cells.buttons["Delete"], timeout: TIMEOUT)
        app.tables.cells.buttons["Delete"].tap()
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306896
    func testDownloadFilesAppMenuFirstTime() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_Downloads)
        mozWaitForElementToExist(app.tables["DownloadsTable"], timeout: TIMEOUT)
        XCTAssertTrue(app.tables["DownloadsTable"].exists)
        // Check that there is not any items and the default text shown is correct
        checkTheNumberOfDownloadedItems(items: 0)
        XCTAssertTrue(app.staticTexts["Downloaded files will show up here."].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306897
    func testDownloadFileContextMenu() {
        navigator.openURL(testURL)
        waitUntilPageLoad()
        // Verify that the context menu prior to download a file is correct
        if !iPad() {
            app.webViews.links.firstMatch.swipeLeft(velocity: 1000)
            app.webViews.links.firstMatch.swipeLeft(velocity: 1000)
        }
        app.webViews.links[testFileName].firstMatch.tap()

        mozWaitForElementToExist(app.tables["Context Menu"], timeout: TIMEOUT)
        XCTAssertTrue(app.tables["Context Menu"].staticTexts[testFileNameDownloadPanel].exists)
        XCTAssertTrue(app.tables["Context Menu"].otherElements[StandardImageIdentifiers.Large.download].exists)
        app.buttons["Cancel"].tap()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        checkTheNumberOfDownloadedItems(items: 0)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306898
    // Smoketest
    func testDownloadFile() {
        downloadFile(fileName: testFileName, numberOfDownloads: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        mozWaitForElementToExist(app.tables["DownloadsTable"], timeout: TIMEOUT)
        // There should be one item downloaded. It's name and size should be shown
        checkTheNumberOfDownloadedItems(items: 1)
        XCTAssertTrue(app.tables.cells.staticTexts[testFileNameDownloadPanel].exists)
        XCTAssertTrue(app.tables.cells.staticTexts[testFileSize].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306899
    func testDownloadBLOBFile() {
        downloadBLOBFile()
        mozWaitForElementToExist(app.buttons["Downloads"])
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        mozWaitForElementToExist(app.tables["DownloadsTable"])
        // There should be one item downloaded. It's name and size should be shown
        checkTheNumberOfDownloadedItems(items: 1)
        // We can only check for the BLOB file size since the name is generated
        XCTAssertTrue(app.tables.cells.staticTexts[testBLOBFileSize].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306900
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

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306901
    func testShareDownloadedFile() throws {
        downloadFile(fileName: testFileName, numberOfDownloads: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        let shareButton = app.tables.buttons.staticTexts["Share"]
        app.tables.cells.staticTexts[testFileNameDownloadPanel].swipeLeft()
        mozWaitForElementToExist(shareButton)
        XCTAssertTrue(shareButton.exists)
        XCTAssertTrue(app.tables.buttons.staticTexts["Delete"].exists)
        shareButton.tap(force: true)
        mozWaitForElementToExist(app.tables["DownloadsTable"])
        XCTAssertTrue(app.tables["DownloadsTable"].staticTexts[testFileNameDownloadPanel].exists)
        XCTAssertTrue(app.collectionViews.cells["Copy"].exists)
        if !iPad() {
            app.buttons["Close"].tap()
        } else {
            // Workaround to close the context menu.
            // XCUITest does not allow me to click the greyed out portion of the app.
            app.otherElements["ActivityListView"].cells["XCElementSnapshotPrivilegedValuePlaceholder"].firstMatch.tap()
            app.navigationBars["Add Tag"].buttons["Done"].tap()
        }
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306902
    func testLongPressOnDownloadedFile() {
        downloadFile(fileName: testFileName, numberOfDownloads: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        mozWaitForElementToExist(app.tables["DownloadsTable"])
        // Commenting out until share sheet can be managed with automated tests issue #5477
        app.tables.cells.staticTexts[testFileNameDownloadPanel].press(forDuration: 2)
        mozWaitForElementToExist(app.otherElements["ActivityListView"], timeout: TIMEOUT)
        XCTAssertTrue(app.tables["DownloadsTable"].staticTexts[testFileNameDownloadPanel].exists)
        XCTAssertTrue(app.collectionViews.cells["Copy"].exists)
        if !iPad() {
            app.buttons["Close"].tap()
        } else {
            // Workaround to close the context menu.
            // XCUITest does not allow me to click the greyed out portion of the app.
            app.otherElements["ActivityListView"].cells["XCElementSnapshotPrivilegedValuePlaceholder"].firstMatch.tap()
            app.navigationBars["Add Tag"].buttons["Done"].tap()
        }
     }

    private func downloadFile(fileName: String, numberOfDownloads: Int) {
        navigator.openURL(testURL)
        waitUntilPageLoad()
        app.webViews.firstMatch.swipeLeft()
        for _ in 0..<numberOfDownloads {
            mozWaitForElementToExist(app.webViews.links[testFileName], timeout: TIMEOUT)

            app.webViews.links[testFileName].firstMatch.tap()

            mozWaitForElementToExist(app.tables["Context Menu"].otherElements[StandardImageIdentifiers.Large.download], timeout: TIMEOUT)
            app.tables["Context Menu"].otherElements[StandardImageIdentifiers.Large.download].tap()
        }
    }

    private func downloadBLOBFile() {
        navigator.openURL(testBLOBURL)
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.links["Download Text"], timeout: TIMEOUT)
        app.webViews.links["Download Text"].press(forDuration: 1)
        app.buttons["Download Link"].tap()
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306903
    func testDownloadMoreThanOneFile() {
        downloadFile(fileName: testFileName, numberOfDownloads: 2)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        mozWaitForElementToExist(app.tables["DownloadsTable"])
        checkTheNumberOfDownloadedItems(items: 2)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306904
    func testRemoveUserDataRemovesDownloadedFiles() {
        navigator.nowAt(NewTabScreen)
        // The option to remove downloaded files from clear private data is off by default
        navigator.goto(ClearPrivateDataSettings)
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
        mozWaitForElementToExist(app.buttons["urlBar-cancel"], timeout: TIMEOUT)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(ClearPrivateDataSettings)
        app.cells.switches["Downloaded Files"].tap()
        navigator.performAction(Action.AcceptClearPrivateData)

        navigator.goto(HomePanelsScreen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_Downloads)
        // Check the item has been removed
        checkTheNumberOfDownloadedItems(items: 0)
    }

    private func checkTheNumberOfDownloadedItems(items: Int) {
        mozWaitForElementToExist(app.tables["DownloadsTable"], timeout: TIMEOUT)
        let list = app.tables["DownloadsTable"].cells.count
        XCTAssertEqual(list, items, "The number of items in the downloads table is not correct")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306895
    // Smoketest
    func testToastButtonToGoToDownloads() {
        downloadFile(fileName: testFileName, numberOfDownloads: 1)
        mozWaitForElementToExist(app.buttons["Downloads"])
        app.buttons["Downloads"].tap()
        mozWaitForElementToExist(app.tables["DownloadsTable"], timeout: TIMEOUT)
        checkTheNumberOfDownloadedItems(items: 1)
    }
}
