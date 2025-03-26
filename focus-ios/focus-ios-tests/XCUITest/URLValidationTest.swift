// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

class URLValidationTest: BaseTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = true
    }

    let urlTypes = ["mozilla.org", "mozilla.org/", "https://mozilla.org", "mozilla.org/en", "mozilla.org/en-",
                    "mozilla.org/en-US", "https://mozilla.org/", "https://mozilla.org/en", "https://mozilla.org/en-US"]
    let urlHttpTypes=["http://example.com", "http://example.com/"]

    // https://mozilla.testrail.io/index.php?/cases/view/2460275
    func testDifferentURLTypes() {
        for i in urlTypes {
            loadAndValidateURL(URL: i)
        }

        for i in urlHttpTypes {
            loadAndValidateHttpURLs(URL: i)
        }
    }

    private func loadAndValidateURL(URL: String) {
        loadWebPage(URL)
        waitForWebPageLoad()
        if !iPad() {
            mozWaitForElementToExist(app.buttons["Menu"])
        }
        XCTAssertTrue(app.otherElements.staticTexts.elementContainingText("Mozilla").exists)
        mozWaitForElementToExist(app.textFields["URLBar.urlText"])
        waitForValueContains(app.textFields["URLBar.urlText"], value: "mozilla.org")
    }

    private func loadAndValidateHttpURLs(URL: String) {
        loadWebPage(URL)
        waitForWebPageLoad()
        mozWaitForElementToExist(app.otherElements.staticTexts["Example Domain"])
        mozWaitForElementToExist(app.textFields["URLBar.urlText"])
        waitForValueContains(app.textFields["URLBar.urlText"], value: "example.com")
    }
}
