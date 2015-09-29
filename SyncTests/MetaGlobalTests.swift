/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
import Foundation
import Shared
import Storage
@testable import Sync
import XCGLogger
import XCTest

private let log = Logger.syncLogger

class MockSyncAuthState: SyncAuthState {
    let serverRoot: String
    let kB: NSData

    init(serverRoot: String, kB: NSData) {
        self.serverRoot = serverRoot
        self.kB = kB
    }

    func invalidate() {
    }

    func token(now: Timestamp, canBeExpired: Bool) -> Deferred<Maybe<(token: TokenServerToken, forKey: NSData)>> {
        let token = TokenServerToken(id: "id", key: "key", api_endpoint: serverRoot, uid: UInt64(0),
            durationInSeconds: UInt64(5 * 60), remoteTimestamp: Timestamp(now - 1))
        return deferMaybe((token, self.kB))
    }
}

class MetaGlobalTests: XCTestCase {
    var server: MockSyncServer!
    var serverRoot: String!
    var kB: NSData!

    override func setUp() {
        kB = NSData.randomOfLength(32)!
        server = MockSyncServer(username: "1234567")
        server.start()
        serverRoot = server.baseURL
    }

    func now() -> Timestamp {
        return Timestamp(1000 * NSDate().timeIntervalSince1970)
    }

    func storeMetaGlobal(metaGlobal: MetaGlobal) {
        let envelope = EnvelopeJSON(JSON([
            "id": "global",
            "collection": "meta",
            "payload": metaGlobal.asPayload().toString(),
            "modified": Double(NSDate().timeIntervalSince1970)]))
        server.storeRecords([envelope], inCollection: "meta")
    }

    func storeKeys(keys: Keys) {
        let keyBundle = KeyBundle.fromKB(kB)
        let keys = Keys(defaultBundle: keyBundle)
        let record = Record(id: "keys", payload: keys.asPayload())
        let envelope = EnvelopeJSON(keyBundle.serializer({ $0 })(record)!)
        server.storeRecords([envelope], inCollection: "crypto")
    }

    func ready() -> ReadyDeferred {
        let syncPrefs = MockProfilePrefs()
        let authState: SyncAuthState = MockSyncAuthState(serverRoot: serverRoot, kB: kB)
        return SyncStateMachine(prefs: syncPrefs).toReady(authState)
    }

    func assertFreshStart(ready: Ready?, after: Timestamp) {
        XCTAssertNotNil(ready)
        guard let ready = ready else {
            return
        }
        // We should have wiped.
        // We should have uploaded new meta/global and crypto/keys.
        XCTAssertGreaterThan(server.collections["meta"]?["global"]?.modified ?? 0, after)
        XCTAssertGreaterThan(server.collections["crypto"]?["keys"]?.modified ?? 0, after)
        // And we should have downloaded meta/global and crypto/keys.
        XCTAssertNotNil(ready.scratchpad.global)
        XCTAssertNotNil(ready.scratchpad.keys)
        // Basic verifications.
        XCTAssertEqual(ready.collectionKeys.defaultBundle.encKey.length, 32)
        if let clients = ready.scratchpad.global?.value.engines?["clients"] {
            XCTAssertTrue(clients.syncID.characters.count == 12)
        }
    }

    func testMetaGlobalVersionTooNew() {
        // There's no recovery from a meta/global version "in the future": just bail out with an UpgradeRequiredError.
        storeMetaGlobal(MetaGlobal(syncID: "id", storageVersion: 6, engines: [String: EngineMeta](), declined: nil))

        let expectation = expectationWithDescription("Waiting on value.")
        ready().upon { result in
            XCTAssertNotNil(result.failureValue as? UpgradeRequiredError)
            XCTAssertNil(result.successValue)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testMetaGlobalVersionTooOld() {
        // To recover from a meta/global version "in the past", fresh start.
        storeMetaGlobal(MetaGlobal(syncID: "id", storageVersion: 4, engines: [String: EngineMeta](), declined: nil))

        let afterStores = now()
        let expectation = expectationWithDescription("Waiting on value.")
        ready().upon { result in
            self.assertFreshStart(result.successValue, after: afterStores)
            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testMetaGlobalMissing() {
        // To recover from a missing meta/global, fresh start.
        let afterStores = now()
        let expectation = expectationWithDescription("Waiting on value.")
        ready().upon { result in
            self.assertFreshStart(result.successValue, after: afterStores)
            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testCryptoKeysMissing() {
        // To recover from a missing crypto/keys, fresh start.
        storeMetaGlobal(MetaGlobal(syncID: "id", storageVersion: 5, engines: [String: EngineMeta](), declined: nil))

        let afterStores = now()
        let expectation = expectationWithDescription("Waiting on value.")
        ready().upon { result in
            self.assertFreshStart(result.successValue, after: afterStores)
            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }
}
