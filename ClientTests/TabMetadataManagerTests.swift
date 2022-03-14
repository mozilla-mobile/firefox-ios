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
    private let weigths = HistoryHighlightWeights(viewTime: 10.0, frequency: 4.0)

    override func setUp() {
        super.setUp()

        profile = MockProfile(databasePrefix: "metadata_recording_tests")
        profile._reopen()
        tabManager = TabManager(profile: profile, imageStore: nil)
        manager = TabMetadataManager(profile: profile)
    }

    override func tearDown() {
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
        let stringUrl = "https://www.mozilla.org/"
        
        manager.tabGroupData.tabAssociatedSearchTerm = "test search"
        manager.tabGroupData.tabAssociatedSearchUrl = "https://www.apple.com/"
        manager.tabGroupData.tabAssociatedNextUrl = stringUrl
        
        let shouldUpdate = manager.shouldUpdateSearchTermData(webViewUrl: stringUrl)
        XCTAssertFalse(shouldUpdate)
    }
    
    func testUpdateTimerAndObserving_ForOpenURLOnly() throws {
        let stringUrl = "https://www.mozilla.org/"
        let title = "mozilla title"
//        let expectation = expectation(description: "wait for database recording")
        manager.updateTimerAndObserving(state: .openURLOnly, tabTitle: title)
        
        // Waiting 5 seconds for results to be available
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            let hhWeigths = HistoryHighlightWeights(viewTime: 10.0, frequency: 4.0)
            let result = self.profile.places.getHighlights(weights: hhWeigths, limit: 1000).value
            
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.successValue)
            XCTAssertEqual(result.successValue!.count, 1)
            XCTAssertEqual(result.successValue![0].url, stringUrl)
            XCTAssertEqual(result.successValue![0].title?.lowercased(), title)
//            expectation.fulfill()
        }
//        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testUpdateObservationTitle_ForOpenURLOnly() throws {
        let stringUrl = "https://www.developer.org/"
        let title = "Updated Title"
        
//        let expectation = expectation(description: "wait for database recording")
        manager.tabGroupData.tabHistoryCurrentState = TabGroupTimerState.openURLOnly.rawValue
        manager.tabGroupData.tabAssociatedSearchUrl = stringUrl
        manager.updateObservationTitle(title)
        
        // Waiting 5 seconds for results to be available
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            
            let result = self.profile.places.getHighlights(weights: self.weigths, limit: 1000).value
            
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.successValue)
            XCTAssertEqual(result.successValue!.count, 1)
            XCTAssertEqual(result.successValue![0].url, stringUrl)
            XCTAssertEqual(result.successValue![0].title?.lowercased(), title)
//            expectation.fulfill()
        }
//        waitForExpectations(timeout: 5, handler: nil)
    }
}
