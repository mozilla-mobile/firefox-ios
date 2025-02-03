// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import MozillaAppServices
// FXIOS-8331: Disable History Highlight tests while FXIOS-8059 (Epic) is in progress
// FXIOS-8367: Added a ticket to enable these tests when we re-enable history highlights
class HistoryHighlightsDataAdaptorTests: XCTestCase {
    var subject: HistoryHighlightsDataAdaptor!
    var historyManager: MockHistoryHighlightsManager!
    var notificationCenter: MockNotificationCenter!
    var delegate: MockHistoryHighlightsDelegate!
    var deletionUtility: MockHistoryDeletionProtocol!

    override func setUp() {
        super.setUp()

        historyManager = MockHistoryHighlightsManager()
        notificationCenter = MockNotificationCenter()
        delegate = MockHistoryHighlightsDelegate()
        deletionUtility = MockHistoryDeletionProtocol()

        let subject = HistoryHighlightsDataAdaptorImplementation(
            historyManager: historyManager,
            profile: MockProfile(),
            tabManager: MockTabManager(),
            notificationCenter: notificationCenter,
            deletionUtility: deletionUtility)
        subject.delegate = delegate
        notificationCenter.notifiableListener = subject
        self.subject = subject
    }

    override func tearDown() {
        subject = nil
        historyManager = nil
        notificationCenter = nil
        delegate = nil
        deletionUtility = nil
        super.tearDown()
    }

    // Loads history on first launch with data
    func testInitialLoadWithHistoryData() {
        let item: HighlightItem = HistoryHighlight(score: 0, placeId: 0, url: "", title: "", previewImageUrl: "")
        historyManager.callGetHighlightsDataCompletion(result: [item])

        let results = subject.getHistoryHighlights()

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(historyManager.getHighlightsDataCallCount, 1)
        XCTAssertEqual(delegate.didLoadNewDataCallCount, 1)
    }

    // Loads history on first launch without data
    func testInitialLoadWithNoHistoryData() {
        historyManager.callGetHighlightsDataCompletion(result: [])

        let results = subject.getHistoryHighlights()

        XCTAssert(results.isEmpty)
        XCTAssertEqual(historyManager.getHighlightsDataCallCount, 1)
        XCTAssertEqual(delegate.didLoadNewDataCallCount, 1)
    }

    // FXIOS-8107: Disabled test as history highlights has been disabled to fix app hangs / slowness
    // Reloads for notification
    func testReloadDataOnNotification() {
        historyManager.callGetHighlightsDataCompletion(result: [])

        notificationCenter.post(name: .HistoryUpdated)

        let item1: HighlightItem = HistoryHighlight(score: 0, placeId: 0, url: "", title: "", previewImageUrl: "")
        let item2: HighlightItem = HistoryHighlight(score: 0, placeId: 0, url: "", title: "", previewImageUrl: "")
        historyManager.callGetHighlightsDataCompletion(result: [item1, item2])

        let results = subject.getHistoryHighlights()

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(historyManager.getHighlightsDataCallCount, 2)
        XCTAssertEqual(delegate.didLoadNewDataCallCount, 2)
    }

    func testDeleteIndividualItem() {
        let item1: HighlightItem = HistoryHighlight(score: 0,
                                                    placeId: 0,
                                                    url: "www.firefox.com",
                                                    title: "",
                                                    previewImageUrl: "")
        historyManager.callGetHighlightsDataCompletion(result: [item1])

        subject.delete(item1)
        deletionUtility.callDeleteCompletion(result: true)

        XCTAssertEqual(historyManager.getHighlightsDataCallCount, 2)
    }

    func testDeleteGroupItem() {
        let item: HighlightItem = HistoryHighlight(score: 0,
                                                   placeId: 0,
                                                   url: "www.firefox.com",
                                                   title: "",
                                                   previewImageUrl: "")

        let group: HighlightItem = ASGroup(searchTerm: "foxes",
                                           groupedItems: [item],
                                           timestamp: 0)

        historyManager.callGetHighlightsDataCompletion(result: [group])

        subject.delete(group)
        deletionUtility.callDeleteCompletion(result: true)

        XCTAssertEqual(historyManager.getHighlightsDataCallCount, 2)
    }

    func testDelegateMemoryLeak() {
        let delegate = MockHistoryHighlightsDelegate()
        let deletionUtility = MockHistoryDeletionProtocol()

        let subject = HistoryHighlightsDataAdaptorImplementation(
            historyManager: historyManager,
            profile: MockProfile(),
            tabManager: MockTabManager(),
            notificationCenter: notificationCenter,
            deletionUtility: deletionUtility)

        subject.delegate = delegate
        trackForMemoryLeaks(subject)
    }
}
