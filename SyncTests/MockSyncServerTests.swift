/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest
import Shared
import Storage
import Sync

private class MockBackoffStorage: BackoffStorage {
    var serverBackoffUntilLocalTimestamp: Timestamp?

    func clearServerBackoff() {
        serverBackoffUntilLocalTimestamp = nil
    }

    func isInBackoff(now: Timestamp) -> Timestamp? {
        return nil
    }
}

class MockSyncServerTests: XCTestCase {
    var server: MockSyncServer!
    var client: Sync15StorageClient!

    override func setUp() {
        server = MockSyncServer(username: "1234567")
        server.start()
        client = getClient(server)
    }

    private func getClient(server: MockSyncServer) -> Sync15StorageClient? {
        guard let url = server.baseURL.asURL else {
            XCTFail("Couldn't get URL.")
            return nil
        }

        let authorizer: Authorizer = identity
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        print("URL: \(url)")
        return Sync15StorageClient(serverURI: url, authorizer: authorizer, workQueue: queue, resultQueue: queue, backoff: MockBackoffStorage())
    }

    func testDeleteSpec() {
        // Deletion of a collection path itself, versus trailing slash, sets the right flags.
        let all = SyncDeleteRequestSpec.fromPath("/1.5/123456/storage/bookmarks", withQuery: [:])!
        XCTAssertTrue(all.wholeCollection)
        XCTAssertNil(all.ids)

        let some = SyncDeleteRequestSpec.fromPath("/1.5/123456/storage/bookmarks", withQuery: ["ids": "123456,abcdef"])!
        XCTAssertFalse(some.wholeCollection)
        XCTAssertEqual(["123456", "abcdef"], some.ids!)

        let one = SyncDeleteRequestSpec.fromPath("/1.5/123456/storage/bookmarks/123456", withQuery: [:])!
        XCTAssertFalse(one.wholeCollection)
        XCTAssertNil(one.ids)
    }

