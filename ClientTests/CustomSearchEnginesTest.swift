/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import Shared
import Storage
import Sync
import UIKit

import XCTest

class CustomSearchEnginesTest: XCTestCase {

    func testgetSearchTemplate() {
        let profile = MockBrowserProfile(localName: "customSearchTests")
        let customSearchEngineForm = CustomSearchViewController()
        customSearchEngineForm.profile = profile

        let template = customSearchEngineForm.getSearchTemplate(withString: "https://github.com/search=%s")
        XCTAssertEqual(template, "https://github.com/search={searchTerms}")

        let badTemplate = customSearchEngineForm.getSearchTemplate(withString: "https://github.com/search=blah")
        XCTAssertNil(badTemplate)
   }

    func testaddSearchEngine() {
        let profile = MockBrowserProfile(localName: "customSearchTests")
        let customSearchEngineForm = CustomSearchViewController()
        customSearchEngineForm.profile = profile
        let q = "http://www.google.ca/?#q=%s"
        let title = "YASE"

        let expectation = self.expectation(description: "Waiting on favicon fetching")
        customSearchEngineForm.createEngine(forQuery: q, andName: title).uponQueue(DispatchQueue.main) { result in
            XCTAssertNotNil(result.successValue, "Make sure the new engine is not nil")
            let engine = result.successValue!
            XCTAssertEqual(engine.shortName, title)
            XCTAssertNotNil(engine.image)
            XCTAssertEqual(engine.searchTemplate, "http://www.google.ca/?#q={searchTerms}")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testaddSearchEngineFailure() {
        let profile = MockBrowserProfile(localName: "customSearchTests")
        let customSearchEngineForm = CustomSearchViewController()
        customSearchEngineForm.profile = profile
        let q = "isthisvalid.com/hhh%s"
        let title = "YASE"

        let expectation = self.expectation(description: "Waiting on favicon fetching")
        customSearchEngineForm.createEngine(forQuery: q, andName: title).uponQueue(DispatchQueue.main) { result in
            XCTAssertNil(result.successValue, "Make sure the new engine is nil")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
