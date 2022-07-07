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

        let list = app.tables["DownloadsTable"].cells.count
        if list != 0 {
            for _ in 0...list-1 {
                waitForExistence(app.tables["DownloadsTable"].cells.element(boundBy: 0))
                app.tables["DownloadsTable"].cells.element(boundBy: 0).swipeLeft()
                waitForExistence(app.tables.cells.buttons["Delete"])
                app.tables.cells.buttons["Delete"].tap()
            }
        }
    }

    private func deleteItem(itemName: String) {
        app.tables.cells.staticTexts[itemName].swipeLeft()
        waitForExistence(app.tables.cells.buttons["Delete"], timeout: 3)
        app.tables.cells.buttons["Delete"].tap()
    }

    func testDownloadFilesAppMenuFirstTime() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_Downloads)
        waitForExistence(app.tables["DownloadsTable"], timeout: 5)
        XCTAssertTrue(app.tables["DownloadsTable"].exists)
        // Check that there is not any items and the default text shown is correct
        checkTheNumberOfDownloadedItems(items: 0)
        XCTAssertTrue(app.staticTexts["Downloaded files will show up here."].exists)
    }

    func testDownloadFileContextMenu() {
        navigator.openURL(testURL)
        waitUntilPageLoad()
        // Verify that the context menu prior to download a file is correct
        app.webViews.links[testFileName].firstMatch.tap()

        waitForExistence(app.tables["Context Menu"], timeout: 5)
        XCTAssertTrue(app.tables["Context Menu"].staticTexts[testFileNameDownloadPanel].exists)
        XCTAssertTrue(app.tables["Context Menu"].otherElements["download"].exists)
        app.buttons["Cancel"].tap()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        checkTheNumberOfDownloadedItems(items: 0)
    }

    // Smoketest
    func testDownloadFile() {
        downloadFile(fileName: testFileName, numberOfDownlowds: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        waitForExistence(app.tables["DownloadsTable"], timeout: 5)
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

    func testDeleteDownloadedFile() {
        downloadFile(fileName: testFileName, numberOfDownlowds: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        waitForExistence(app.tables["DownloadsTable"])

        deleteItem(itemName: testFileNameDownloadPanel)
        waitForNoExistence(app.tables.cells.staticTexts[testFileNameDownloadPanel])

        // After removing the number of items should be 0
        checkTheNumberOfDownloadedItems(items: 0)
    }

    func testShareDownloadedFile() {
        downloadFile(fileName: testFileName, numberOfDownlowds: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        app.tables.cells.staticTexts[testFileNameDownloadPanel].swipeLeft()
        XCTAssertTrue(app.tables.buttons.staticTexts["Share"].exists)
        XCTAssertTrue(app.tables.buttons.staticTexts["Delete"].exists)
    }

    func testLongPressOnDownloadedFile() {
        downloadFile(fileName: testFileName, numberOfDownlowds: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        waitForExistence(app.tables["DownloadsTable"])
        // Comenting out until share sheet can be managed with automated tests issue #5477
        app.tables.cells.staticTexts[testFileNameDownloadPanel].press(forDuration: 2)
        waitForExistence(app.otherElements["ActivityListView"], timeout: 10)
        if !iPad() {
            app.buttons["Close"].tap()
        }
     }

    private func downloadFile(fileName: String, numberOfDownlowds: Int) {
        navigator.openURL(testURL)
        waitUntilPageLoad()
        for _ in 0..<numberOfDownlowds {
            waitForExistence(app.webViews.links[testFileName], timeout: 5)
            app.webViews.links[testFileName].firstMatch.tap()

            waitForExistence(app.tables["Context Menu"].otherElements["download"], timeout: 5)
            app.tables["Context Menu"].otherElements["download"].tap()
        }
    }

    private func downloadBLOBFile() {
        navigator.openURL(testBLOBURL)
        waitForExistence(app.webViews.links["Download Text"], timeout: 5)
        app.webViews.links["Download Text"].press(forDuration: 1)
        app.buttons["Download Link"].tap()
    }

    func testDownloadMoreThanOneFile() {
        downloadFile(fileName: testFileName, numberOfDownlowds: 2)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        waitForExistence(app.tables["DownloadsTable"])
        checkTheNumberOfDownloadedItems(items: 2)
    }

    func testRemoveUserDataRemovesDownloadedFiles() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        // The option to remove downloaded files from clear private data is off by default
        navigator.goto(ClearPrivateDataSettings)
        XCTAssertTrue(app.cells.switches["Downloaded Files"].isEnabled, "The switch is not set correclty by default")

        // Change the value of the setting to on (make an action for this)
        downloadFile(fileName: testFileName, numberOfDownlowds: 1)

        // Check there is one item
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        waitForExistence(app.tables["DownloadsTable"])
        checkTheNumberOfDownloadedItems(items: 1)

        // Remove private data once the switch to remove downloaded files is enabled
        navigator.goto(NewTabScreen)
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(ClearPrivateDataSettings)
        app.cells.switches["Downloaded Files"].tap()
        navigator.performAction(Action.AcceptClearPrivateData)

        navigator.goto(HomePanelsScreen)
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_Downloads)
        // Check there is still one item
        checkTheNumberOfDownloadedItems(items: 0)
    }

    private func checkTheNumberOfDownloadedItems(items: Int) {
        waitForExistence(app.tables["DownloadsTable"], timeout: 10)
        let list = app.tables["DownloadsTable"].cells.count
        XCTAssertEqual(list, items, "The number of items in the downloads table is not correct")
    }
    // Smoketest
    func testToastButtonToGoToDownloads() {
        downloadFile(fileName: testFileName, numberOfDownlowds: 1)
        waitForExistence(app.buttons["Downloads"])
        app.buttons["Downloads"].tap()
        waitForExistence(app.tables["DownloadsTable"], timeout: 3)
        checkTheNumberOfDownloadedItems(items: 1)
    }
}
