// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

let website = [
    "url": "mozilla.org",
    "value": "mozilla.org",
    "subDomain": "https://www.mozilla.org/en-US/firefox/products"
]

let websiteExample = [
    "url": "www.example.com",
    "value": "www.example.com"
]

class DomainAutocompleteTests: BaseTestCase {
    let testWithDB = [
        "test1Autocomplete",
        "test3AutocompleteDeletingChars",
        "test5NoMatches",
        "testMixedCaseAutocompletion",
        "testDeletingCharsUpdateTheResults"
    ]

    // This DB contains 3 entries mozilla.com/github.com/git.es
    let historyDB = "browserAutocomplete-places.db"

    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = String(parts[1])
        if testWithDB.contains(key) {
            // for the current test name, add the db fixture used
            launchArguments = [LaunchArguments.SkipIntro,
                               LaunchArguments.SkipWhatsNew,
                               LaunchArguments.SkipETPCoverSheet,
                               LaunchArguments.LoadDatabasePrefix + historyDB,
                               LaunchArguments.SkipContextualHints,
                               LaunchArguments.DisableAnimations]
        }
        super.setUp()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2334558
    func test1Autocomplete() {
        // Basic autocompletion cases
        // The autocomplete does not display the history item from the DB. Workaround is to manually visit "mozilla.org".
        navigator.openURL("mozilla.org")
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        if isTablet {
            navigator.performAction(Action.AcceptRemovingAllTabs)
        } else {
            navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
        }
        navigator.goto(URLBarOpen)
        urlBarAddress.typeText("moz")

        mozWaitForValueContains(urlBarAddress, value: website["value"]!)
        let value = urlBarAddress.value
        XCTAssertEqual(value as? String, website["value"]!, "Wrong autocompletion")

        // Enter the complete website and check that there is not more text added, just what user typed
        app.buttons["Clear text"].tap()
        urlBarAddress.typeText(website["value"]!)
        mozWaitForValueContains(urlBarAddress, value: website["value"]!)
        let value2 = urlBarAddress.value
        XCTAssertEqual(value2 as? String, website["value"]!, "Wrong autocompletion")
    }

