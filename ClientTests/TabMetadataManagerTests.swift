// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client
@testable import Storage

class TabMetadataManagerTests: XCTestCase {
    
    private var profile: MockProfile!
    private var tabManager: TabManager!
    private var manager: TabMetadataManager!

    override func setUpWithError() throws {
        super.setUp()

        profile = MockProfile(databasePrefix: "metadata_recording_tests")
        profile._reopen()
        tabManager = TabManager(profile: profile, imageStore: nil)
        manager = TabMetadataManager(profile: profile)
    }

    override func tearDownWithError() throws {
        super.tearDown()
        
        profile._shutdown()
        profile = nil
        tabManager = nil
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
        let stringUrl = "www.mozilla.org"
        
        manager.tabGroupData.tabAssociatedSearchTerm = "test search"
        manager.tabGroupData.tabAssociatedSearchUrl = "www.apple.com"
        manager.tabGroupData.tabAssociatedNextUrl = stringUrl
        
        let shouldUpdate = manager.shouldUpdateSearchTermData(webViewUrl: stringUrl)
        XCTAssertFalse(shouldUpdate)
    }
    
    func testUpdateTimerAndObserving_ForOpenURLOnly() throws {
        let stringUrl = "www.mozilla.org"
        let title = "Mozilla title"
        
        emptyDB()
        manager.updateTimerAndObserving(state: .openURLOnly, searchTerm: title, searchProviderUrl: stringUrl, nextUrl: "")
        
        let hhWeigths = HistoryHighlightWeights(viewTime: 10.0,
                                                frequency: 4.0)
        let singleItemRead = profile.places.getHistoryMetadataSince(since: 0).value
        profile.places.getHighlights(weights:hhWeigths, limit: 1000).uponQueue(.main) { result in
            
            guard let ASHighlights = result.successValue, !ASHighlights.isEmpty else { return completion(nil) }

            XCTAssertTrue(singleItemRead.isSuccess)
            XCTAssertNotNil(singleItemRead.successValue)
            XCTAssertEqual(singleItemRead.successValue!.count, 1)
            XCTAssertEqual(singleItemRead.successValue![0].url, stringUrl)
            XCTAssertEqual(singleItemRead.successValue![0].title?.lowercased(), title)
            completion(ASHighlights)
        }
    }
    
    // MARK: - Helper functions
    private func emptyDB() {
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: 0).value.isSuccess)
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: INT64_MAX).value.isSuccess)
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: -1).value.isSuccess)
    }
}
