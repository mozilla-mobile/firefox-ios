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
    var syncPrefs: Prefs!
    var authState: SyncAuthState!
    var stateMachine: SyncStateMachine!

    override func setUp() {
        kB = NSData.randomOfLength(32)!
        server = MockSyncServer(username: "1234567")
        server.start()
        serverRoot = server.baseURL
        syncPrefs = MockProfilePrefs()
        authState = MockSyncAuthState(serverRoot: serverRoot, kB: kB)
        stateMachine = SyncStateMachine(prefs: syncPrefs)
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

    func storeCryptoKeys(keys: Keys) {
        let keyBundle = KeyBundle.fromKB(kB)
        let record = Record(id: "keys", payload: keys.asPayload())
        let envelope = EnvelopeJSON(keyBundle.serializer({ $0 })(record)!)
        server.storeRecords([envelope], inCollection: "crypto")
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
        if let clients = ready.scratchpad.global?.value.engines["clients"] {
            XCTAssertTrue(clients.syncID.characters.count == 12)
        }
    }

    func testMetaGlobalVersionTooNew() {
        // There's no recovery from a meta/global version "in the future": just bail out with an UpgradeRequiredError.
        storeMetaGlobal(MetaGlobal(syncID: "id", storageVersion: 6, engines: [String: EngineMeta](), declined: []))

        let expectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobal", "clientUpgradeRequired"])
            XCTAssertNotNil(result.failureValue as? ClientUpgradeRequiredError)
            XCTAssertNil(result.successValue)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testMetaGlobalVersionTooOld() {
        // To recover from a meta/global version "in the past", fresh start.
        storeMetaGlobal(MetaGlobal(syncID: "id", storageVersion: 4, engines: [String: EngineMeta](), declined: []))

        let afterStores = now()
        let expectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobal", "remoteUpgradeRequired",
                "freshStartRequired", "serverConfigurationRequired", "initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobal", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
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
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "missingMetaGlobal",
                "freshStartRequired", "serverConfigurationRequired", "initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobal", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
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
        storeMetaGlobal(MetaGlobal(syncID: "id", storageVersion: 5, engines: [String: EngineMeta](), declined: []))

        let afterStores = now()
        let expectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobal", "hasMetaGlobal", "needsFreshCryptoKeys", "missingCryptoKeys", "freshStartRequired", "serverConfigurationRequired", "initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobal", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
            self.assertFreshStart(result.successValue, after: afterStores)
            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testMetaGlobalAndCryptoKeysFresh() {
        // When encountering a valid meta/global and crypto/keys, advance smoothly.
        let metaGlobal = MetaGlobal(syncID: "id", storageVersion: 5, engines: [String: EngineMeta](), declined: [])
        let cryptoKeys = Keys.random()
        storeMetaGlobal(metaGlobal)
        storeCryptoKeys(cryptoKeys)

        var metaGlobalTimestamp: Timestamp!
        var cryptoKeysTimestamp: Timestamp!

        let expectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobal", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
            XCTAssertNotNil(result.successValue)
            guard let ready = result.successValue else {
                return
            }
            metaGlobalTimestamp = ready.scratchpad.global!.timestamp
            cryptoKeysTimestamp = ready.scratchpad.keys!.timestamp

            // And we should have downloaded meta/global and crypto/keys.
            XCTAssertEqual(ready.scratchpad.global?.value, metaGlobal)
            XCTAssertEqual(ready.scratchpad.keys?.value, cryptoKeys)

            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        // Now, run through the state machine again.  Nothing's changed remotely, so we should advance quickly.
        let secondExpectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "hasMetaGlobal", "hasFreshCryptoKeys", "ready"])
            XCTAssertNotNil(result.successValue)
            guard let ready = result.successValue else {
                return
            }
            // And we should have not downloaded a fresh meta/global or crypto/keys.
            XCTAssertEqual(ready.scratchpad.global?.timestamp, metaGlobalTimestamp)
            XCTAssertEqual(ready.scratchpad.keys?.timestamp, cryptoKeysTimestamp)

            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            secondExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }
}
