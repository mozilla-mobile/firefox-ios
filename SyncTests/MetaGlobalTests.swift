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

    func storeMetaGlobal(metaGlobal: MetaGlobal) {
        let envelope = EnvelopeJSON(JSON([
            "id": "global",
            "collection": "meta",
            "payload": metaGlobal.asPayload().toString(),
            "modified": Double(NSDate.now())/1000]))
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
        XCTAssertGreaterThan(server.collections["meta"]?.records["global"]?.modified ?? 0, after)
        XCTAssertGreaterThan(server.collections["meta"]?.modified ?? 0, after)
        XCTAssertGreaterThan(server.collections["crypto"]?.records["keys"]?.modified ?? 0, after)
        XCTAssertGreaterThan(server.collections["crypto"]?.modified ?? 0, after)

        // And we should have downloaded meta/global and crypto/keys.
        XCTAssertNotNil(ready.scratchpad.global)
        XCTAssertNotNil(ready.scratchpad.keys)

        // We should have the default engine configuration.
        XCTAssertNotNil(ready.scratchpad.engineConfiguration)
        guard let engineConfiguration = ready.scratchpad.engineConfiguration else {
            return
        }
        XCTAssertEqual(engineConfiguration.enabled.sort(), ["addons", "bookmarks", "clients", "forms", "history", "passwords", "prefs", "tabs"])
        XCTAssertEqual(engineConfiguration.declined, [])

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
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobalVersion", "clientUpgradeRequired"])
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

        let afterStores = NSDate.now()
        let expectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobalVersion", "remoteUpgradeRequired",
                "freshStartRequired", "serverConfigurationRequired", "initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
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
        let afterStores = NSDate.now()
        let expectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "missingMetaGlobal",
                "freshStartRequired", "serverConfigurationRequired", "initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
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
        storeMetaGlobal(createMetaGlobal())

        let afterStores = NSDate.now()
        let expectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "missingCryptoKeys", "freshStartRequired", "serverConfigurationRequired", "initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
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

        let expectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
            XCTAssertNotNil(result.successValue)
            guard let ready = result.successValue else {
                return
            }

            // And we should have downloaded meta/global and crypto/keys.
            XCTAssertEqual(ready.scratchpad.global?.value, metaGlobal)
            XCTAssertEqual(ready.scratchpad.keys?.value, cryptoKeys)

            // We should have marked all local engines for reset.
            XCTAssertEqual(ready.collectionsThatNeedLocalReset(), ["bookmarks", "clients", "history", "passwords", "tabs"])
            ready.clearLocalCommands()

            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        let afterFirstSync = NSDate.now()

        // Now, run through the state machine again.  Nothing's changed remotely, so we should advance quickly.
        let secondExpectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "hasMetaGlobal", "hasFreshCryptoKeys", "ready"])
            XCTAssertNotNil(result.successValue)
            guard let ready = result.successValue else {
                return
            }
            // And we should have not downloaded a fresh meta/global or crypto/keys.
            XCTAssertLessThan(ready.scratchpad.global?.timestamp ?? Timestamp.max, afterFirstSync)
            XCTAssertLessThan(ready.scratchpad.keys?.timestamp ?? Timestamp.max, afterFirstSync)

            // We should not have marked any local engines for reset.
            XCTAssertEqual(ready.collectionsThatNeedLocalReset(), [])

            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            secondExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testUpdatedCryptoKeys() {
        // When encountering a valid meta/global and crypto/keys, advance smoothly.
        let metaGlobal = MetaGlobal(syncID: "id", storageVersion: 5, engines: [String: EngineMeta](), declined: [])
        let cryptoKeys = Keys.random()
        cryptoKeys.collectionKeys.updateValue(KeyBundle.random(), forKey: "bookmarks")
        cryptoKeys.collectionKeys.updateValue(KeyBundle.random(), forKey: "clients")
        storeMetaGlobal(metaGlobal)
        storeCryptoKeys(cryptoKeys)

        let expectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
            XCTAssertNotNil(result.successValue)
            guard let ready = result.successValue else {
                return
            }

            // And we should have downloaded meta/global and crypto/keys.
            XCTAssertEqual(ready.scratchpad.global?.value, metaGlobal)
            XCTAssertEqual(ready.scratchpad.keys?.value, cryptoKeys)

            // We should have marked all local engines for reset.
            XCTAssertEqual(ready.collectionsThatNeedLocalReset(), ["bookmarks", "clients", "history", "passwords", "tabs"])
            ready.clearLocalCommands()

            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        let afterFirstSync = NSDate.now()

        // Store a fresh crypto/keys, with the same default key, one identical collection key, and one changed collection key.
        let freshCryptoKeys = Keys.init(defaultBundle: cryptoKeys.defaultBundle)
        freshCryptoKeys.collectionKeys.updateValue(cryptoKeys.forCollection("bookmarks"), forKey: "bookmarks")
        freshCryptoKeys.collectionKeys.updateValue(KeyBundle.random(), forKey: "clients")
        storeCryptoKeys(freshCryptoKeys)

        // Now, run through the state machine again.
        let secondExpectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
            XCTAssertNotNil(result.successValue)
            guard let ready = result.successValue else {
                return
            }
            // And we should have not downloaded a fresh meta/global ...
            XCTAssertLessThan(ready.scratchpad.global?.timestamp ?? Timestamp.max, afterFirstSync)
            // ... but we should have downloaded a fresh crypto/keys.
            XCTAssertGreaterThanOrEqual(ready.scratchpad.keys?.timestamp ?? Timestamp.min, afterFirstSync)

            // We should have marked only the local engine with a changed key for reset.
            XCTAssertEqual(ready.collectionsThatNeedLocalReset(), ["clients"])

            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            secondExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        let afterSecondSync = NSDate.now()

        // Store a fresh crypto/keys, with a changed default key and one identical collection key, and one changed collection key.
        let freshCryptoKeys2 = Keys.random()
        freshCryptoKeys2.collectionKeys.updateValue(freshCryptoKeys.forCollection("bookmarks"), forKey: "bookmarks")
        freshCryptoKeys2.collectionKeys.updateValue(KeyBundle.random(), forKey: "clients")
        storeCryptoKeys(freshCryptoKeys2)

        // Now, run through the state machine again.
        let thirdExpectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
            XCTAssertNotNil(result.successValue)
            guard let ready = result.successValue else {
                return
            }
            // And we should have not downloaded a fresh meta/global ...
            XCTAssertLessThan(ready.scratchpad.global?.timestamp ?? Timestamp.max, afterSecondSync)
            // ... but we should have downloaded a fresh crypto/keys.
            XCTAssertGreaterThanOrEqual(ready.scratchpad.keys?.timestamp ?? Timestamp.min, afterSecondSync)

            // We should have marked all local engines as needing reset, except for the engine whose key remained constant.
            XCTAssertEqual(ready.collectionsThatNeedLocalReset(), ["clients", "history", "passwords", "tabs"])

            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            thirdExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        let afterThirdSync = NSDate.now()

        // Now store a random crypto/keys, with a different default key (and no bulk keys).
        let randomCryptoKeys = Keys.random()
        storeCryptoKeys(randomCryptoKeys)

        // Now, run through the state machine again.
        let fourthExpectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
            XCTAssertNotNil(result.successValue)
            guard let ready = result.successValue else {
                return
            }
            // And we should have not downloaded a fresh meta/global ...
            XCTAssertLessThan(ready.scratchpad.global?.timestamp ?? Timestamp.max, afterThirdSync)
            // ... but we should have downloaded a fresh crypto/keys.
            XCTAssertGreaterThanOrEqual(ready.scratchpad.keys?.timestamp ?? Timestamp.min, afterThirdSync)

            // We should have marked all local engines for reset.
            XCTAssertEqual(ready.collectionsThatNeedLocalReset(), ["bookmarks", "clients", "history", "passwords", "tabs"])

            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            fourthExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }

    private func createUnusualMetaGlobal() -> MetaGlobal {
        let metaGlobal = MetaGlobal(syncID: "id", storageVersion: 5,
            engines: ["bookmarks": EngineMeta(version: 1, syncID: "bookmarks"), "unknownEngine1": EngineMeta(version: 2, syncID: "engineId1")],
            declined: ["clients", "forms", "unknownEngine2"])
        return metaGlobal
    }

    func testEngineConfigurations() {
        // When encountering a valid meta/global and crypto/keys, advance smoothly.  Keep the engine configuration for re-upload.
        let metaGlobal = createUnusualMetaGlobal()
        let cryptoKeys = Keys.random()
        storeMetaGlobal(metaGlobal)
        storeCryptoKeys(cryptoKeys)

        let expectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
            XCTAssertNotNil(result.successValue)
            guard let ready = result.successValue else {
                return
            }

            // We should have saved the engine configuration.
            XCTAssertNotNil(ready.scratchpad.engineConfiguration)
            guard let engineConfiguration = ready.scratchpad.engineConfiguration else {
                return
            }
            XCTAssertEqual(engineConfiguration, metaGlobal.engineConfiguration())

            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        // Wipe meta/global.
        server.removeAllItemsFromCollection("meta", atTime: NSDate.now())

        // Now, run through the state machine again.  We should produce and upload a meta/global reflecting our engine configuration.
        let secondExpectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "missingMetaGlobal", "freshStartRequired", "serverConfigurationRequired", "initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
            XCTAssertNotNil(result.successValue)
            guard let ready = result.successValue else {
                return
            }

            // The downloaded meta/global should reflect our local engine configuration.
            XCTAssertNotNil(ready.scratchpad.global)
            guard let global = ready.scratchpad.global?.value else {
                return
            }
            XCTAssertEqual(global.engineConfiguration(), metaGlobal.engineConfiguration())

            // We should have the same cached engine configuration.
            XCTAssertNotNil(ready.scratchpad.engineConfiguration)
            guard let engineConfiguration = ready.scratchpad.engineConfiguration else {
                return
            }
            XCTAssertEqual(engineConfiguration, metaGlobal.engineConfiguration())

            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            secondExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testMetaGlobalModified() {
        // When encountering a valid meta/global and crypto/keys, advance smoothly.
        let metaGlobal = createUnusualMetaGlobal()
        let cryptoKeys = Keys.random()
        storeMetaGlobal(metaGlobal)
        storeCryptoKeys(cryptoKeys)

        let expectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
            XCTAssertNotNil(result.successValue)
            guard let ready = result.successValue else {
                return
            }

            // And we should have downloaded meta/global and crypto/keys.
            XCTAssertEqual(ready.scratchpad.global?.value, metaGlobal)
            XCTAssertEqual(ready.scratchpad.keys?.value, cryptoKeys)

            // We should have marked all local engines for reset.
            XCTAssertEqual(ready.collectionsThatNeedLocalReset(), ["bookmarks", "clients", "history", "passwords", "tabs"])
            XCTAssertEqual(ready.enginesEnabled(), [])
            XCTAssertEqual(ready.enginesDisabled(), [])

            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        let afterFirstSync = NSDate.now()

        // Store a meta/global with a new global syncID.
        let newMetaGlobal = metaGlobal.withSyncID("newID")
        storeMetaGlobal(newMetaGlobal)

        // Now, run through the state machine again.
        let secondExpectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
            XCTAssertNotNil(result.successValue)
            guard let ready = result.successValue else {
                return
            }
            // And we should have downloaded a fresh meta/global ...
            XCTAssertGreaterThanOrEqual(ready.scratchpad.global?.timestamp ?? Timestamp.min, afterFirstSync)
            // ... and we should have downloaded a fresh crypto/keys -- but its timestamp is identical to the old one!
            // Therefore, the "needsFreshCryptoKeys" stage above is our test that we re-downloaded crypto/keys.

            // We should have marked all local engines for reset.
            XCTAssertEqual(ready.collectionsThatNeedLocalReset(), ["bookmarks", "clients", "history", "passwords", "tabs"])

            // And our engine configuration should be unchanged.
            XCTAssertNotNil(ready.scratchpad.global)
            guard let global = ready.scratchpad.global?.value else {
                return
            }
            XCTAssertEqual(global.engineConfiguration(), metaGlobal.engineConfiguration())

            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            secondExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        // Now store a meta/global with a changed engine syncID, a new engine, and a new declined entry.
        var engines = newMetaGlobal.engines
        engines.updateValue(EngineMeta(version: 1, syncID: Bytes.generateGUID()), forKey: "bookmarks")
        engines.updateValue(EngineMeta(version: 1, syncID: Bytes.generateGUID()), forKey: "forms")
        engines.removeValueForKey("unknownEngine1")
        var declined = newMetaGlobal.declined.filter({ $0 != "forms" })
        declined.append("unknownEngine1")
        let secondMetaGlobal = MetaGlobal(syncID: newMetaGlobal.syncID, storageVersion: 5, engines: engines, declined: declined)
        storeMetaGlobal(secondMetaGlobal)

        // Now, run through the state machine again.
        let thirdExpectation = expectationWithDescription("Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "hasFreshCryptoKeys", "ready"])
            XCTAssertNotNil(result.successValue)
            guard let ready = result.successValue else {
                return
            }
            // And we should have downloaded a fresh meta/global ...
            XCTAssertGreaterThanOrEqual(ready.scratchpad.global?.timestamp ?? Timestamp.min, afterFirstSync)
            // ... and we should have downloaded a fresh crypto/keys -- but its timestamp is identical to the old one!
            // Therefore, the "needsFreshCryptoKeys" stage above is our test that we re-downloaded crypto/keys.

            // We should have marked the changed engine for local reset, and identified the enabled and disabled engines.
            XCTAssertEqual(ready.collectionsThatNeedLocalReset(), ["bookmarks"])
            XCTAssertEqual(ready.enginesEnabled(), ["forms"])
            XCTAssertEqual(ready.enginesDisabled(), ["unknownEngine1"])

            // And our engine configuration should reflect the new meta/global on the server.
            XCTAssertNotNil(ready.scratchpad.global)
            guard let global = ready.scratchpad.global?.value else {
                return
            }
            XCTAssertEqual(global.engineConfiguration(), secondMetaGlobal.engineConfiguration())

            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            thirdExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }
}
