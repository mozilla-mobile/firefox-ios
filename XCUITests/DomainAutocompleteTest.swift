/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let website = ["url": "www.mozilla.org", "value": "www.mozilla.org", "subDomain": "https://www.mozilla.org/en-US/firefox/products"]

class DomainAutocompleteTest: BaseTestCase {
    func testAutocomplete() {
        navigator.openURL(urlString: website["url"]!)

        // Basic autocompletion cases
        navigator.goto(URLBarOpen)
        app.textFields["address"].typeText("w")

        waitForValueContains(app.textFields["address"], value: website["value"]!)
        let value = app.textFields["address"].value
        XCTAssertEqual(value as? String, website["value"]!, "Wrong autocompletion")

        // Enter the complete website and check that there is not more text added, just what user typed
        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText(website["value"]!)
        waitForValueContains(app.textFields["address"], value: website["value"]!)
        let value2 = app.textFields["address"].value
        XCTAssertEqual(value2 as? String, website["value"]!, "Wrong autocompletion")
    }
    // Test that deleting characters works correctly with autocomplete
    func testAutocompleteDeletingChars() {
        navigator.openURL(urlString: website["url"]!)
        navigator.goto(URLBarOpen)
        app.textFields["address"].typeText("www.moz")

        // First delete the autocompleted part
        app.textFields["address"].typeText("\u{0008}")
        // Then remove an extra char and check that the autocompletion stops working
        app.textFields["address"].typeText("\u{0008}")
        waitForValueContains(app.textFields["address"], value: "mo")
        // Then write another letter and the autocompletion works again
        app.textFields["address"].typeText("z")
        waitForValueContains(app.textFields["address"], value: "moz")

        let value = app.textFields["address"].value
        XCTAssertEqual(value as? String, website["value"]!, "Wrong autocompletion")
    }
    // Delete the entire string and verify that the home panels are shown again.
    func testDeleteEntireString() {
        navigator.openURL(urlString: website["url"]!)
        navigator.goto(URLBarOpen)
        app.textFields["address"].typeText("www.moz")
        waitforExistence(app.buttons["Clear text"])
        app.buttons["Clear text"].tap()

        // Check that the address field is empty and that the home panels are shown
        let value = app.textFields["address"].value
        XCTAssertEqual(value as? String, "", "The url has not been removed correctly")

        waitforExistence(app.buttons["HomePanels.TopSites"])
        XCTAssertFalse(app.buttons["HomePanels.TopSites"].isEnabled)
        XCTAssertTrue(app.buttons["HomePanels.Bookmarks"].isEnabled)
    }
    // Ensure that the scheme is included in the autocompletion.
    func testEnsureSchemeIncludedAutocompletion() {
        navigator.openURL(urlString: website["url"]!)
        waitUntilPageLoad()
        navigator.goto(URLBarOpen)
        app.textFields["address"].typeText("https")
        waitForValueContains(app.textFields["address"], value: "mozilla")
        let value = app.textFields["address"].value
        XCTAssertEqual(value as? String, "https://www.mozilla.org", "Wrong autocompletion")
    }
    // Non-matches.
    func testNoMatches() {
        navigator.openURL(urlString: website["url"]!)
        navigator.openURL(urlString: website["subDomain"]!)
        navigator.goto(URLBarOpen)
        app.textFields["address"].typeText("baz")
        let value = app.textFields["address"].value
        // Check there is not more text added, just what user typed
        XCTAssertEqual(value as? String, "baz", "Wrong autocompletion")

        // Ensure we don't match against TLDs.
        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText("org")
        let value2 = app.textFields["address"].value
        // Check there is not more text added, just what user typed
        XCTAssertEqual(value2 as? String, "org", "Wrong autocompletion")

        // Ensure we don't match other characters ie: ., :, /
        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText(".")
        let value3 = app.textFields["address"].value
        XCTAssertEqual(value3 as? String, ".", "Wrong autocompletion")

        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText(":")
        let value4 = app.textFields["address"].value
        XCTAssertEqual(value4 as? String, ":", "Wrong autocompletion")

        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText("/")
        let value5 = app.textFields["address"].value
        XCTAssertEqual(value5 as? String, "/", "Wrong autocompletion")

        // Ensure we don't match strings that don't start a word.
        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText("ozilla")
        let value6 = app.textFields["address"].value
        XCTAssertEqual(value6 as? String, "ozilla", "Wrong autocompletion")

        // Ensure we don't match words outside of the domain
        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText("products")
        let value7 = app.textFields["address"].value
        XCTAssertEqual(value7 as? String, "products", "Wrong autocompletion")
    }
    // Test default domains.
    func testDefaultDomains() {
        navigator.goto(URLBarOpen)
        app.textFields["address"].typeText("a")
        waitForValueContains(app.textFields["address"], value: ".com")
        let value = app.textFields["address"].value
        XCTAssertEqual(value as? String, "amazon.com", "Wrong autocompletion")

        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText("an")
        waitForValueContains(app.textFields["address"], value: ".com")
        let value2 = app.textFields["address"].value
        XCTAssertEqual(value2 as? String, "answers.com", "Wrong autocompletion")

        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText("anc")
        waitForValueContains(app.textFields["address"], value: ".com")
        let value3 = app.textFields["address"].value
        XCTAssertEqual(value3 as? String, "ancestry.com", "Wrong autocompletion")
    }
    // Test mixed case autocompletion.
    func testMixedCaseAutocompletion() {
        navigator.openURL(urlString: website1["url"]!)
        navigator.goto(URLBarOpen)
        app.textFields["address"].typeText("MoZ")
        waitForValueContains(app.textFields["address"], value: ".org")
        let value = app.textFields["address"].value
        XCTAssertEqual(value as? String, "MoZilla.org", "Wrong autocompletion")

        // Test that leading spaces still show suggestions.
        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText("    moz")
        waitForValueContains(app.textFields["address"], value: ".org")
        let value2 = app.textFields["address"].value
        XCTAssertEqual(value2 as? String, "    mozilla.org", "Wrong autocompletion")

        // Test that trailing spaces do *not* show suggestions.
        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText("    moz ")
        waitForValueContains(app.textFields["address"], value: "moz")
        let value3 = app.textFields["address"].value
        // No autocompletion, just what user typed
        XCTAssertEqual(value3 as? String, "    moz ", "Wrong autocompletion")
    }
}
