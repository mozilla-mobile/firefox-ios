// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

let PDF_website = ["url": "http://www.pdf995.com/samples/pdf.pdf", "pdfValue": "www.pdf995.com/samples", "urlValue": "www.pdf995.com/", "bookmarkLabel": "http://www.pdf995.com/samples/pdf.pdf", "longUrlValue": "http://www.pdf995.com/"]

class BrowsingPDFTests: BaseTestCase {
    func testOpenPDFViewer() {
        navigator.openURL(PDF_website["url"]!)

        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: PDF_website["pdfValue"]!)
        // Swipe Up and Down
        let element = app.children(matching: .other).element
        element.swipeUp()
        waitForExistence(app.staticTexts["2 of 5"])

        var i = 0
        repeat {
            element.swipeDown()
            i = i+1
        } while (app.staticTexts["1 of 5"].exists == false && i < 10)

        waitForExistence(app.staticTexts["1 of 5"])
        XCTAssertTrue(app.staticTexts["1 of 5"].exists)
    }

    func testOpenLinkFromPDF() {
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()

        // Click on a link on the pdf and check that the website is shown
        app/*@START_MENU_TOKEN@*/.webViews/*[[".otherElements[\"Web content\"].webViews",".otherElements[\"contentView\"].webViews",".webViews"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element.children(matching: .other).element(boundBy: 0).tap()
        waitForValueContains(app.textFields["url"], value: PDF_website["pdfValue"]!)

        let element = app/*@START_MENU_TOKEN@*/.webViews/*[[".otherElements[\"Web content\"].webViews",".otherElements[\"contentView\"].webViews",".webViews"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element.children(matching: .other).element(boundBy: 0)
        element.children(matching: .other).element(boundBy: 11).tap()
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: PDF_website["urlValue"]!)
        XCTAssertTrue(app.webViews.links["Download Now"].exists)

        // Go back to pdf view
        if iPad() {
            app.buttons["URLBarView.backButton"].tap()
        } else {
            app.buttons["TabToolbar.backButton"].tap()
        }
        waitForValueContains(app.textFields["url"], value: PDF_website["pdfValue"]!)
    }

    func testLongPressOnPDFLink() {
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()
        // Long press on a link on the pdf and check the options shown
        app/*@START_MENU_TOKEN@*/.webViews/*[[".otherElements[\"Web content\"].webViews",".otherElements[\"contentView\"].webViews",".webViews"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element.children(matching: .other).element(boundBy: 0).tap()
        waitForValueContains(app.textFields["url"], value: PDF_website["pdfValue"]!)

        let element = app/*@START_MENU_TOKEN@*/.webViews/*[[".otherElements[\"Web content\"].webViews",".otherElements[\"contentView\"].webViews",".webViews"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element.children(matching: .other).element(boundBy: 0)
        element.children(matching: .other).element(boundBy: 11).press(forDuration: 1)

        waitForExistence(app.sheets.staticTexts[PDF_website["longUrlValue"]!])
        waitForExistence(app.sheets.buttons["Open"])
        waitForExistence(app.sheets.buttons["Add to Reading List"])
        waitForExistence(app.sheets.buttons["Copy"])
        waitForExistence(app.sheets.buttons["Share…"])
    }

    func testLongPressOnPDFLinkToAddToReadingList() {
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()
        // Long press on a link on the pdf and check the options shown
        app/*@START_MENU_TOKEN@*/.webViews/*[[".otherElements[\"Web content\"].webViews",".otherElements[\"contentView\"].webViews",".webViews"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element.children(matching: .other).element(boundBy: 0).tap()
        waitForValueContains(app.textFields["url"], value: PDF_website["pdfValue"]!)

        let element = app/*@START_MENU_TOKEN@*/.webViews/*[[".otherElements[\"Web content\"].webViews",".otherElements[\"contentView\"].webViews",".webViews"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element.children(matching: .other).element(boundBy: 0)
        element.children(matching: .other).element(boundBy: 11).press(forDuration: 1)

        waitForExistence(app.sheets.staticTexts[PDF_website["longUrlValue"]!])
        app.sheets.buttons["Add to Reading List"].tap()
        navigator.nowAt(BrowserTab)

        // Go to reading list and check that the item is there
        navigator.goto(LibraryPanel_ReadingList)
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts[PDF_website["longUrlValue"]!]
        waitForExistence(savedToReadingList)
        XCTAssertTrue(savedToReadingList.exists)
    }

    func testPinPDFtoTopSites() {
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()
        navigator.performAction(Action.PinToTopSitesPAM)
        navigator.goto(NewTabScreen)
        waitForExistence(app.collectionViews.cells["TopSitesCell"].cells["pdf995"])
        XCTAssertTrue(app.collectionViews.cells["TopSitesCell"].cells["pdf995"].exists)

        // Open pdf from pinned site
        let pdfTopSite = app.collectionViews.cells["TopSitesCell"].cells["pdf995"]
        pdfTopSite.tap()
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: PDF_website["pdfValue"]!)

        // Remove pdf pinned site
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForExistence(app.collectionViews.cells["TopSitesCell"].cells["pdf995"])
        pdfTopSite.press(forDuration: 1)
        waitForExistence(app.tables["Context Menu"].cells["action_unpin"])
        app.tables["Context Menu"].cells["action_unpin"].tap()
        waitForExistence(app.collectionViews.cells["TopSitesCell"])
        XCTAssertTrue(app.collectionViews.cells["TopSitesCell"].cells["pdf995"].exists)
    }

    func testBookmarkPDF() {
        navigator.openURL(PDF_website["url"]!)
        navigator.performAction(Action.BookmarkThreeDots)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Bookmarks)
        waitForExistence(app.tables["Bookmarks List"])
        XCTAssertTrue(app.tables["Bookmarks List"].staticTexts[PDF_website["bookmarkLabel"]!].exists)
    }
}
