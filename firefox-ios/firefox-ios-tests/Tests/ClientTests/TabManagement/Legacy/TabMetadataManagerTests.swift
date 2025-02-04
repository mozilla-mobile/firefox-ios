// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import XCTest

@testable import Client
@testable import Storage

class TabMetadataManagerTests: XCTestCase {
    private var metadataObserver: HistoryMetadataObserverMock!
    private var manager: LegacyTabMetadataManager!

    override func setUp() {
        super.setUp()

        metadataObserver = HistoryMetadataObserverMock()
        manager = LegacyTabMetadataManager(metadataObserver: metadataObserver)
    }

    override func tearDown() {
        metadataObserver = nil
        manager = nil
        super.tearDown()
    }

    // MARK: - Should Update Search Term Data

    func testShouldUpdateSearchTermData() throws {
        let stringUrl = "www.mozilla.org"

        manager.tabGroupData.tabAssociatedSearchTerm = "test search"
        manager.tabGroupData.tabAssociatedSearchUrl = "internal://local/about/home"
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

    // MARK: - Update Observation Title

    func testUpdateObservationTitle_ForOpenURLOnly() throws {
        let stringUrl = "https://www.developer.org/"
        let title = "updated title"

        manager.tabGroupData = LegacyTabGroupData(searchTerm: "",
                                                  searchUrl: stringUrl,
                                                  nextReferralUrl: "",
                                                  tabHistoryCurrentState: LegacyTabGroupTimerState.openURLOnly.rawValue)

        manager.updateObservationTitle(title) {
            XCTAssertEqual(self.metadataObserver.observation?.url, stringUrl)
            XCTAssertEqual(self.metadataObserver.observation?.title?.lowercased(), title)
            XCTAssertEqual(self.metadataObserver.observation?.referrerUrl, "")
        }
    }

    func testUpdateObservationTitle_ForNavigatedToDifferentURL() throws {
        let stringUrl = "https://www.developer.org/"
        let referralURL = "https://www.developer.org/ref"
        let title = "updated title"

        manager.tabGroupData = LegacyTabGroupData(
            searchTerm: "",
            searchUrl: stringUrl,
            nextReferralUrl: referralURL,
            tabHistoryCurrentState: LegacyTabGroupTimerState.tabNavigatedToDifferentUrl.rawValue
        )

        manager.updateObservationTitle(title) {
            XCTAssertEqual(self.metadataObserver.observation?.url, stringUrl)
            XCTAssertEqual(self.metadataObserver.observation?.title?.lowercased(), title)
            XCTAssertEqual(self.metadataObserver.observation?.referrerUrl?.lowercased(), referralURL)
        }
    }

    func testNotUpdateObservationTitle_ForOpenInNewTab() throws {
        let stringUrl = "https://www.developer.org/"
        let referralURL = "https://www.developer.org/ref"
        let title = "updated title"

        manager.tabGroupData = LegacyTabGroupData(
            searchTerm: "",
            searchUrl: stringUrl,
            nextReferralUrl: referralURL,
            tabHistoryCurrentState: LegacyTabGroupTimerState.openInNewTab.rawValue
        )

        // Title should not be updated for this state
        manager.updateObservationTitle(title) {
            XCTAssertNil(self.metadataObserver.observation)
            XCTAssertNil(self.metadataObserver.key)
        }
    }

    func testNotUpdateObservationTitle_ForTabSwitched() throws {
        let stringUrl = "https://www.developer.org/"
        let referralURL = "https://www.developer.org/ref"
        let title = "updated title"

        manager.tabGroupData = LegacyTabGroupData(searchTerm: "",
                                                  searchUrl: stringUrl,
                                                  nextReferralUrl: referralURL,
                                                  tabHistoryCurrentState: LegacyTabGroupTimerState.tabSwitched.rawValue)

        // Title should not be updated for this state
        manager.updateObservationTitle(title) {
            XCTAssertNil(self.metadataObserver.observation)
            XCTAssertNil(self.metadataObserver.key)
        }
    }
}

class HistoryMetadataObserverMock: HistoryMetadataObserver {
    var key: HistoryMetadataKey?
    var observation: HistoryMetadataObservation?

    func noteHistoryMetadataObservation(key: HistoryMetadataKey,
                                        observation: HistoryMetadataObservation,
                                        completion: @escaping () -> Void) {
        self.key = key
        self.observation = observation
        completion()
    }
}
