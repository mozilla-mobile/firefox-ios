/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Sync
import XCTest

func identity<T>(x: T) -> T {
    return x
}

private class MockBackoffStorage: BackoffStorage {
    var serverBackoffUntilLocalTimestamp: Timestamp?

    func clearServerBackoff() {
        serverBackoffUntilLocalTimestamp = nil
    }

    func isInBackoff(now: Timestamp) -> Timestamp? {
        return nil
    }
}

// Non-encrypting 'encrypter'.
internal func getEncrypter() -> RecordEncrypter<CleartextPayloadJSON> {
    let serializer: Record<CleartextPayloadJSON> -> JSON? = { $0.payload }
    let factory: String -> CleartextPayloadJSON = { CleartextPayloadJSON($0) }
    return RecordEncrypter(serializer: serializer, factory: factory)
}

class DownloadTests: XCTestCase {
    func getClient(server: MockSyncServer) -> Sync15StorageClient? {
        guard let url = server.baseURL.asURL else {
            XCTFail("Couldn't get URL.")
            return nil
        }

        let authorizer: Authorizer = identity
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        print("URL: \(url)")
        return Sync15StorageClient(serverURI: url, authorizer: authorizer, workQueue: queue, resultQueue: queue, backoff: MockBackoffStorage())
    }

    func getServer() -> MockSyncServer {
        let server = MockSyncServer(username: "1234567")
        server.storeRecords([], inCollection: "bookmarks")
        server.start()
        return server
    }

    func testBasicDownload() {
        let server = getServer()
        server.storeRecords([], inCollection: "bookmarks")

        let storageClient = getClient(server)!
        let bookmarksClient = storageClient.clientForCollection("bookmarks", encrypter: getEncrypter())

        let expectation = self.expectationWithDescription("Waiting for result.")
        let deferred = bookmarksClient.getSince(0)
        deferred >>== { response in
            XCTAssertEqual(response.metadata.status, 200)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testDownloadBatches() {
        let guid1: GUID = "abcdefghijkl"
        let ts1: Timestamp = 1326254123650
        let rec1 = MockSyncServer.makeValidEnvelope(guid1, modified: ts1)

        let guid2: GUID = "bbcdefghijkl"
        let ts2: Timestamp = 1326254125650
        let rec2 = MockSyncServer.makeValidEnvelope(guid2, modified: ts2)

        let server = getServer()
        server.storeRecords([rec1], inCollection: "clients", now: ts1)

        let storageClient = getClient(server)!
        let bookmarksClient = storageClient.clientForCollection("clients", encrypter: getEncrypter())
        let prefs = MockProfilePrefs()

        let batcher = BatchingDownloader(collectionClient: bookmarksClient, basePrefs: prefs, collection: "clients")

        let ic1 = InfoCollections(collections: ["clients": ts1])
        let fetch1 = batcher.go(ic1, limit: 1).value
        XCTAssertEqual(fetch1.successValue, DownloadEndState.Complete)
        let records1 = batcher.retrieve()
        XCTAssertEqual(1, records1.count)
        XCTAssertEqual(guid1, records1[0].id)

        // Fetching again yields nothing, because the collection hasn't
        // changed.
        XCTAssertEqual(batcher.go(ic1, limit: 1).value.successValue, DownloadEndState.NoNewData)

        // More records. Start again.
        batcher.reset().value

        let ic2 = InfoCollections(collections: ["clients": ts2])
        server.storeRecords([rec2], inCollection: "clients", now: ts2)

        let fetch2 = batcher.go(ic2, limit: 1).value
        XCTAssertEqual(fetch2.successValue, DownloadEndState.Incomplete)
        let records2 = batcher.retrieve()
        XCTAssertEqual(1, records2.count)
        XCTAssertEqual(guid1, records2[0].id)

        let fetch3 = batcher.go(ic2, limit: 1).value
        XCTAssertEqual(fetch3.successValue, DownloadEndState.Complete)
        let records3 = batcher.retrieve()
        XCTAssertEqual(1, records3.count)
        XCTAssertEqual(guid2, records3[0].id)
        let fetch4 = batcher.go(ic2, limit: 1).value
        XCTAssertEqual(fetch4.successValue, DownloadEndState.NoNewData)
        let records4 = batcher.retrieve()
        XCTAssertEqual(0, records4.count)
    }
}