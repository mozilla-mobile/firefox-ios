// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client
@testable import Storage

class TabMetadataManagerTests: XCTestCase {
    
    private var profile: MockProfile!
    private var manager: TabMetadataManager!

    override func setUp() {
        super.setUp()
        
        profile = MockProfile(databasePrefix: "historyHighlights_tests")
        manager = TabMetadataManager(profile: profile)
    }

    override func tearDown() {
        super.tearDown()

        manager = nil
    }

    func testShouldUpdateSearchTermData() throws {
        let stringUrl = "www.mozilla.org"
        
        manager.tabGroupData.tabAssociatedSearchTerm = "test search"
        manager.tabGroupData.tabAssociatedSearchUrl = "internal://home"
        manager.tabGroupData.tabAssociatedNextUrl = ""
        
        let shouldUpdate = manager.shouldUpdateSearchTermData(webViewUrl: stringUrl)
        XCTAssertTrue(shouldUpdate)
    }
    
    func testNotShouldUpdateSearchTermData_NilNextUrl() throws {
        let shouldUpdate = manager.shouldUpdateSearchTermData(webViewUrl: nil)
        XCTAssertFalse(shouldUpdate)
    }
    
    func testNotShouldUpdateSearchTermData_SameSearchURL() throws {
        let stringUrl = "www.mozilla.org"
        
        manager.tabGroupData.tabAssociatedSearchTerm = "test search"
        manager.tabGroupData.tabAssociatedSearchUrl = stringUrl
        manager.tabGroupData.tabAssociatedNextUrl = "www.apple.com"
        
        let shouldUpdate = manager.shouldUpdateSearchTermData(webViewUrl: stringUrl)
        XCTAssertFalse(shouldUpdate)
    }
    
    func testNotShouldUpdateSearchTermData_SameNextURL() throws {
        let stringUrl = "https://www.mozilla.org/"
        
        manager.tabGroupData.tabAssociatedSearchTerm = "test search"
        manager.tabGroupData.tabAssociatedSearchUrl = "https://www.apple.com/"
        manager.tabGroupData.tabAssociatedNextUrl = stringUrl
        
        let shouldUpdate = manager.shouldUpdateSearchTermData(webViewUrl: stringUrl)
        XCTAssertFalse(shouldUpdate)
    }
}
