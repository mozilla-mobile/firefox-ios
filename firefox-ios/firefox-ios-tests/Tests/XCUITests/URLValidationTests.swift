// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class URLValidationTests: BaseTestCase {
    let urlTypes = ["www.mozilla.org", "www.mozilla.org/", "https://www.mozilla.org", "www.mozilla.org/en", "www.mozilla.org/en-",
                    "www.mozilla.org/en-US", "https://www.mozilla.org/", "https://www.mozilla.org/en", "https://www.mozilla.org/en-US"]
    let urlHttpTypes = ["http://example.com", "http://example.com/"]
    let urlField = XCUIApplication().textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
    var browserScreen: BrowserScreen!

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = true
        navigator.goto(SearchSettings)
        app.tables.switches["Show Search Suggestions"].waitAndTap()
        // Skip FirefoxSuggest setting for FirefoxBeta and Firefox
        if isFennec {
            scrollToElement(app.tables.switches["FirefoxSuggestShowNonSponsoredSuggestions"])
            app.tables.switches["FirefoxSuggestShowNonSponsoredSuggestions"].waitAndTap()
        }
        navigator.goto(NewTabScreen)
        browserScreen = BrowserScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2460854
    // Smoketest
    func testDifferentURLTypes() {
        for url in urlTypes {
            navigator.openURL(url)
            waitUntilPageLoad()
            browserScreen.assertMozillaPageLoaded(urlField: urlField)
            clearURL()
        }

        for url in urlHttpTypes {
            navigator.openURL(url)
            waitUntilPageLoad()
            browserScreen.assertExampleDomainLoaded(urlField: urlField)
            clearURL()
        }
    }

    private func clearURL() {
        navigator.nowAt(BrowserTab)
        navigator.goto(URLBarOpen)
        browserScreen.clearURL()
    }
}
