// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Shared
import Storage
import Sync
import UIKit
import Common
import XCTest

class CustomSearchEnginesTest: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        AppContainer.shared.reset()
        super.tearDown()
    }

    func testgetSearchTemplate() {
        let profile = MockBrowserProfile(localName: "customSearchTests")
        let customSearchEngineForm = CustomSearchViewController(windowUUID: windowUUID)
        customSearchEngineForm.profile = profile

        let template = customSearchEngineForm.getSearchTemplate(withString: "https://github.com/search=%s")
        XCTAssertEqual(template, "https://github.com/search={searchTerms}")

        let badTemplate = customSearchEngineForm.getSearchTemplate(withString: "https://github.com/search=blah")
        XCTAssertNil(badTemplate)
   }

    @MainActor
    func testaddSearchEngine() async {
        let profile = MockBrowserProfile(localName: "customSearchTests")
        let customSearchEngineForm = CustomSearchViewController(windowUUID: windowUUID)
        customSearchEngineForm.profile = profile
        let q = "http://www.google.ca/?#q=%s"
        let title = "YASE"

        do {
            let engine = try await customSearchEngineForm.createEngine(query: q, name: title)

            XCTAssertEqual(engine.shortName, title)
            XCTAssertNotNil(engine.image)
            XCTAssertEqual(engine.searchTemplate, "http://www.google.ca/?#q={searchTerms}")
        } catch {
            XCTFail("Failed to create engine \(error)")
        }
    }

    @MainActor
    func testaddSearchEngineFailure() async {
        let profile = MockBrowserProfile(localName: "customSearchTests")
        let customSearchEngineForm = CustomSearchViewController(windowUUID: windowUUID)
        customSearchEngineForm.profile = profile
        let q = "isthisvalid.com/hhh%s"
        let title = "YASE"

        do {
            _ = try await customSearchEngineForm.createEngine(query: q, name: title)
            XCTFail("Test should have failed to create the engine")
        } catch {
            XCTAssertEqual((error as? CustomSearchError)?.reason, CustomSearchError(.FormInput).reason)
        }
    }
}
