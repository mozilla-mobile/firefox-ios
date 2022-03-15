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
        profile._reopen()
        manager = TabMetadataManager(profile: profile)
    }

    override func tearDown() {
        super.tearDown()
        
        profile._shutdown()
        profile = nil
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
    
    func testUpdateObservationTitle_ForOpenURLOnly() throws {
        emptyDB()
        let stringUrl = "https://www.developer.org/"
        let title = "updated title"
        
        let expectation = expectation(description: "historyRecording")
        manager.tabGroupData = TabGroupData(searchTerm: "",
                                            searchUrl: stringUrl,
                                            nextReferralUrl: "",
                                            tabHistoryCurrentState: TabGroupTimerState.openURLOnly.rawValue)
        
        manager.updateObservationTitle(title) {
            let result = self.profile.places.getHistoryMetadataSince(since: 0).value

            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.successValue)
            XCTAssertEqual(result.successValue!.count, 1)
            XCTAssertEqual(result.successValue![0].url, stringUrl)
            XCTAssertEqual(result.successValue![0].title?.lowercased(), title)
            XCTAssertNil(result.successValue![0].referrerUrl)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUpdateObservationTitle_ForNavigatedToDifferentURL() throws {
        emptyDB()
        let stringUrl = "https://www.developer.org/"
        let referralURL = "https://www.developer.org/ref"
        let title = "updated title"
        
        let expectation = expectation(description: "historyRecording")
        manager.tabGroupData = TabGroupData(searchTerm: "",
                                            searchUrl: stringUrl,
                                            nextReferralUrl: referralURL,
                                            tabHistoryCurrentState: TabGroupTimerState.tabNavigatedToDifferentUrl.rawValue)
        
        manager.updateObservationTitle(title) {
            let result = self.profile.places.getHistoryMetadataSince(since: 0).value

            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.successValue)
            XCTAssertEqual(result.successValue!.count, 1)
            XCTAssertEqual(result.successValue![0].url, stringUrl)
            XCTAssertEqual(result.successValue![0].title?.lowercased(), title)
            XCTAssertEqual(result.successValue![0].referrerUrl?.lowercased(), referralURL)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUpdateObservationTitle_ForOpenInNewTab() throws {
        emptyDB()
        let stringUrl = "https://www.developer.org/"
        let referralURL = "https://www.developer.org/ref"
        let title = "updated title"
        
        let expectation = expectation(description: "historyRecording")
        manager.tabGroupData = TabGroupData(searchTerm: "",
                                            searchUrl: stringUrl,
                                            nextReferralUrl: referralURL,
                                            tabHistoryCurrentState: TabGroupTimerState.openInNewTab.rawValue)
        
        manager.updateObservationTitle(title) {
            let result = self.profile.places.getHistoryMetadataSince(since: 0).value

            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.successValue)
            XCTAssertEqual(result.successValue!.count, 1)
            XCTAssertEqual(result.successValue![0].url, stringUrl)
            XCTAssertEqual(result.successValue![0].title?.lowercased(), title)
            XCTAssertEqual(result.successValue![0].referrerUrl?.lowercased(), referralURL)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testNotUpdateObservationTitle_ForTabSwitched() throws {
        emptyDB()
        let stringUrl = "https://www.developer.org/"
        let referralURL = "https://www.developer.org/ref"
        let title = "updated title"
        
        let expectation = expectation(description: "historyRecording")
        manager.tabGroupData = TabGroupData(searchTerm: "",
                                            searchUrl: stringUrl,
                                            nextReferralUrl: referralURL,
                                            tabHistoryCurrentState: TabGroupTimerState.tabSwitched.rawValue)
        // Title should not be updated for this state
        manager.updateObservationTitle(title) {
            let result = self.profile.places.getHistoryMetadataSince(since: 0).value

            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.successValue)
            XCTAssertEqual(result.successValue!.count, 0)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    private func emptyDB() {
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: 0).value.isSuccess)
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: INT64_MAX).value.isSuccess)
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: -1).value.isSuccess)
    }
}