    func testInfoCollections() {
        server.storeRecords([MockSyncServer.makeValidEnvelope(Bytes.generateGUID(), modified: 0)], inCollection: "bookmarks", now: 1326251111000)
        server.storeRecords([], inCollection: "tabs", now: 1326252222500)
        server.storeRecords([MockSyncServer.makeValidEnvelope(Bytes.generateGUID(), modified: 0)], inCollection: "bookmarks", now: 1326252222000)
        server.storeRecords([MockSyncServer.makeValidEnvelope(Bytes.generateGUID(), modified: 0)], inCollection: "clients",   now: 1326253333000)

        let expectation = self.expectationWithDescription("Waiting for result.")
        let before = decimalSecondsStringToTimestamp(millisecondsToDecimalSeconds(NSDate.now()))!
        client.getInfoCollections().upon { result in
            XCTAssertNotNil(result.successValue)
            guard let response = result.successValue else {
                expectation.fulfill()
                return
            }
            let after = decimalSecondsStringToTimestamp(millisecondsToDecimalSeconds(NSDate.now()))!

            // JSON contents.
            XCTAssertEqual(response.value.collectionNames().sort(), ["bookmarks", "clients", "tabs"])
            XCTAssertEqual(response.value.modified("bookmarks"), 1326252222000)
            XCTAssertEqual(response.value.modified("clients"), 1326253333000)

            // X-Weave-Timestamp.
            XCTAssertLessThanOrEqual(before, response.metadata.timestampMilliseconds)
            XCTAssertLessThanOrEqual(response.metadata.timestampMilliseconds, after)
            // X-Weave-Records.
            XCTAssertEqual(response.metadata.records, 3) // bookmarks, clients, tabs.

            // X-Last-Modified, max of all collection modified timestamps.
            XCTAssertEqual(response.metadata.lastModifiedMilliseconds, 1326253333000)

            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testGet() {
        server.storeRecords([MockSyncServer.makeValidEnvelope("guid", modified: 0)], inCollection: "bookmarks", now: 1326251111000)
        let collectionClient = client.clientForCollection("bookmarks", encrypter: getEncrypter())

        let expectation = self.expectationWithDescription("Waiting for result.")
        let before = decimalSecondsStringToTimestamp(millisecondsToDecimalSeconds(NSDate.now()))!
        collectionClient.get("guid").upon { result in
            XCTAssertNotNil(result.successValue)
            guard let response = result.successValue else {
                expectation.fulfill()
                return
            }
            let after = decimalSecondsStringToTimestamp(millisecondsToDecimalSeconds(NSDate.now()))!

            // JSON contents.
            XCTAssertEqual(response.value.id, "guid")
            XCTAssertEqual(response.value.modified, 1326251111000)

            // X-Weave-Timestamp.
            XCTAssertLessThanOrEqual(before, response.metadata.timestampMilliseconds)
            XCTAssertLessThanOrEqual(response.metadata.timestampMilliseconds, after)
            // X-Weave-Records.
            XCTAssertNil(response.metadata.records)
            // X-Last-Modified.
            XCTAssertEqual(response.metadata.lastModifiedMilliseconds, 1326251111000)

            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)

        // And now a missing record, which should produce a 404.
        collectionClient.get("missing").upon { result in
            XCTAssertNotNil(result.failureValue)
            guard let response = result.failureValue else {
                expectation.fulfill()
                return
            }
            XCTAssertNotNil(response as? NotFound<NSHTTPURLResponse>)
        }
    }

    func testWipeStorage() {
        server.storeRecords([MockSyncServer.makeValidEnvelope("a", modified: 0)], inCollection: "bookmarks", now: 1326251111000)
        server.storeRecords([MockSyncServer.makeValidEnvelope("b", modified: 0)], inCollection: "bookmarks", now: 1326252222000)
        server.storeRecords([MockSyncServer.makeValidEnvelope("c", modified: 0)], inCollection: "clients",   now: 1326253333000)
        server.storeRecords([], inCollection: "tabs")

        // For now, only testing wiping the storage root, which is the only thing we use in practice.
        let expectation = self.expectationWithDescription("Waiting for result.")
        let before = decimalSecondsStringToTimestamp(millisecondsToDecimalSeconds(NSDate.now()))!
        client.wipeStorage().upon { result in
            XCTAssertNotNil(result.successValue)
            guard let response = result.successValue else {
                expectation.fulfill()
                return
            }
            let after = decimalSecondsStringToTimestamp(millisecondsToDecimalSeconds(NSDate.now()))!

            // JSON contents: should be the empty object.
            XCTAssertEqual(response.value.toString(), "{}")

            // X-Weave-Timestamp.
            XCTAssertLessThanOrEqual(before, response.metadata.timestampMilliseconds)
            XCTAssertLessThanOrEqual(response.metadata.timestampMilliseconds, after)
            // X-Weave-Records.
            XCTAssertNil(response.metadata.records)
            // X-Last-Modified.
            XCTAssertNil(response.metadata.lastModifiedMilliseconds)

            // And we really wiped the data.
            XCTAssertTrue(self.server.collections.isEmpty)

            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testPut() {
        // For now, only test uploading crypto/keys.  There's nothing special about this PUT, however.
        let expectation = self.expectationWithDescription("Waiting for result.")
        let before = decimalSecondsStringToTimestamp(millisecondsToDecimalSeconds(NSDate.now()))!
        client.uploadCryptoKeys(Keys.random(), withSyncKeyBundle: KeyBundle.random(), ifUnmodifiedSince: nil).upon { result in
            XCTAssertNotNil(result.successValue)
            guard let response = result.successValue else {
                expectation.fulfill()
                return
            }
            let after = decimalSecondsStringToTimestamp(millisecondsToDecimalSeconds(NSDate.now()))!

            // Contents: should be just the record timestamp.
            XCTAssertLessThanOrEqual(before, response.value)
            XCTAssertLessThanOrEqual(response.value, after)

            // X-Weave-Timestamp.
            XCTAssertLessThanOrEqual(before, response.metadata.timestampMilliseconds)
            XCTAssertLessThanOrEqual(response.metadata.timestampMilliseconds, after)
            // X-Weave-Records.
            XCTAssertNil(response.metadata.records)
            // X-Last-Modified.
            XCTAssertNil(response.metadata.lastModifiedMilliseconds)

            // And we really uploaded the record.
            XCTAssertNotNil(self.server.collections["crypto"])
            XCTAssertNotNil(self.server.collections["crypto"]?.records["keys"])

            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
}
