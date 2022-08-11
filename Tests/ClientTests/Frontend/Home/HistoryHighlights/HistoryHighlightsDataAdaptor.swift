// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import MozillaAppServices

class HistoryHighlightsDataAdaptorTests: XCTestCase {

    var subject: HistoryHighlightsDataAdaptor!
    var historyManager: MockHistoryHighlightsManager!
    var notificationCenter: MockNotificationCenter!

    override func setUp() {
        super.setUp()

        historyManager = MockHistoryHighlightsManager()
        notificationCenter = MockNotificationCenter()
        let subject = HistoryHighlightsDataAdaptorImplementation(
            historyManager: historyManager,
            profile: MockProfile(),
            tabManager: MockTabManager(),
            notificationCenter: notificationCenter)
        notificationCenter.notifiableListener = subject
        self.subject = subject
    }

    override func tearDown() {
        super.tearDown()
    }

    // Loads history on first launch
    func testInitialLoadWithHistoryData() {
        let item: HighlightItem = HistoryHighlight(score: 0, placeId: 0, url: "", title: "", previewImageUrl: "")
        historyManager.callGetHighlightsDataCompletion(result: [item])

        let results = subject.getHistoryHightlights()

        XCTAssert(results.count == 1)
        XCTAssert(historyManager.getHighlightsDataCallCount == 1)
    }

    // Reloads for notification
    func testReloadDataOnNotification() {
        historyManager.callGetHighlightsDataCompletion(result: [])

        notificationCenter.post(name: .HistoryUpdated)

        let item1: HighlightItem = HistoryHighlight(score: 0, placeId: 0, url: "", title: "", previewImageUrl: "")
        let item2: HighlightItem = HistoryHighlight(score: 0, placeId: 0, url: "", title: "", previewImageUrl: "")
        historyManager.callGetHighlightsDataCompletion(result: [item1, item2])

        let results = subject.getHistoryHightlights()

        XCTAssert(results.count == 2)
        XCTAssert(historyManager.getHighlightsDataCallCount == 2)
    }
}
