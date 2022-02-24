/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */
 
import Foundation
import XCTest

class BasicBrowsing: BaseTestCase {

    // Smoke test
    func testLaunchExternalApp() {
        // Load URL
        loadWebPage("https://www.example.com")
        waitForWebPageLoad()

        // Tap on Page Action button
        waitForExistence(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()

        // Tap Share button
        
        let shareButton: XCUIElement
        if #available(iOS 14, *) {
            shareButton = app.cells.buttons["Share Page With..."]
        } else {
            shareButton = app.cells["Share Page With..."]
        }
        waitForExistence(shareButton)
        shareButton.tap()

        // Launch external app
        let RemindersApp = app.collectionViews.scrollViews.cells.element(boundBy: 1)
        waitForExistence(RemindersApp, timeout: 5)
        RemindersApp.tap()
        waitForExistence(app.buttons["Add"], timeout: 10)
        XCTAssertTrue(app.buttons["Add"].exists)
    }
    
    // Smoke test
    func testAdBlocking() {
        // Load URL
        loadWebPage("https://blockads.fivefilters.org/")
        waitForWebPageLoad()

        // Check ad blocking is enabled
        let TrackingProtection = app.staticTexts["Ad blocking enabled!"]
        XCTAssertTrue(TrackingProtection.exists)
    }

    // Smoketest
    func testNavigationToolbar() {
        loadWebPage("example.com")
        waitForWebPageLoad()
        waitForExistence(app.textFields["URLBar.urlText"])
        app.textFields["URLBar.urlText"].tap()
        app.buttons["icon clear"].tap()

        loadWebPage("mozilla.org")
        waitForWebPageLoad()

        // Tap Reload button
        app.buttons["BrowserToolset.stopReloadButton"].tap()
        waitForWebPageLoad()
        waitForValueContains( app.textFields["URLBar.urlText"], value: "mozilla")

        // Tap Back button to load example.com
        app.buttons["Back"].tap()
        waitForWebPageLoad()
        waitForValueContains(app.textFields["URLBar.urlText"], value: "example")

        // Tap Forward button to load mozilla.org
        app.buttons["Forward"].tap()
        waitForWebPageLoad()
        waitForValueContains(app.textFields["URLBar.urlText"], value: "mozilla")

        // Tap Reload button and Stop button
        app.buttons["BrowserToolset.stopReloadButton"].tap()
        waitForWebPageLoad()
        waitForValueContains(app.textFields["URLBar.urlText"], value: "mozilla")
        app.buttons["BrowserToolset.stopReloadButton"].tap()
        waitForValueContains(app.textFields["URLBar.urlText"], value: "mozilla")
    }
}
