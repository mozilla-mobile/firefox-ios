/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class BrowsingTest: BaseTestCase {
    // Smoke test
    // https://mozilla.testrail.io/index.php?/cases/view/1569888
    func testLaunchExternalApp() {
        // Load URL
        loadWebPage("https://www.example.com")
        waitForWebPageLoad()

        // Tap on Page Action button
        waitForExistence(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()

        // Tap Share button
        // https://mozilla.testrail.io/index.php?/cases/view/1569888
        let shareButton: XCUIElement
        if #available(iOS 14, *) {
            shareButton = app.cells.buttons["Share Page With…"]
        } else {
            shareButton = app.cells["Share Page With..."]
        }
        waitForExistence(shareButton)
        waitForHittable(shareButton)
        shareButton.tap()

        // Launch external app
        let RemindersApp: XCUIElement
        if #available(iOS 17, *) {
            RemindersApp = app.collectionViews.scrollViews.cells["Reminders"]
        } else {
            if iPad() {
                RemindersApp = app.collectionViews.scrollViews.cells.element(boundBy: 0)
            } else {
                RemindersApp = app.collectionViews.scrollViews.cells.element(boundBy: 1)
            }
        }
        waitForExistence(RemindersApp)
        waitForHittable(RemindersApp)
        RemindersApp.tap()
        waitForExistence(app.buttons["Add"])
    }

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/1569889
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

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/2587661
    func testActivityMenuRequestDesktopItem() {
        // Wait for existence rather than hittable because the textfield is technically disabled
        loadWebPage("facebook.com")

        waitForWebPageLoad()
        waitForExistence(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()

        if iPad() {
            waitForExistence(app.collectionViews.buttons["Request Mobile Site"])
            app.collectionViews.buttons["Request Mobile Site"].tap()
        } else {
            waitForExistence(app.collectionViews.buttons["Request Desktop Site"])
            app.collectionViews.buttons["Request Desktop Site"].tap()
        }

        waitForWebPageLoad()

        // https://github.com/mozilla-mobile/focus-ios/issues/2782
        /*
         guard let text = urlBarTextField.value as? String else {
             XCTFail()
             return
         }

         if text.contains("m.facebook") {
             if !iPad() {
                 XCTFail()
             }
         }
        */
    }

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/2587662
    func testCheckCollapsedURL() {
        // Test do not apply to iPad
        if !iPad() {
            // Visit a page that scrolls
            loadWebPage("https://news.ycombinator.com")
            waitForWebPageLoad()

            // Wait for the website to load
            waitForExistence(app.webViews.otherElements["Hacker News"])
            app.swipeUp()
            app.swipeUp()
            let collapsedTruncatedurltextTextView = app.textViews["Collapsed.truncatedUrlText"]
            waitForExistence(collapsedTruncatedurltextTextView)

            waitForHittable(collapsedTruncatedurltextTextView)
            XCTAssertEqual(collapsedTruncatedurltextTextView.value as? String, "news.ycombinator.com")

            // After swiping down, the collapsed URL should not be displayed
            app.swipeDown()
            app.swipeDown()
            waitForNoExistence(collapsedTruncatedurltextTextView)
        }
    }
}
