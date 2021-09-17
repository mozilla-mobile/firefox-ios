/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class CollapsedURLTest: BaseTestCase {
    func testCheckCollapsedURL() {
        // Test do not apply to iPad
        if !iPad() {
            // Visit a page that scrolls
            loadWebPage("https://news.ycombinator.com") //

            // Wait for the website to load
            waitForExistence(app.webViews.otherElements["Hacker News"])
            app.swipeUp()
            app.swipeUp()
            let collapsedTruncatedurltextTextView = app.textViews["Collapsed.truncatedUrlText"]
            waitForExistence(collapsedTruncatedurltextTextView)

            XCTAssertTrue(collapsedTruncatedurltextTextView.isHittable)
            XCTAssertEqual(collapsedTruncatedurltextTextView.value as? String, "news.ycombinator.com")

            // After swiping down, the collapsed URL should not be displayed
            app.swipeDown()
            app.swipeDown()
            waitForNoExistence(collapsedTruncatedurltextTextView)
            XCTAssertFalse(collapsedTruncatedurltextTextView.exists)
        }
    }
}
