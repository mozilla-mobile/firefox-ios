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

class DownloadFilesTests: BaseTestCase {
    override func tearDown() {
        // The downloaded file has to be removed between tests
        waitForExistence(app.tables["DownloadsTable"])
        if processIsTranslatedStr() == m1Rosetta {
            navigator.nowAt(LibraryPanel_Downloads)
            navigator.goto(HomePanelsScreen)
            navigator.nowAt(NewTabScreen)
            navigator.goto(ClearPrivateDataSettings)
            app.cells.switches["Downloaded Files"].tap()
            app.tables.cells["ClearPrivateData"].tap()
            app.alerts.buttons["OK"].tap()
        } else {
            let list = app.tables["DownloadsTable"].cells.count
            if list != 0 {
                for _ in 0...list-1 {
                    waitForExistence(app.tables["DownloadsTable"].cells.element(boundBy: 0))
                    app.tables["DownloadsTable"].cells.element(boundBy: 0).swipeLeft()
                    waitForExistence(app.tables.cells.buttons[StandardImageIdentifiers.Large.delete])
                    app.tables.cells.buttons[StandardImageIdentifiers.Large.delete].tap()
                }
            }
        }
        super.tearDown()
    }

    private func deleteItem(itemName: String) {
        app.tables.cells.staticTexts[itemName].swipeLeft()
        waitForExistence(app.tables.cells.buttons[StandardImageIdentifiers.Large.delete], timeout: TIMEOUT)
        app.tables.cells.buttons[StandardImageIdentifiers.Large.delete].tap()
    }

    func testDownloadFilesAppMenuFirstTime() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_Downloads)
        waitForExistence(app.tables["DownloadsTable"], timeout: TIMEOUT)
        XCTAssertTrue(app.tables["DownloadsTable"].exists)
        // Check that there is not any items and the default text shown is correct
        checkTheNumberOfDownloadedItems(items: 0)
        XCTAssertTrue(app.staticTexts["Downloaded files will show up here."].exists)
    }

    func testDownloadFileContextMenu() {
        navigator.openURL(testURL)
        waitUntilPageLoad()
        // Verify that the context menu prior to download a file is correct
        if !iPad() {
            app.webViews.links.firstMatch.swipeLeft(velocity: 1000)
            app.webViews.links.firstMatch.swipeLeft(velocity: 1000)
        }
        app.webViews.links[testFileName].firstMatch.tap()

        waitForExistence(app.tables["Context Menu"], timeout: TIMEOUT)
        XCTAssertTrue(app.tables["Context Menu"].staticTexts[testFileNameDownloadPanel].exists)
        XCTAssertTrue(app.tables["Context Menu"].otherElements[StandardImageIdentifiers.Large.download].exists)
        app.buttons["Cancel"].tap()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        checkTheNumberOfDownloadedItems(items: 0)
    }

    // Smoketest
    func testDownloadFile() {
        downloadFile(fileName: testFileName, numberOfDownloads: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        waitForExistence(app.tables["DownloadsTable"], timeout: TIMEOUT)
        // There should be one item downloaded. It's name and size should be shown
        checkTheNumberOfDownloadedItems(items: 1)
        XCTAssertTrue(app.tables.cells.staticTexts[testFileNameDownloadPanel].exists)
        XCTAssertTrue(app.tables.cells.staticTexts[testFileSize].exists)
    }

    func testDownloadBLOBFile() {
        downloadBLOBFile()
        waitForExistence(app.buttons["Downloads"])
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        waitForExistence(app.tables["DownloadsTable"])
        // There should be one item downloaded. It's name and size should be shown
        checkTheNumberOfDownloadedItems(items: 1)
        // We can only check for the BLOB file size since the name is generated
        XCTAssertTrue(app.tables.cells.staticTexts[testBLOBFileSize].exists)
    }

    func testDeleteDownloadedFile() throws {
        downloadFile(fileName: testFileName, numberOfDownloads: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        waitForExistence(app.tables["DownloadsTable"])
        if processIsTranslatedStr() == m1Rosetta {
            throw XCTSkip("swipeLeft() does not work on M1")
        } else {
            deleteItem(itemName: testFileNameDownloadPanel)
            waitForNoExistence(app.tables.cells.staticTexts[testFileNameDownloadPanel])
            // After removing the number of items should be 0
            checkTheNumberOfDownloadedItems(items: 0)
        }
    }

    func testShareDownloadedFile() throws {
        downloadFile(fileName: testFileName, numberOfDownloads: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        if processIsTranslatedStr() == m1Rosetta {
            throw XCTSkip("swipeLeft() does not work on M1")
        } else {
            app.tables.cells.staticTexts[testFileNameDownloadPanel].swipeLeft()
            XCTAssertTrue(app.tables.buttons.staticTexts["Share"].exists)
            XCTAssertTrue(app.tables.buttons.staticTexts[StandardImageIdentifiers.Large.delete].exists)
        }
    }

    func testLongPressOnDownloadedFile() {
        downloadFile(fileName: testFileName, numberOfDownloads: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        waitForExistence(app.tables["DownloadsTable"])
        // Commenting out until share sheet can be managed with automated tests issue #5477
        app.tables.cells.staticTexts[testFileNameDownloadPanel].press(forDuration: 2)
        waitForExistence(app.otherElements["ActivityListView"], timeout: TIMEOUT)
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
            waitForExistence(app.webViews.links[testFileName], timeout: TIMEOUT)

            app.webViews.links[testFileName].firstMatch.tap()

            waitForExistence(app.tables["Context Menu"].otherElements[StandardImageIdentifiers.Large.download], timeout: TIMEOUT)
            app.tables["Context Menu"].otherElements[StandardImageIdentifiers.Large.download].tap()
        }
    }

    private func downloadBLOBFile() {
        navigator.openURL(testBLOBURL)
        waitForExistence(app.webViews.links["Download Text"], timeout: TIMEOUT)
        app.webViews.links["Download Text"].press(forDuration: 1)
        app.buttons["Download Link"].tap()
    }

    func testDownloadMoreThanOneFile() {
        downloadFile(fileName: testFileName, numberOfDownloads: 2)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        waitForExistence(app.tables["DownloadsTable"])
        checkTheNumberOfDownloadedItems(items: 2)
    }

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

        waitForExistence(app.tables["DownloadsTable"])
        checkTheNumberOfDownloadedItems(items: 1)

        // Remove private data once the switch to remove downloaded files is enabled
        navigator.goto(NewTabScreen)
        waitForExistence(app.buttons["urlBar-cancel"], timeout: TIMEOUT)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(ClearPrivateDataSettings)
        app.cells.switches["Downloaded Files"].tap()
        navigator.performAction(Action.AcceptClearPrivateData)

        navigator.goto(HomePanelsScreen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_Downloads)
        // Check there is still one item
        checkTheNumberOfDownloadedItems(items: 0)
    }

    private func checkTheNumberOfDownloadedItems(items: Int) {
        waitForExistence(app.tables["DownloadsTable"], timeout: TIMEOUT)
        let list = app.tables["DownloadsTable"].cells.count
        XCTAssertEqual(list, items, "The number of items in the downloads table is not correct")
    }
    // Smoketest
    func testToastButtonToGoToDownloads() {
        downloadFile(fileName: testFileName, numberOfDownloads: 1)
        waitForExistence(app.buttons["Downloads"])
        app.buttons["Downloads"].tap()
        waitForExistence(app.tables["DownloadsTable"], timeout: TIMEOUT)
        checkTheNumberOfDownloadedItems(items: 1)
    }
}
