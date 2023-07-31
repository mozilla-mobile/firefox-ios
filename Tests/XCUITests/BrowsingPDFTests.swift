// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

let PDF_website = ["url": "www.orimi.com/pdf-test.pdf", "pdfValue": "www.orimi.com/pdf", "urlValue": "yukon.ca/en/educat", "bookmarkLabel": "https://www.orimi.com/pdf-test.pdf", "longUrlValue": "http://www.education.gov.yk.ca/"]
class BrowsingPDFTests: BaseTestCase {
    func testOpenPDFViewer() {
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: PDF_website["pdfValue"]!)
        // Swipe Up and Down
        app.swipeUp()
        waitForExistence(app.staticTexts["1 of 1"])
        app.swipeDown()
        XCTAssertTrue(app.staticTexts["1 of 1"].exists)
    }

    func testOpenLinkFromPDF() {
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()

        // Click on a link on the pdf and check that the website is shown
        app.links.element(boundBy: 0).tapOnApp()
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: PDF_website["urlValue"]!)
        XCTAssertTrue(app.staticTexts["Education and schools"].exists)

        // Go back to pdf view
        app.buttons[AccessibilityIdentifiers.Toolbar.backButton].tap()
        waitForValueContains(app.textFields["url"], value: PDF_website["pdfValue"]!)
    }

    func testLongPressOnPDFLink() {
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()
        // Long press on a link on the pdf and check the options shown
        app.webViews.links.element(boundBy: 0).pressAtPoint(CGPoint(x: 10, y: 0), forDuration: 3)

        waitForExistence(app.staticTexts[PDF_website["longUrlValue"]!])
        waitForExistence(app.buttons["Open"])
        waitForExistence(app.buttons["Add to Reading List"])
        waitForExistence(app.buttons["Copy Link"])
        waitForExistence(app.buttons["Share…"])
    }

    func testLongPressOnPDFLinkToAddToReadingList() {
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()
        // Long press on a link on the pdf and check the options shown
        app.webViews.links.element(boundBy: 0).pressAtPoint(CGPoint(x: 10, y: 0), forDuration: 3)

        waitForExistence(app.staticTexts[PDF_website["longUrlValue"]!])
        app.buttons["Add to Reading List"].tap()
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
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForExistence(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell], timeout: 10)
        waitForExistence(app.collectionViews.cells.staticTexts[PDF_website["bookmarkLabel"]!])
        XCTAssertTrue(app.collectionViews.cells.staticTexts[PDF_website["bookmarkLabel"]!].exists)

        // Open pdf from pinned site
        let pdfTopSite = app.collectionViews[AccessibilityIdentifiers.FirefoxHomepage.collectionView].cells[PDF_website["bookmarkLabel"]!].children(matching: .other).element.children(matching: .other).element(boundBy: 0)
        pdfTopSite.tap()
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: PDF_website["pdfValue"]!)

        // Remove pdf pinned site
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForExistence(app.collectionViews.cells.staticTexts[PDF_website["bookmarkLabel"]!])
        pdfTopSite.press(forDuration: 1)
        waitForExistence(app.tables.cells.otherElements[StandardImageIdentifiers.Large.pinSlash])
        app.tables.cells.otherElements[StandardImageIdentifiers.Large.pinSlash].tap()
        waitForExistence(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
        XCTAssertTrue(app.collectionViews.cells.staticTexts[PDF_website["bookmarkLabel"]!].exists)
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
