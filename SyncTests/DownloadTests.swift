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

    func makeValidEnvelope(guid: GUID, modified: Timestamp) -> EnvelopeJSON {
        let clientBody: [String: AnyObject] = [
            "name": "Foobar",
            "commands": [],
            "type": "mobile",
        ]
        let clientBodyString = JSON(clientBody).toString(false)
        let clientRecord: [String : AnyObject] = [
            "id": guid,
            "collection": "clients",
            "payload": clientBodyString,
            "modified": Double(modified) / 1000,
        ]
        return EnvelopeJSON(JSON(clientRecord).toString(false))
    }
}
