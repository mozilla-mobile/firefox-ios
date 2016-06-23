/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Sync

import XCTest

func compareScratchpads(tuple: (lhs: Scratchpad, rhs: Scratchpad)) {
    // This one is set in the constructor!
    XCTAssertEqual(tuple.lhs.syncKeyBundle, tuple.rhs.syncKeyBundle)

    XCTAssertEqual(tuple.lhs.clientName, tuple.rhs.clientName)
    XCTAssertEqual(tuple.lhs.clientGUID, tuple.rhs.clientGUID)
    if let lkeys = tuple.lhs.keys {
        if let rkeys = tuple.rhs.keys {
            XCTAssertEqual(lkeys.timestamp, rkeys.timestamp)
            XCTAssertEqual(lkeys.value, rkeys.value)
        } else {
            XCTAssertTrue(tuple.rhs.keys != nil)
        }
    } else {
        XCTAssertTrue(tuple.rhs.keys == nil)
    }

    XCTAssertTrue(tuple.lhs.global == tuple.rhs.global)
    XCTAssertEqual(tuple.lhs.localCommands, tuple.rhs.localCommands)
    XCTAssertEqual(tuple.lhs.engineConfiguration, tuple.rhs.engineConfiguration)
}

func roundtrip(s: Scratchpad) -> (Scratchpad, rhs: Scratchpad) {
    let prefs = MockProfilePrefs()
    s.pickle(prefs)
    return (s, rhs: Scratchpad.restoreFromPrefs(prefs, syncKeyBundle: s.syncKeyBundle)!)
}

class StateTests: XCTestCase {
    func getGlobal() -> Fetched<MetaGlobal> {
        let g = MetaGlobal(syncID: "abcdefghiklm", storageVersion: 5, engines: ["bookmarks": EngineMeta(version: 1, syncID: "dddddddddddd")], declined: ["tabs"])
        return Fetched(value: g, timestamp: NSDate.now())
    }

    func getEngineConfiguration() -> EngineConfiguration {
        return EngineConfiguration(enabled: ["bookmarks", "clients"], declined: ["tabs"])
    }

    func baseScratchpad() -> Scratchpad {
        let syncKeyBundle = KeyBundle.fromKB(Bytes.generateRandomBytes(32))
        let keys = Fetched(value: Keys(defaultBundle: syncKeyBundle), timestamp: 1001)
        let b = Scratchpad(b: syncKeyBundle, persistingTo: MockProfilePrefs()).evolve()
        b.setKeys(keys)
        b.localCommands = Set([
            .EnableEngine(engine: "tabs"),
            .DisableEngine(engine: "passwords"),
            .ResetAllEngines(except: Set(["bookmarks", "clients"])),
            .ResetEngine(engine: "clients")])
        return b.build()
    }

    func testPickling() {
        compareScratchpads(roundtrip(baseScratchpad()))
        compareScratchpads(roundtrip(baseScratchpad().evolve().setGlobal(getGlobal()).build()))
        compareScratchpads(roundtrip(baseScratchpad().evolve().clearLocalCommands().build()))
        compareScratchpads(roundtrip(baseScratchpad().evolve().setEngineConfiguration(getEngineConfiguration()).build()))
    }
}
