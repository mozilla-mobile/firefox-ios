/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class MarketingSnapshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            XCUIDevice.sharedDevice().orientation = .LandscapeLeft
        }
    }

    func test01Homescreen() {
        app.buttons["IntroViewController.startBrowsingButton"].tap()
        snapshot("01-HomeScreen")
    }

//    func test02Bookmarks() {
//    }
//
//    func test03History() {
//    }
//
//    func test04Sync() {
//    }
//
//    func test05ReadingList() {
//    }

    func test06Tabs() {
        let urls = [
            "https://www.twitter.com",
            "https://www.mozilla.org/firefox/desktop",
            "https://www.flickr.com",
            "https://www.mozilla.org",
            "https://www.mozilla.org/firefox/developer"
        ]

        for (index, url) in urls.enumerate() {
            // Open a new tab, load the page
            app.buttons["URLBarView.tabsButton"].tap()
            app.buttons["TabTrayController.addTabButton"].tap()
            loadWebPage(url, waitForLoadToFinish: false)
            sleep(15) // TODO Need better mechanism to find out if page has finished loading. Also, mozilla.org/firefox/desktop will need more time to settle because it does animations.
        }

        app.buttons["URLBarView.tabsButton"].tap()
        app.collectionViews["TabTrayController.collectionView"].swipeDown()
        snapshot("06-Tabs")
    }

    func test07PrivateBrowsing() {
        let app = XCUIApplication()
        app.buttons["URLBarView.tabsButton"].tap()
        app.buttons["TabTrayController.togglePrivateMode"].tap()
        snapshot("07-PrivateBrowsing")
    }

//    func test08SearchResults() {
//    }

    private func loadWebPage(url: String, waitForLoadToFinish: Bool = true) {
        let LoadingTimeout: NSTimeInterval = 10
        let exists = NSPredicate(format: "exists = true")
        let loaded = NSPredicate(format: "value BEGINSWITH '100'")

        let app = XCUIApplication()

        UIPasteboard.generalPasteboard().string = url
        app.textFields["url"].pressForDuration(2.0)
        app.sheets.elementBoundByIndex(0).buttons.elementBoundByIndex(0).tap()

        if waitForLoadToFinish {
            let progressIndicator = app.progressIndicators.elementBoundByIndex(0)
            expectationForPredicate(exists, evaluatedWithObject: progressIndicator, handler: nil)
            expectationForPredicate(loaded, evaluatedWithObject: progressIndicator, handler: nil)
            waitForExpectationsWithTimeout(LoadingTimeout, handler: nil)
        }
    }
}
