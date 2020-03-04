/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let website = ["url": "www.mozilla.org", "value": "www.mozilla.org", "subDomain": "https://www.mozilla.org/en-US/firefox/products"]

let websiteExample = ["url": "www.example.com", "value": "www.example.com"]


class DomainAutocompleteTest: BaseTestCase {

    let testWithDB = ["testAutocomplete","testAutocompleteDeletingChars","testDeleteEntireString","testNoMatches","testMixedCaseAutocompletion", "testDeletingCharsUpdateTheResults"]

    // This DB contains 3 entries mozilla.com/github.com/git.es
    let historyDB = "browserAutocomplete.db"

    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = String(parts[1])
        if testWithDB.contains(key) {
            // for the current test name, add the db fixture used
            launchArguments = [LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.LoadDatabasePrefix + historyDB]
        }
        super.setUp()
    }

    func testAutocomplete() {
        // Basic autocompletion cases
        navigator.goto(URLBarOpen)
        Base.app.textFields["address"].typeText("w")

        Base.helper.waitForValueContains(Base.app.textFields["address"], value: website["value"]!)
        let value = Base.app.textFields["address"].value
        XCTAssertEqual(value as? String, website["value"]!, "Wrong autocompletion")

        // Enter the complete website and check that there is not more text added, just what user typed
        Base.app.buttons["Clear text"].tap()
        Base.app.textFields["address"].typeText(website["value"]!)
        Base.helper.waitForValueContains(Base.app.textFields["address"], value: website["value"]!)
        let value2 = Base.app.textFields["address"].value
        XCTAssertEqual(value2 as? String, website["value"]!, "Wrong autocompletion")
    }
    // Test that deleting characters works correctly with autocomplete
    func testAutocompleteDeletingChars() {
        navigator.goto(URLBarOpen)
        Base.app.textFields["address"].typeText("www.moz")

        // First delete the autocompleted part
        Base.app.textFields["address"].typeText("\u{0008}")
        // Then remove an extra char and check that the autocompletion stops working
        Base.app.textFields["address"].typeText("\u{0008}")
        Base.helper.waitForValueContains(Base.app.textFields["address"], value: "mo")
        // Then write another letter and the autocompletion works again
        Base.app.textFields["address"].typeText("z")
        Base.helper.waitForValueContains(Base.app.textFields["address"], value: "moz")

        let value = Base.app.textFields["address"].value
        XCTAssertEqual(value as? String, website["value"]!, "Wrong autocompletion")
    }
    // Delete the entire string and verify that the home panels are shown again.
    func testDeleteEntireString() {
        navigator.goto(URLBarOpen)
        Base.app.textFields["address"].typeText("www.moz")
        Base.helper.waitForExistence(Base.app.buttons["Clear text"])
        Base.app.buttons["Clear text"].tap()

        // Check that the address field is empty and that the home panels are shown
        let value = Base.app.textFields["address"].value
        XCTAssertEqual(value as? String, "", "The url has not been removed correctly")

        Base.helper.waitForExistence(Base.app.cells["TopSitesCell"])
    }

    // Ensure that the scheme is included in the autocompletion.
    func testEnsureSchemeIncludedAutocompletion() {
        navigator.openURL(websiteExample["url"]!)
        Base.helper.waitUntilPageLoad()
        navigator.goto(URLBarOpen)
        Base.app.textFields["address"].typeText("http")
        Base.helper.waitForValueContains(Base.app.textFields["address"], value: "example")
        let value = Base.app.textFields["address"].value
        XCTAssertEqual(value as? String, "http://www.example.com", "Wrong autocompletion")
    }
    // Non-matches.
    func testNoMatches() {
        navigator.openURL("twitter.com/login")
        navigator.goto(URLBarOpen)
        Base.app.textFields["address"].typeText("baz")
        let value = Base.app.textFields["address"].value
        // Check there is not more text added, just what user typed
        XCTAssertEqual(value as? String, "baz", "Wrong autocompletion")

        // Ensure we don't match against TLDs.
        Base.app.buttons["Clear text"].tap()
        Base.app.textFields["address"].typeText(".com")
        let value2 = Base.app.textFields["address"].value
        // Check there is not more text added, just what user typed
        XCTAssertEqual(value2 as? String, ".com", "Wrong autocompletion")

        // Ensure we don't match other characters ie: ., :, /
        Base.app.buttons["Clear text"].tap()
        Base.app.textFields["address"].typeText(".")
        let value3 = Base.app.textFields["address"].value
        XCTAssertEqual(value3 as? String, ".", "Wrong autocompletion")

        Base.app.buttons["Clear text"].tap()
        Base.app.textFields["address"].typeText(":")
        let value4 = Base.app.textFields["address"].value
        XCTAssertEqual(value4 as? String, ":", "Wrong autocompletion")

        Base.app.buttons["Clear text"].tap()
        Base.app.textFields["address"].typeText("/")
        let value5 = Base.app.textFields["address"].value
        XCTAssertEqual(value5 as? String, "/", "Wrong autocompletion")

        // Ensure we don't match strings that don't start a word.
        Base.app.buttons["Clear text"].tap()
        Base.app.textFields["address"].typeText("tter")
        let value6 = Base.app.textFields["address"].value
        XCTAssertEqual(value6 as? String, "tter", "Wrong autocompletion")

        // Ensure we don't match words outside of the domain
        Base.app.buttons["Clear text"].tap()
        Base.app.textFields["address"].typeText("login")
        let value7 = Base.app.textFields["address"].value
        XCTAssertEqual(value7 as? String, "login", "Wrong autocompletion")
    }
    // Test default domains.
    func testDefaultDomains() {
        navigator.goto(URLBarOpen)
        Base.app.textFields["address"].typeText("a")
        Base.helper.waitForValueContains(Base.app.textFields["address"], value: ".com")
        let value = Base.app.textFields["address"].value
        XCTAssertEqual(value as? String, "amazon.com", "Wrong autocompletion")

        Base.app.buttons["Clear text"].tap()
        Base.app.textFields["address"].typeText("an")
        Base.helper.waitForValueContains(Base.app.textFields["address"], value: ".com")
        let value2 = Base.app.textFields["address"].value
        XCTAssertEqual(value2 as? String, "answers.com", "Wrong autocompletion")

        Base.app.buttons["Clear text"].tap()
        Base.app.textFields["address"].typeText("anc")
        Base.helper.waitForValueContains(Base.app.textFields["address"], value: ".com")
        let value3 = Base.app.textFields["address"].value
        XCTAssertEqual(value3 as? String, "ancestry.com", "Wrong autocompletion")
    }
    // Test mixed case autocompletion.
    func testMixedCaseAutocompletion() {
        navigator.goto(URLBarOpen)
        Base.app.textFields["address"].typeText("MoZ")
        Base.helper.waitForValueContains(Base.app.textFields["address"], value: ".org")
        let value = Base.app.textFields["address"].value
        XCTAssertEqual(value as? String, "MoZilla.org", "Wrong autocompletion")

        // Test that leading spaces still show suggestions.
        Base.app.buttons["Clear text"].tap()
        Base.app.textFields["address"].typeText("    moz")
        Base.helper.waitForValueContains(Base.app.textFields["address"], value: ".org")
        let value2 = Base.app.textFields["address"].value
        XCTAssertEqual(value2 as? String, "    mozilla.org", "Wrong autocompletion")

        // Test that trailing spaces do *not* show suggestions.
        Base.app.buttons["Clear text"].tap()
        Base.app.textFields["address"].typeText("    moz ")
        Base.helper.waitForValueContains(Base.app.textFields["address"], value: "moz")
        let value3 = Base.app.textFields["address"].value
        // No autocompletion, just what user typed
        XCTAssertEqual(value3 as? String, "    moz ", "Wrong autocompletion")
    }

    // This test is disabled for general schema due to bug 1494269
    func testDeletingCharsUpdateTheResults() {
        let url1 = ["url" : "git.es", "label" : "git.es - Dominio premium en venta"]
        let url2 = ["url" : "github.com", "label" : "The world's leading software development platform · GitHub"]

        navigator.goto(URLBarOpen)
        Base.app.typeText("gith")

        Base.helper.waitForExistence(Base.app.tables["SiteTable"].cells.staticTexts[url2["label"]!])
        // There should be only one matching entry
        XCTAssertTrue(Base.app.tables["SiteTable"].staticTexts[url2["label"]!].exists)
        XCTAssertFalse(Base.app.tables["SiteTable"].staticTexts[url1["label"]!].exists)

        // Remove 2 chars ("th")  to have two coincidences with git
        Base.app.typeText("\u{0008}")
        Base.app.typeText("\u{0008}")

        XCTAssertTrue(Base.app.tables["SiteTable"].staticTexts[url2["label"]!].exists)
        XCTAssertTrue(Base.app.tables["SiteTable"].staticTexts[url1["label"]!].exists)

        // Remove All chars so that there is not any matches
        let charsAddressBar: String = (Base.app.textFields["address"].value! as? String)!

        for _ in 1...charsAddressBar.count {
            Base.app.typeText("\u{0008}")
        }

        Base.helper.waitForNoExistence(Base.app.tables["SiteTable"].staticTexts[url2["label"]!])
        XCTAssertFalse(Base.app.tables["SiteTable"].staticTexts[url2["label"]!].exists)
        XCTAssertFalse(Base.app.tables["SiteTable"].staticTexts[url1["label"]!].exists)
    }
}
