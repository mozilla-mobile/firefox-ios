/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Sync

import XCTest
import SwiftyJSON

func identity<T>(x: T) -> T {
    return x
}

class DownloadTests: XCTestCase {
    func loadEmptyBookmarksIntoServer(server: MockSyncServer) {
        server.storeRecords(records: [], inCollection: "bookmarks")
    }

    func testBasicDownload() {
        let server = getServer(preStart: loadEmptyBookmarksIntoServer)
        server.storeRecords(records: [], inCollection: "bookmarks")

        let storageClient = getClient(server: server)
        let bookmarksClient = storageClient.clientForCollection("bookmarks", encrypter: getEncrypter())

        let expectation = self.expectation(description: "Waiting for result.")
        let deferred = bookmarksClient.getSince(0)
        deferred >>== { response in
            XCTAssertEqual(response.metadata.status, 200)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testDownloadBatches() {
        let guid1: GUID = "abcdefghijkl"
        let ts1: Timestamp = 1326254123650
        let rec1 = MockSyncServer.makeValidEnvelope(guid: guid1, modified: ts1)

        let guid2: GUID = "bbcdefghijkl"
        let ts2: Timestamp = 1326254125650
        let rec2 = MockSyncServer.makeValidEnvelope(guid: guid2, modified: ts2)

        let server = getServer(preStart: loadEmptyBookmarksIntoServer)

        server.storeRecords(records: [rec1], inCollection: "clients", now: ts1)

        let storageClient = getClient(server: server)
        let bookmarksClient = storageClient.clientForCollection("clients", encrypter: getEncrypter())
        let prefs = MockProfilePrefs()

        let batcher = BatchingDownloader(collectionClient: bookmarksClient, basePrefs: prefs, collection: "clients")

        let ic1 = InfoCollections(collections: ["clients": ts1])
        let fetch1 = batcher.go(ic1, limit: 1).value
        XCTAssertEqual(fetch1.successValue, DownloadEndState.complete)
        XCTAssertEqual(0, batcher.baseTimestamp)    // This isn't updated until after success.
        let records1 = batcher.retrieve()
        XCTAssertEqual(1, records1.count)
        XCTAssertEqual(guid1, records1[0].id)
        batcher.advance()
        XCTAssertNotEqual(0, batcher.baseTimestamp)

        // Fetching again yields nothing, because the collection hasn't
        // changed.
        XCTAssertEqual(batcher.go(ic1, limit: 1).value.successValue, DownloadEndState.noNewData)

        // More records. Start again.
        let _ = batcher.reset().value

        let ic2 = InfoCollections(collections: ["clients": ts2])
        server.storeRecords(records: [rec2], inCollection: "clients", now: ts2)

        let fetch2 = batcher.go(ic2, limit: 1).value
        XCTAssertEqual(fetch2.successValue, DownloadEndState.incomplete)
        let records2 = batcher.retrieve()
        XCTAssertEqual(1, records2.count)
        XCTAssertEqual(guid1, records2[0].id)
        batcher.advance()

        let fetch3 = batcher.go(ic2, limit: 1).value
        XCTAssertEqual(fetch3.successValue, DownloadEndState.complete)
        let records3 = batcher.retrieve()
        XCTAssertEqual(1, records3.count)
        XCTAssertEqual(guid2, records3[0].id)
        batcher.advance()

        let fetch4 = batcher.go(ic2, limit: 1).value
        XCTAssertEqual(fetch4.successValue, DownloadEndState.noNewData)
        let records4 = batcher.retrieve()
        XCTAssertEqual(0, records4.count)
        batcher.advance()
    }
}
