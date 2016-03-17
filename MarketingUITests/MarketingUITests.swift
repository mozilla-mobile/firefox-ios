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

    func test00SkipIntro() {
        app.buttons["IntroViewController.startBrowsingButton"].tap()
    }

    func test01Homescreen() {
    }

    func test02Bookmarks() {
    }

    func test03History() {
    }

    func test04Sync() {
    }

    func test05ReadingList() {
    }

    func test06Tabs() {
    }

    func test07PrivateBrowsing() {
        let app = XCUIApplication()
        app.buttons["URLBarView.tabsButton"].tap()
        app.buttons["TabTrayController.togglePrivateMode"].tap()
        snapshot("07PrivateBrowsing")
    }

    func test08SearchResults() {
    }
}
