import XCTest

let testFileName = "Small.zip"
let testFileSize = "178 bytes"
let testURL = "http://demo.borland.com/testsite/download_testpage.php"

class DownloadFilesTests: BaseTestCase {

    override func tearDown() {
        // The downloaded file has to be removed between tests
        Base.helper.waitForExistence(Base.app.tables["DownloadsTable"])

        let list = Base.app.tables["DownloadsTable"].cells.count
        if list != 0 {
            for _ in 0...list-1 {
                Base.helper.waitForExistence(Base.app.tables["DownloadsTable"].cells.element(boundBy: 0))
                Base.app.tables["DownloadsTable"].cells.element(boundBy: 0).swipeLeft()
                Base.helper.waitForExistence(Base.app.tables.cells.buttons["Delete"])
                Base.app.tables.cells.buttons["Delete"].tap()
            }
        }
    }

    private func deleteItem(itemName: String) {
        Base.app.tables.cells.staticTexts[itemName].swipeLeft()
        Base.helper.waitForExistence(Base.app.tables.cells.buttons["Delete"], timeout: 3)
        Base.app.tables.cells.buttons["Delete"].tap()
    }

    func testDownloadFilesAppMenuFirstTime() {
        navigator.goto(LibraryPanel_Downloads)
        XCTAssertTrue(Base.app.tables["DownloadsTable"].exists)
        // Check that there is not any items and the default text shown is correct
        checkTheNumberOfDownloadedItems(items: 0)
        XCTAssertTrue(Base.app.staticTexts["Downloaded files will show up here."].exists)
    }

    func testDownloadFileContextMenu() {
        navigator.openURL(testURL)
        Base.helper.waitUntilPageLoad()
        // Verify that the context menu prior to download a file is correct
        Base.app.webViews.staticTexts[testFileName].tap()
        Base.helper.waitForExistence(Base.app.webViews.buttons["Download"])
        Base.app.webViews.buttons["Download"].tap()
        Base.helper.waitForExistence(Base.app.tables["Context Menu"])
        XCTAssertTrue(Base.app.tables["Context Menu"].staticTexts[testFileName].exists)
        XCTAssertTrue(Base.app.tables["Context Menu"].cells["download"].exists)
        Base.app.buttons["Cancel"].tap()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        checkTheNumberOfDownloadedItems(items: 0)
    }

    func testDownloadFile() {
        downloadFile(fileName: testFileName, numberOfDownlowds: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        Base.helper.waitForExistence(Base.app.tables["DownloadsTable"])
        // There should be one item downloaded. It's name and size should be shown
        checkTheNumberOfDownloadedItems(items: 1)
        XCTAssertTrue(Base.app.tables.cells.staticTexts[testFileName].exists)
        XCTAssertTrue(Base.app.tables.cells.staticTexts[testFileSize].exists)
    }

    func testDeleteDownloadedFile() {
        downloadFile(fileName: testFileName, numberOfDownlowds: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        Base.helper.waitForExistence(Base.app.tables["DownloadsTable"])

        deleteItem(itemName: testFileName)
        Base.helper.waitForNoExistence(Base.app.tables.cells.staticTexts[testFileName])

        // After removing the number of items should be 0
        checkTheNumberOfDownloadedItems(items: 0)
    }

    func testShareDownloadedFile() {
        downloadFile(fileName: testFileName, numberOfDownlowds: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        Base.app.tables.cells.staticTexts[testFileName].swipeLeft()

        XCTAssertTrue(Base.app.tables.cells.buttons["Share"].exists)
        XCTAssertTrue(Base.app.tables.cells.buttons["Delete"].exists)
        //Comenting out until share sheet can be managed with automated tests issue #5477
        //Base.app.tables.cells.buttons["Share"].tap()
        //Base.helper.waitForExistence(Base.app.otherElements["ActivityListView"])
        //if iPad() {
        //    Base.app.otherElements["PopoverDismissRegion"].tap()
        //} else {
        //    Base.app.buttons["Cancel"].tap()
        //}
    }

    func testLongPressOnDownloadedFile() {
        downloadFile(fileName: testFileName, numberOfDownlowds: 1)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        Base.helper.waitForExistence(Base.app.tables["DownloadsTable"])
        //Comenting out until share sheet can be managed with automated tests issue #5477
        //Base.app.tables.cells.staticTexts[testFileName].press(forDuration: 2)
        //Base.helper.waitForExistence(Base.app.otherElements["ActivityListView"])
        //if iPad() {
        //    Base.app.otherElements["PopoverDismissRegion"].tap()
        //} else {
        //    Base.app.buttons["Cancel"].tap()
        //}
     }

    private func downloadFile(fileName: String, numberOfDownlowds: Int) {
        navigator.openURL(testURL)
        Base.helper.waitUntilPageLoad()
        for _ in 0..<numberOfDownlowds {
            Base.app.webViews.staticTexts[fileName].tap()
            Base.helper.waitForExistence(Base.app.webViews.buttons["Download"])
            Base.app.webViews.buttons["Download"].tap()
            Base.helper.waitForExistence(Base.app.tables["Context Menu"])
            Base.app.tables["Context Menu"].cells["download"].tap()
        }
    }

    func testDownloadMoreThanOneFile() {
        downloadFile(fileName: testFileName, numberOfDownlowds: 2)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        Base.helper.waitForExistence(Base.app.tables["DownloadsTable"])
        checkTheNumberOfDownloadedItems(items: 2)
    }

    func testRemoveUserDataRemovesDownloadedFiles() {
        // The option to remove downloaded files from clear private data is off by default
        navigator.goto(ClearPrivateDataSettings)
        XCTAssertTrue(Base.app.cells.switches["Downloaded Files"].isEnabled, "The switch is not set correclty by default")

        // Change the value of the setting to on (make an action for this)
        downloadFile(fileName: testFileName, numberOfDownlowds: 1)

        // Check there is one item
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)

        Base.helper.waitForExistence(Base.app.tables["DownloadsTable"])
        checkTheNumberOfDownloadedItems(items: 1)

        // Remove private data once the switch to remove downloaded files is enabled
        navigator.goto(ClearPrivateDataSettings)
        Base.app.cells.switches["Downloaded Files"].tap()
        navigator.performAction(Action.AcceptClearPrivateData)

        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        // Check there is still one item
        checkTheNumberOfDownloadedItems(items: 0)
    }

    private func checkTheNumberOfDownloadedItems(items: Int) {
        Base.helper.waitForExistence(Base.app.tables["DownloadsTable"])
        let list = Base.app.tables["DownloadsTable"].cells.count
        XCTAssertEqual(list, items, "The number of items in the downloads table is not correct")
    }

    func testToastButtonToGoToDownloads() {
        downloadFile(fileName: testFileName, numberOfDownlowds: 1)
        Base.helper.waitForExistence(Base.app.buttons["Downloads"])
        Base.app.buttons["Downloads"].tap()
        Base.helper.waitForExistence(Base.app.tables["DownloadsTable"], timeout: 3)
        checkTheNumberOfDownloadedItems(items: 1)
    }
}
