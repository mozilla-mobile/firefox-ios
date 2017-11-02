/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
import Foundation
import Shared
import Storage
@testable import Sync
import XCGLogger
import Deferred

import XCTest
import SwiftyJSON

private let log = Logger.syncLogger

class MockSyncAuthState: SyncAuthState {
    var enginesEnablements: [String : Bool]?

    let serverRoot: String
    let kB: Data

    var deviceID: String? {
        return "mock_device_id"
    }

    init(serverRoot: String, kB: Data) {
        self.serverRoot = serverRoot
        self.kB = kB
    }

    func invalidate() {
    }

    func token(_ now: Timestamp, canBeExpired: Bool) -> Deferred<Maybe<(token: TokenServerToken, forKey: Data)>> {
        let token = TokenServerToken(id: "id", key: "key", api_endpoint: serverRoot, uid: UInt64(0), hashedFxAUID: "",
            durationInSeconds: UInt64(5 * 60), remoteTimestamp: Timestamp(now - 1))
        return deferMaybe((token, self.kB))
    }
}

class MetaGlobalTests: XCTestCase {
    var server: MockSyncServer!
    var serverRoot: String!
    var kB: Data!
    var syncPrefs: Prefs!
    var authState: SyncAuthState!
    var stateMachine: SyncStateMachine!

    override func setUp() {
        kB = Data.randomOfLength(32)!
        server = MockSyncServer(username: "1234567")
        server.start()
        serverRoot = server.baseURL
        syncPrefs = MockProfilePrefs()
        authState = MockSyncAuthState(serverRoot: serverRoot, kB: kB)
        stateMachine = SyncStateMachine(prefs: syncPrefs)
    }

    func storeMetaGlobal(metaGlobal: MetaGlobal) {
        let envelope = EnvelopeJSON(JSON(object: [
            "id": "global",
            "collection": "meta",
            "payload": metaGlobal.asPayload().json.stringValue()!,
            "modified": Double(Date.now())/1000]))
        server.storeRecords(records: [envelope], inCollection: "meta")
    }

    func storeCryptoKeys(keys: Keys) {
        let keyBundle = KeyBundle.fromKB(kB)
        let record = Record(id: "keys", payload: keys.asPayload())
        let envelope = EnvelopeJSON(keyBundle.serializer({ $0.json })(record)!)
        server.storeRecords(records: [envelope], inCollection: "crypto")
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
        XCTAssertEqual(engineConfiguration.enabled.sorted(), ["addons", "bookmarks", "clients", "forms", "history", "passwords", "prefs", "tabs"])
        XCTAssertEqual(engineConfiguration.declined, [])

        // Basic verifications.
        XCTAssertEqual(ready.collectionKeys.defaultBundle.encKey.count, 32)
        if let clients = ready.scratchpad.global?.value.engines["clients"] {
            XCTAssertTrue(clients.syncID.characters.count == 12)
        }
    }

    func testMetaGlobalVersionTooNew() {
        // There's no recovery from a meta/global version "in the future": just bail out with an UpgradeRequiredError.
        storeMetaGlobal(metaGlobal: MetaGlobal(syncID: "id", storageVersion: 6, engines: [String: EngineMeta](), declined: []))

        let expectation = self.expectation(description: "Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "needsFreshMetaGlobal", "resolveMetaGlobalVersion", "clientUpgradeRequired"])
            XCTAssertNotNil(result.failureValue as? ClientUpgradeRequiredError)
            XCTAssertNil(result.successValue)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }
    }

    func testMetaGlobalVersionTooOld() {
        // To recover from a meta/global version "in the past", fresh start.
        storeMetaGlobal(metaGlobal: MetaGlobal(syncID: "id", storageVersion: 4, engines: [String: EngineMeta](), declined: []))

        let afterStores = Date.now()
        let expectation = self.expectation(description: "Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "needsFreshMetaGlobal", "resolveMetaGlobalVersion", "remoteUpgradeRequired",
                "freshStartRequired", "serverConfigurationRequired", "initialWithLiveToken", "initialWithLiveTokenAndInfo", "needsFreshMetaGlobal", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
            self.assertFreshStart(ready: result.successValue, after: afterStores)
            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }
    }

    func testMetaGlobalMissing() {
        // To recover from a missing meta/global, fresh start.
        let afterStores = Date.now()
        let expectation = self.expectation(description: "Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "needsFreshMetaGlobal", "missingMetaGlobal",
                "freshStartRequired", "serverConfigurationRequired", "initialWithLiveToken", "initialWithLiveTokenAndInfo", "needsFreshMetaGlobal", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
            self.assertFreshStart(ready: result.successValue, after: afterStores)
            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }
    }

