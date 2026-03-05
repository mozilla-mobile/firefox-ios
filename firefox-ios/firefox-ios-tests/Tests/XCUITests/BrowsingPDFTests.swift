// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

let PDF_website = [
    "url": "https://storage.googleapis.com/mobile_test_assets/public/pdf-test.pdf",
    "urlValue": "education.gov.yk.ca",
    "pdfValue": "storage.googleapis.com",
    "bookmarkLabel": "https://storage.googleapis.com/mobile_test_assets/public/pdf-test.pdf",
    "longUrlValue": "http://www.education.gov.yk.ca/"
]

class BrowsingPDFTests: BaseTestCase {
    let url = XCUIApplication().textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
    private var topSites: TopSitesScreen!
    private var browser: BrowserScreen!
    private var pdf: PDFScreen!
    private var contextMenu: ContextMenuScreen!
    private var library: LibraryScreen!

    override func setUp() async throws {
        // Test name looks like: "[Class testFunc]", parse out the function name
        try await super.setUp()
        topSites = TopSitesScreen(app: app)
        contextMenu = ContextMenuScreen(app: app)
        pdf = PDFScreen(app: app)
        browser = BrowserScreen(app: app)
        library = LibraryScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307116
    func testOpenPDFViewer() {
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()
        mozWaitForValueContains(url, value: PDF_website["pdfValue"]!)
        // Swipe Up and Down
        app.swipeUp()
        mozWaitForElementToExist(app.staticTexts["1 of 1"])
        app.swipeDown()
        mozWaitForElementToExist(app.staticTexts["1 of 1"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307117
    func testOpenLinkFromPDF() {
        // Sometimes the test fails before opening the URL. Let's make sure the homepage is ready
        topSites.assertVisible()

        // Open the PDF URL and wait for the page to load
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()

        // Tap on a link within the PDF and check that the website is shown
        pdf.tapOnLinkInPdf(atIndex: 0)
        waitUntilPageLoad()

        // Handle potential human verification step
        browser.handleHumanVerification()

        // Assert that the browser is at the correct URL
        browser.assertAddressBarContains(value: PDF_website["urlValue"]!)

        // Go back to the PDF view
        browser.tapBackButton()

        // Assert that the browser is back at the PDF URL
        browser.assertAddressBarContains(value: PDF_website["pdfValue"]!)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307118
    func testLongPressOnPDFLink() {
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()
        // Long press on a link on the pdf and check the options shown
        longPressOnPdfLink()

        if #unavailable(iOS 26) {
            waitForElementsToExist(
                [
                    app.staticTexts[PDF_website["longUrlValue"]!],
                    app.buttons["Open"],
                    app.buttons["Add to Reading List"]
                ]
            )
        }
        if #available(iOS 26, *) {
            mozWaitForElementToExist(app.menuItems["Copy"])
        } else if #available(iOS 16, *) {
            mozWaitForElementToExist(app.buttons["Copy Link"])
        } else {
            mozWaitForElementToExist(app.buttons["Copy"])
        }
        if #available(iOS 26, *) {
            mozWaitForElementToExist(app.menuItems["Share…"])
        } else {
            mozWaitForElementToExist(app.buttons["Share…"])
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307119
    func testLongPressOnPDFLinkToAddToReadingList() {
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()
        // Long press on a link on the pdf and check the options shown
        longPressOnPdfLink()

        if #unavailable(iOS 26) {
            mozWaitForElementToExist(app.staticTexts[PDF_website["longUrlValue"]!])
            app.buttons["Add to Reading List"].waitAndTap()
            navigator.nowAt(BrowserTab)

            // Go to reading list and check that the item is there
            navigator.goto(LibraryPanel_ReadingList)
            let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts[PDF_website["longUrlValue"]!]
            mozWaitForElementToExist(savedToReadingList)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307120
    // Smoketest
    func testPinPDFtoTopSites() {
        // 1. Open a PDF and pin it to Top Sites.
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()

        // Assumes BrowserTabMenuMore and PinToTopSitesPAM are custom navigator actions
        navigator.goto(BrowserTabMenuMore)
        navigator.performAction(Action.PinToTopSitesPAM)

        // 2. Go to the homepage and verify the PDF is pinned.
        navigator.performAction(Action.OpenNewTabFromTabTray)

        // Wait for the pinned item to exist on the Top Sites screen.
        let bookmarkLabel = PDF_website["bookmarkLabel"]!
        topSites.assertTopSiteExists(named: bookmarkLabel)

        // 3. Open the PDF from the pinned site and verify the URL.
        // Tap on the pinned PDF item.
        topSites.tapOnPinnedSite(named: bookmarkLabel)
        waitUntilPageLoad()

        // Assert the browser is showing the correct PDF URL.
        browser.assertAddressBarContains(value: PDF_website["pdfValue"]!)

        // 4. Go back to the homepage and unpin the item.
        navigator.performAction(Action.OpenNewTabFromTabTray)
        topSites.assertTopSiteExists(named: bookmarkLabel)

        // Long-press the pinned site to open the context menu.
        topSites.longPressOnPinnedSite(named: bookmarkLabel)

        // Remove the pinned site via the context menu.
        contextMenu.unpinFromTopSites()

        // 5. Verify the item has been unpinned.
        topSites.assertTopSiteDoesNotExist(named: bookmarkLabel)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307121
    // Smoketest
    func testBookmarkPDF() {
        library = LibraryScreen(app: app)
        // Open the PDF URL and wait for the page to load
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()

        // Navigate to the browser menu and perform the bookmark action
        navigator.goto(BrowserTabMenu)
        navigator.performAction(Action.Bookmark)

        // Navigate to the bookmarks section
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Bookmarks)

        // Assert that the bookmarked item exists
        library.assertBookmarkExists(named: PDF_website["bookmarkLabel"]!)
    }

    private func longPressOnPdfLink() {
        let link = app.webViews.links.element(boundBy: 0)
        mozWaitForElementToExist(link)
        let startCoordinate = link.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let endCoordinate = link.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        startCoordinate.press(forDuration: 3, thenDragTo: endCoordinate)
    }
}
