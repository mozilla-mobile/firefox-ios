/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class NoImageTests: BaseTestCase {
    
    var navigator: Navigator!
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        navigator = createScreenGraph(app).navigator(self)
    }
    
    override func tearDown() {
        navigator = nil
        app = nil
        super.tearDown()
    }
    
    private func showImages() {
        app.buttons["TabToolbar.menuButton"].tap()
        app.collectionViews.containing(.cell, identifier:"FindInPageMenuItem").element.swipeLeft()
        let collectionViewsQuery = app.collectionViews
        collectionViewsQuery.cells["ShowImageModeMenuItem"].tap()
    }
    
    private func hideImages() {
        app.buttons["TabToolbar.menuButton"].tap()
        app.collectionViews.containing(.cell, identifier:"FindInPageMenuItem").element.swipeLeft()
        let collectionViewsQuery = app.collectionViews
        collectionViewsQuery.cells["HideImageModeMenuItem"].tap()
    }
    
    private func checkShowImages() {
        navigator.goto(BrowserTabMenu)
        app.collectionViews.containing(.cell, identifier:"FindInPageMenuItem").element.swipeLeft()
        waitforExistence(app.collectionViews.cells["ShowImageModeMenuItem"])
        navigator.goto(BrowserTab)
    }
    
    private func checkHideImages() {
        navigator.goto(BrowserTabMenu)
        app.collectionViews.containing(.cell, identifier:"FindInPageMenuItem").element.swipeLeft()
        waitforExistence(app.collectionViews.cells["HideImageModeMenuItem"])
        navigator.goto(BrowserTab)
    }
    
    func testImageOnOff() {
    let url1 = "www.google.com"
    
    // Go to a webpage, and select no images or hide images, check it's hidden or not
    navigator.openNewURL(urlString: url1)
    XCTAssertTrue(app.images.count == 2)
    hideImages()
    
    //After image is hidden, only image detected is the lock icon in the UI
    XCTAssertTrue(app.images.count == 1)
    checkShowImages()
    
    // Load a same page on a new tab, check images are hidden
    //navigator.goto(NewTabScreen)
    navigator.openNewURL(urlString: url1)
    
    // Open it, then select show images it, and check it's showing the images
    showImages()
    XCTAssertTrue(app.images.count == 2)
    checkHideImages()
    }
}