    func testCryptoKeysMissing() {
        // To recover from a missing crypto/keys, fresh start.
        storeMetaGlobal(metaGlobal: createMetaGlobal(enginesEnablements: nil))

        let afterStores = Date.now()
        let expectation = self.expectation(description: "Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "needsFreshMetaGlobal", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "missingCryptoKeys", "freshStartRequired", "serverConfigurationRequired", "initialWithLiveToken", "initialWithLiveTokenAndInfo", "needsFreshMetaGlobal", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
            self.assertFreshStart(ready: result.successValue, after: afterStores)
            XCTAssertTrue(result.isSuccess)
            XCTAssertNil(result.failureValue)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }
    }

    func testMetaGlobalAndCryptoKeysFresh() {
        // When encountering a valid meta/global and crypto/keys, advance smoothly.
        let metaGlobal = MetaGlobal(syncID: "id", storageVersion: 5, engines: [String: EngineMeta](), declined: [])
        let cryptoKeys = Keys.random()
        storeMetaGlobal(metaGlobal: metaGlobal)
        storeCryptoKeys(keys: cryptoKeys)

        let expectation = self.expectation(description: "Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "needsFreshMetaGlobal", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
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

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }

        let afterFirstSync = Date.now()

        // Now, run through the state machine again.  Nothing's changed remotely, so we should advance quickly.
        let secondExpectation = self.expectation(description: "Waiting on value.")
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

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }
    }

    func testFailingOptimisticStateMachine() {
        // We test only the optimistic state machine, knowing it will need to go through 
        // needsFreshMetaGlobal, and fail.
        let metaGlobal = MetaGlobal(syncID: "id", storageVersion: 5, engines: [String: EngineMeta](), declined: [])
        let cryptoKeys = Keys.random()
        storeMetaGlobal(metaGlobal: metaGlobal)
        storeCryptoKeys(keys: cryptoKeys)

        stateMachine = SyncStateMachine(prefs: syncPrefs, allowingStates: SyncStateMachine.OptimisticStates)

        let expectation = self.expectation(description: "Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "needsFreshMetaGlobal"])
            XCTAssertNotNil(result.failureValue)
            if let failure = result.failureValue as? DisallowedStateError {
                XCTAssertEqual(failure.state, SyncStateLabel.NeedsFreshMetaGlobal)
            } else {
                XCTFail("SyncStatus failed, but with a different error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }
    }

    func testHappyOptimisticStateMachine() {
        // We should be able to quickly progress through a constrained (a.k.a. optimistic) state machine
        let metaGlobal = MetaGlobal(syncID: "id", storageVersion: 5, engines: [String: EngineMeta](), declined: [])
        let cryptoKeys = Keys.random()
        storeMetaGlobal(metaGlobal: metaGlobal)
        storeCryptoKeys(keys: cryptoKeys)

        let expectation = self.expectation(description: "Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "needsFreshMetaGlobal", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
            XCTAssertNotNil(result.successValue)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }

        // Now, run through the state machine again.  Nothing's changed remotely, so we should advance quickly.
        // We should be able to use this 'optimistic' path in an extension.
        stateMachine = SyncStateMachine(prefs: syncPrefs, allowingStates: SyncStateMachine.OptimisticStates)

        let secondExpectation = self.expectation(description: "Waiting on value.")

        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "hasMetaGlobal", "hasFreshCryptoKeys", "ready"])
            XCTAssertNotNil(result.successValue)
            secondExpectation.fulfill()
        }

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }
    }

    func testUpdatedCryptoKeys() {
        // When encountering a valid meta/global and crypto/keys, advance smoothly.
        let metaGlobal = MetaGlobal(syncID: "id", storageVersion: 5, engines: [String: EngineMeta](), declined: [])
        let cryptoKeys = Keys.random()
        cryptoKeys.collectionKeys.updateValue(KeyBundle.random(), forKey: "bookmarks")
        cryptoKeys.collectionKeys.updateValue(KeyBundle.random(), forKey: "clients")
        storeMetaGlobal(metaGlobal: metaGlobal)
        storeCryptoKeys(keys: cryptoKeys)

        let expectation = self.expectation(description: "Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "needsFreshMetaGlobal", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
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

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }

        let afterFirstSync = Date.now()

        // Store a fresh crypto/keys, with the same default key, one identical collection key, and one changed collection key.
        let freshCryptoKeys = Keys(defaultBundle: cryptoKeys.defaultBundle)
        freshCryptoKeys.collectionKeys.updateValue(cryptoKeys.forCollection("bookmarks"), forKey: "bookmarks")
        freshCryptoKeys.collectionKeys.updateValue(KeyBundle.random(), forKey: "clients")
        storeCryptoKeys(keys: freshCryptoKeys)

        // Now, run through the state machine again.
        let secondExpectation = self.expectation(description: "Waiting on value.")
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

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }

        let afterSecondSync = Date.now()

        // Store a fresh crypto/keys, with a changed default key and one identical collection key, and one changed collection key.
        let freshCryptoKeys2 = Keys.random()
        freshCryptoKeys2.collectionKeys.updateValue(freshCryptoKeys.forCollection("bookmarks"), forKey: "bookmarks")
        freshCryptoKeys2.collectionKeys.updateValue(KeyBundle.random(), forKey: "clients")
        storeCryptoKeys(keys: freshCryptoKeys2)

        // Now, run through the state machine again.
        let thirdExpectation = self.expectation(description: "Waiting on value.")
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

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }

        let afterThirdSync = Date.now()

        // Now store a random crypto/keys, with a different default key (and no bulk keys).
        let randomCryptoKeys = Keys.random()
        storeCryptoKeys(keys: randomCryptoKeys)

        // Now, run through the state machine again.
        let fourthExpectation = self.expectation(description: "Waiting on value.")
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

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
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
        storeMetaGlobal(metaGlobal: metaGlobal)
        storeCryptoKeys(keys: cryptoKeys)

        let expectation = self.expectation(description: "Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "needsFreshMetaGlobal", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
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

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }

        // Wipe meta/global.
        server.removeAllItemsFromCollection(collection: "meta", atTime: Date.now())

        // Now, run through the state machine again.  We should produce and upload a meta/global reflecting our engine configuration.
        let secondExpectation = self.expectation(description: "Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "needsFreshMetaGlobal", "missingMetaGlobal", "freshStartRequired", "serverConfigurationRequired", "initialWithLiveToken", "initialWithLiveTokenAndInfo", "needsFreshMetaGlobal", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
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

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }
    }

    func testMetaGlobalModified() {
        // When encountering a valid meta/global and crypto/keys, advance smoothly.
        let metaGlobal = createUnusualMetaGlobal()
        let cryptoKeys = Keys.random()
        storeMetaGlobal(metaGlobal: metaGlobal)
        storeCryptoKeys(keys: cryptoKeys)

        let expectation = self.expectation(description: "Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "needsFreshMetaGlobal", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
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

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }

        let afterFirstSync = Date.now()

        // Store a meta/global with a new global syncID.
        let newMetaGlobal = metaGlobal.withSyncID("newID")
        storeMetaGlobal(metaGlobal: newMetaGlobal)

        // Now, run through the state machine again.
        let secondExpectation = self.expectation(description: "Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "needsFreshMetaGlobal", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "needsFreshCryptoKeys", "hasFreshCryptoKeys", "ready"])
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

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }

        // Now store a meta/global with a changed engine syncID, a new engine, and a new declined entry.
        var engines = newMetaGlobal.engines
        engines.updateValue(EngineMeta(version: 1, syncID: Bytes.generateGUID()), forKey: "bookmarks")
        engines.updateValue(EngineMeta(version: 1, syncID: Bytes.generateGUID()), forKey: "forms")
        engines.removeValue(forKey: "unknownEngine1")
        var declined = newMetaGlobal.declined.filter({ $0 != "forms" })
        declined.append("unknownEngine1")
        let secondMetaGlobal = MetaGlobal(syncID: newMetaGlobal.syncID, storageVersion: 5, engines: engines, declined: declined)
        storeMetaGlobal(metaGlobal: secondMetaGlobal)
        syncPrefs.removeObjectForKey("scratchpad.localCommands")

        // Now, run through the state machine again.
        let thirdExpectation = self.expectation(description: "Waiting on value.")
        stateMachine.toReady(authState).upon { result in
            XCTAssertEqual(self.stateMachine.stateLabelSequence.map { $0.rawValue }, ["initialWithLiveToken", "initialWithLiveTokenAndInfo", "needsFreshMetaGlobal", "resolveMetaGlobalVersion", "resolveMetaGlobalContent", "hasMetaGlobal", "hasFreshCryptoKeys", "ready"])
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

        waitForExpectations(timeout: 2000) { (error) in
            XCTAssertNil(error, "Error: \(error ??? "nil")")
        }
    }
}