    // Test that deleting characters works correctly with autocomplete
    // https://mozilla.testrail.io/index.php?/cases/view/2334647
    func test3AutocompleteDeletingChars() {
        // The autocomplete does not display the history item from the DB. Workaround is to manually visit "mozilla.org".
        navigator.openURL("mozilla.org")
        waitUntilPageLoad()
        navigator.goto(TabTray)

        navigator.goto(CloseTabMenu)
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.nowAt(HomePanelsScreen)

        navigator.goto(URLBarOpen)
        mozWaitForElementToExist(urlBarAddress)
        urlBarAddress.typeText("moz")

        // First delete the autocompleted part
        urlBarAddress.typeText("\u{0008}")
        // Then remove an extra char and check that the autocompletion stops working
        urlBarAddress.typeText("\u{0008}")
        mozWaitForValueContains(urlBarAddress, value: "mo")
        // Then write another letter and the autocompletion works again
        urlBarAddress.typeText("z")
        mozWaitForValueContains(urlBarAddress, value: "moz")

        if #available(iOS 16, *) {
            let value = urlBarAddress.value
            XCTAssertEqual(value as? String, website["value"]!, "Wrong autocompletion")
        }
    }
    // Delete the entire string and verify that the home panels are shown again.
    // https://mozilla.testrail.io/index.php?/cases/view/2334648
    func test6DeleteEntireString() {
        navigator.goto(URLBarOpen)
        urlBarAddress.typeText("www.moz")
        app.buttons["Clear text"].waitAndTap()

        // Check that the address field is empty and that the home panels are shown
        let value = urlBarAddress.value
        XCTAssertEqual(value as? String, "", "The url has not been removed correctly")

        mozWaitForElementToExist(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
    }

    // Ensure that the scheme is included in the autocompletion.
    // https://mozilla.testrail.io/index.php?/cases/view/2334649
    func test4EnsureSchemeIncludedAutocompletion() {
        navigator.openURL(websiteExample["url"]!)
        waitUntilPageLoad()
        navigator.goto(URLBarOpen)
        urlBarAddress.typeText("ex")
        if #available(iOS 16, *) {
            mozWaitForValueContains(app.otherElements.textFields["Address Bar"], value: "www.example.com/")
            let value = urlBarAddress.value
            XCTAssertEqual(value as? String, "example.com", "Wrong autocompletion")
        }
    }

    // Non-matches.
    // https://mozilla.testrail.io/index.php?/cases/view/2334650
    func test5NoMatches() {
        navigator.openURL("twitter.com/login")
        waitUntilPageLoad()
        navigator.goto(URLBarOpen)
        urlBarAddress.typeText("baz")
        let value = urlBarAddress.value
        // Check there is not more text added, just what user typed
        XCTAssertEqual(value as? String, "baz", "Wrong autocompletion")

        // Ensure we don't match against TLDs.
        app.buttons["Clear text"].tap()
        urlBarAddress.typeText(".com")
        let value2 = urlBarAddress.value
        // Check there is not more text added, just what user typed
        XCTAssertEqual(value2 as? String, ".com", "Wrong autocompletion")

        // Ensure we don't match other characters ie: ., :, /
        app.buttons["Clear text"].tap()
        urlBarAddress.typeText(".")
        let value3 = urlBarAddress.value
        XCTAssertEqual(value3 as? String, ".", "Wrong autocompletion")

        app.buttons["Clear text"].tap()
        urlBarAddress.typeText(":")
        let value4 = urlBarAddress.value
        XCTAssertEqual(value4 as? String, ":", "Wrong autocompletion")

        app.buttons["Clear text"].tap()
        urlBarAddress.typeText("/")
        let value5 = urlBarAddress.value
        XCTAssertEqual(value5 as? String, "/", "Wrong autocompletion")

        // Ensure we don't match strings that don't start a word.
        app.buttons["Clear text"].tap()
        urlBarAddress.typeText("tter")
        let value6 = urlBarAddress.value
        XCTAssertEqual(value6 as? String, "tter", "Wrong autocompletion")

        // Ensure we don't match words outside of the domain
        app.buttons["Clear text"].tap()
        urlBarAddress.typeText("login")
        let value7 = urlBarAddress.value
        XCTAssertEqual(value7 as? String, "login", "Wrong autocompletion")
    }

    // Test default domains.
    // https://mozilla.testrail.io/index.php?/cases/view/2334651
    func test2DefaultDomains() {
        navigator.goto(URLBarOpen)
        urlBarAddress.typeText("a")
        mozWaitForValueContains(urlBarAddress, value: ".com")
        let value = urlBarAddress.value
        XCTAssertEqual(value as? String, "amazon.com", "Wrong autocompletion")

        app.buttons["Clear text"].tap()
        urlBarAddress.typeText("an")
        mozWaitForValueContains(urlBarAddress, value: ".com")
        let value2 = urlBarAddress.value
        XCTAssertEqual(value2 as? String, "answers.com", "Wrong autocompletion")

        app.buttons["Clear text"].tap()
        urlBarAddress.typeText("anc")
        mozWaitForValueContains(urlBarAddress, value: ".com")
        let value3 = urlBarAddress.value
        XCTAssertEqual(value3 as? String, "ancestry.com", "Wrong autocompletion")
    }

    // Test mixed case autocompletion.
    // https://mozilla.testrail.io/index.php?/cases/view/2334653
    func testMixedCaseAutocompletion() {
        navigator.goto(URLBarOpen)
        urlBarAddress.typeText("MoZ")
        mozWaitForValueContains(urlBarAddress, value: ".org")
        let value = urlBarAddress.value
        XCTAssertEqual(value as? String, "MoZilla.org", "Wrong autocompletion")

        // Test that leading spaces still show suggestions.
        app.buttons["Clear text"].tap()
        urlBarAddress.typeText("    moz")
        mozWaitForValueContains(urlBarAddress, value: ".org")
        let value2 = urlBarAddress.value
        XCTAssertEqual(value2 as? String, "    mozilla.org", "Wrong autocompletion")

        // Test that trailing spaces do *not* show suggestions.
        app.buttons["Clear text"].tap()
        urlBarAddress.typeText("    moz ")
        mozWaitForValueContains(urlBarAddress, value: "moz")
        let value3 = urlBarAddress.value
        // No autocompletion, just what user typed
        XCTAssertEqual(value3 as? String, "    moz ", "Wrong autocompletion")
    }
}
