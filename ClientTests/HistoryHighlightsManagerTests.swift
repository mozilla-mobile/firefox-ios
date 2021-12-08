// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client
@testable import Storage

class HistoryHighlightsTests: XCTestCase {
    var profile: MockProfile!

    override func setUp() {
        profile = MockProfile(databasePrefix: "historyHighlights_tests")
    }

    override func tearDown() {
        profile = nil
    }

    func testEmptyRead() {
        emptyDB()

        let emptyRead = profile.places.getHistoryMetadataSince(since: 0).value
        XCTAssertTrue(emptyRead.isSuccess)
        XCTAssertNotNil(emptyRead.successValue)
        XCTAssertEqual(emptyRead.successValue!.count, 0)
    }

    func testSingleDataExists() {
        emptyDB()
        setupData(forTestURL: "https://www.mozilla.com", withTitle: "Mozilla Test", andViewTime: 1)

        let singleItemRead = profile.places.getHistoryMetadataSince(since: 0).value
        XCTAssertTrue(singleItemRead.isSuccess)
        XCTAssertNotNil(singleItemRead.successValue)
        XCTAssertEqual(singleItemRead.successValue!.count, 1)
        XCTAssertEqual(singleItemRead.successValue![0].title, "Mozilla Test")
        XCTAssertEqual(singleItemRead.successValue![0].documentType, DocumentType.regular)
        XCTAssertEqual(singleItemRead.successValue![0].totalViewTime, 1)
    }

    func testHistoryHighlightsDontExist() {
//        emptyDB()
//
//        let expectation = expectation(description: "Highlights")
//
//        HistoryHighlightsManager.getHighlightsForRecentlyViewed(
//            with: profile) { result in
//                expectation.fulfill()
//                XCTAssertTrue(result.isEmpty, "Results should be empty")
//            }
//
//        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSingleHistoryHighlightExists() {
        emptyDB()
        setupData(forTestURL: "https://www.mozilla.com", withTitle: "Mozilla Test", andViewTime: 1)

        let expectation = expectation(description: "Highlights")
        let expectedCount = 1

        HistoryHighlightsManager.getHighlightsForRecentlyViewed(
            with: profile) { result in

                expectation.fulfill()
                XCTAssertEqual(result.count, expectedCount, "There should be one history highlight")
            }

        waitForExpectations(timeout: 5, handler: nil)
    }

    private func emptyDB() {
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: 0).value.isSuccess)
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: INT64_MAX).value.isSuccess)
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: -1).value.isSuccess)
    }

    private func setupData(forTestURL siteURL: String, withTitle title: String, andViewTime viewTime: Int32) {
        let metadataKey1 = HistoryMetadataKey(url: siteURL, searchTerm: nil, referrerUrl: nil)

        XCTAssertTrue(profile.places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: nil,
                documentType: nil,
                title: title
            )
        ).value.isSuccess)

        XCTAssertTrue(profile.places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: viewTime,
                documentType: nil,
                title: nil
            )
        ).value.isSuccess)

        XCTAssertTrue(profile.places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: nil,
                documentType: .regular,
                title: nil
            )
        ).value.isSuccess)
    }
}
