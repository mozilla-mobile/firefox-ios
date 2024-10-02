// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import XCTest

@testable import Storage

class RustPlacesTests: XCTestCase {
    var files: FileAccessor!
    var places: RustPlaces!

    override func setUpWithError() throws {
        try super.setUpWithError()
        files = MockFiles()

        let databasePath = URL(
            fileURLWithPath: (try files.getAndEnsureDirectory()),
            isDirectory: true
        ).appendingPathComponent("testplaces.db").path
        try? files.remove("testplaces.db")

        places = RustPlaces(databasePath: databasePath)
        _ = places.reopenIfClosed()
    }

    override func tearDown() {
        _ = places.forceClose()
        places = nil
        super.tearDown()
    }

    /**
        Basic "smoke tests" of the history metadata. Robust test suite exists within the library itself.
     */
    func testHistoryMetadataBasics() {
        XCTAssertTrue(places.deleteHistoryMetadataOlderThan(olderThan: 0).value.isSuccess)
        XCTAssertTrue(places.deleteHistoryMetadataOlderThan(olderThan: INT64_MAX).value.isSuccess)
        XCTAssertTrue(places.deleteHistoryMetadataOlderThan(olderThan: -1).value.isSuccess)

        let emptyRead = places.getHistoryMetadataSince(since: 0).value
        XCTAssertTrue(emptyRead.isSuccess)
        XCTAssertNotNil(emptyRead.successValue)
        XCTAssertEqual(emptyRead.successValue!.count, 0)

        // Observing facts one-by-one.
        let metadataKey1 = HistoryMetadataKey(
            url: "https://www.mozilla.org",
            searchTerm: nil,
            referrerUrl: nil
        )
        XCTAssertTrue(places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: nil,
                documentType: nil,
                title: "Mozilla Test"
            )
        ).value.isSuccess)

        XCTAssertTrue(places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: 1,
                documentType: nil,
                title: nil
            )
        ).value.isSuccess)

        XCTAssertTrue(places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: nil,
                documentType: .regular,
                title: nil
            )
        ).value.isSuccess)

        var singleItemRead = places.getHistoryMetadataSince(since: 0).value
        XCTAssertTrue(singleItemRead.isSuccess)
        XCTAssertNotNil(singleItemRead.successValue)
        XCTAssertEqual(singleItemRead.successValue!.count, 1)
        XCTAssertEqual(singleItemRead.successValue![0].title, "Mozilla Test")
        XCTAssertEqual(singleItemRead.successValue![0].documentType, DocumentType.regular)
        XCTAssertEqual(singleItemRead.successValue![0].totalViewTime, 1)

        // Able to aggregate total view time.
        XCTAssertTrue(places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: 11,
                documentType: nil,
                title: nil
            )
        ).value.isSuccess)

        singleItemRead = places.getHistoryMetadataSince(since: 0).value
        XCTAssertEqual(singleItemRead.successValue!.count, 1)
        XCTAssertEqual(singleItemRead.successValue![0].totalViewTime, 12)

        XCTAssertTrue(places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: 3,
                documentType: nil,
                title: nil
            )
        ).value.isSuccess)

        singleItemRead = places.getHistoryMetadataSince(since: 0).value
        XCTAssertEqual(singleItemRead.successValue!.count, 1)
        XCTAssertEqual(singleItemRead.successValue![0].totalViewTime, 15)

        // Able to change document type.
        XCTAssertTrue(places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: nil,
                documentType: .media,
                title: nil
            )
        ).value.isSuccess)

        singleItemRead = places.getHistoryMetadataSince(since: 0).value
        XCTAssertEqual(singleItemRead.successValue!.count, 1)
        XCTAssertEqual(singleItemRead.successValue![0].documentType, DocumentType.media)

        // Unable to change title.
        XCTAssertTrue(places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: nil,
                documentType: nil,
                title: "New title"
            )
        ).value.isSuccess)
        singleItemRead = places.getHistoryMetadataSince(since: 0).value
        XCTAssertEqual(singleItemRead.successValue!.count, 1)
        XCTAssertEqual(singleItemRead.successValue![0].title, "Mozilla Test")

        // Able to observe facts for multiple keys.
        let metadataKey2 = HistoryMetadataKey(
            url: "https://www.mozilla.org/another",
            searchTerm: nil,
            referrerUrl: "https://www.mozilla.org"
        )
        XCTAssertTrue(places.noteHistoryMetadataObservation(
            key: metadataKey2,
            observation: HistoryMetadataObservation(
                url: metadataKey2.url,
                viewTime: nil,
                documentType: nil,
                title: "Another Mozilla"
            )
        ).value.isSuccess)

        XCTAssertTrue(places.noteHistoryMetadataObservation(
            key: metadataKey2,
            observation: HistoryMetadataObservation(
                url: metadataKey2.url,
                viewTime: nil,
                documentType: .regular,
                title: nil
            )
        ).value.isSuccess)

        var multipleItemsRead = places.getHistoryMetadataSince(since: 0).value
        XCTAssertEqual(multipleItemsRead.successValue!.count, 2)

        // Observations for a different key unaffected.
        if let anotherMozilla = multipleItemsRead.successValue?.first(where: { $0.title == "Another Mozilla" }) {
            XCTAssertEqual(anotherMozilla.documentType, DocumentType.regular)
            XCTAssertEqual(anotherMozilla.totalViewTime, 0)
        } else {
            XCTFail("Expected to find 'Another Mozilla' with total time 0")
        }

        if let mozillaTest = multipleItemsRead.successValue?.first(where: { $0.title == "Mozilla Test" }) {
            XCTAssertEqual(mozillaTest.documentType, DocumentType.media)
            XCTAssertEqual(mozillaTest.totalViewTime, 15)
        } else {
            XCTFail("Expected to find 'Mozilla Test' with total time 15")
        }

        XCTAssertTrue(places.noteHistoryMetadataObservation(
            key: metadataKey2,
            observation: HistoryMetadataObservation(
                url: metadataKey2.url,
                viewTime: 25,
                documentType: nil,
                title: nil
            )
        ).value.isSuccess)
        multipleItemsRead = places.getHistoryMetadataSince(since: 0).value
        XCTAssertEqual(multipleItemsRead.successValue!.count, 2)

        if let anotherMozilla = multipleItemsRead.successValue?.first(where: { $0.title == "Another Mozilla" }) {
            XCTAssertEqual(anotherMozilla.documentType, DocumentType.regular)
            XCTAssertEqual(anotherMozilla.totalViewTime, 25)
        } else {
            XCTFail("Expected to find 'Another Mozilla'")
        }

        if let mozillaTest = multipleItemsRead.successValue?.first(where: { $0.title == "Mozilla Test" }) {
            XCTAssertEqual(mozillaTest.documentType, DocumentType.media)
            XCTAssertEqual(mozillaTest.totalViewTime, 15)
        } else {
            XCTFail("Expected to find 'Mozilla Test'")
        }

        // Able to query by title.
        var queryResults = places.queryHistoryMetadata(query: "another", limit: 0).value
        XCTAssertEqual(queryResults.successValue!.count, 0)
        queryResults = places.queryHistoryMetadata(query: "another", limit: 10).value
        XCTAssertEqual(queryResults.successValue!.count, 1)
        queryResults = places.queryHistoryMetadata(query: "mozilla", limit: 10).value
        XCTAssertEqual(queryResults.successValue!.count, 2)

        // Able to query by url.
        let metadataKey3 = HistoryMetadataKey(
            url: "https://www.firefox.ru/download",
            searchTerm: nil,
            referrerUrl: "https://www.mozilla.org"
        )
        XCTAssertTrue(places.noteHistoryMetadataObservation(
            key: metadataKey3,
            observation: HistoryMetadataObservation(
                url: metadataKey3.url,
                viewTime: nil,
                documentType: nil,
                title: "Скачать Фаерфокс"
            )
        ).value.isSuccess)
        queryResults = places.queryHistoryMetadata(query: "firefox", limit: 10).value
        XCTAssertEqual(queryResults.successValue!.count, 1)
        XCTAssertEqual(queryResults.successValue![0].url, "https://www.firefox.ru/download")
        XCTAssertEqual(queryResults.successValue![0].title, "Скачать Фаерфокс")

        // Able to query by search term.
        let metadataKey4 = HistoryMetadataKey(
            url: "https://www.example.com",
            searchTerm: "Sample webpage",
            referrerUrl: nil
        )
        XCTAssertTrue(places.noteHistoryMetadataObservation(
            key: metadataKey4,
            observation: HistoryMetadataObservation(
                url: metadataKey4.url,
                viewTime: 1337,
                documentType: nil,
                title: nil
            )
        ).value.isSuccess)
        queryResults = places.queryHistoryMetadata(query: "sample", limit: 10).value
        XCTAssertEqual(queryResults.successValue!.count, 1)
        XCTAssertEqual(queryResults.successValue![0].url, "https://www.example.com/")

        // Able to query highlights.
        let highlights = places.getHighlights(
            weights: HistoryHighlightWeights(viewTime: 1.0, frequency: 1.0),
            limit: 10
        ).value
        XCTAssertEqual(highlights.successValue!.count, 4)

        // Deletions.
        queryResults = places.getHistoryMetadataSince(since: 0).value
        XCTAssertEqual(queryResults.successValue!.count, 4)

        // Able to delete individual metadata items by key.
        XCTAssertTrue(places.deleteHistoryMetadata(key: metadataKey4).value.isSuccess)
        queryResults = places.getHistoryMetadataSince(since: 0).value
        XCTAssertEqual(queryResults.successValue!.count, 3)

        // Able to delete since.
        queryResults = places.getHistoryMetadataSince(since: 0).value
        XCTAssertEqual(queryResults.successValue!.count, 3)
        XCTAssertTrue(places.deleteHistoryMetadataOlderThan(olderThan: INT64_MAX).value.isSuccess)
        queryResults = places.getHistoryMetadataSince(since: 0).value
        XCTAssertEqual(queryResults.successValue!.count, 0)
    }
}
