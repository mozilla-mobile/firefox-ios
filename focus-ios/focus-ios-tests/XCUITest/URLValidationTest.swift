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

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2460275
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
        XCTAssertTrue(app.otherElements.staticTexts["Mozilla"].exists, "The website was not loaded properly")
        if !iPad() {
            XCTAssertTrue(app.buttons["Menu"].exists)
        }
        XCTAssertEqual(app.textFields["URLBar.urlText"].value as? String, "www.mozilla.org")
    }
    
    private func loadAndValidateHttpURLs(URL: String) {
        loadWebPage(URL)
        waitForWebPageLoad()
        XCTAssertTrue(app.otherElements.staticTexts["Example Domain"].exists, "The website was not loaded properly")
        XCTAssertEqual(app.textFields["URLBar.urlText"].value as? String, "example.com")
    }
}
