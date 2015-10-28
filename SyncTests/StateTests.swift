/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Sync
import XCTest

func compareScratchpads(lhs: Scratchpad, rhs: Scratchpad) {
    // This one is set in the constructor!
    XCTAssertEqual(lhs.syncKeyBundle, rhs.syncKeyBundle)

    XCTAssertEqual(lhs.clientName, rhs.clientName)
    XCTAssertEqual(lhs.clientGUID, rhs.clientGUID)
    if let lkeys = lhs.keys {
        if let rkeys = rhs.keys {
            XCTAssertEqual(lkeys.timestamp, rkeys.timestamp)
            XCTAssertEqual(lkeys.value, rkeys.value)
        } else {
            XCTAssertTrue(rhs.keys != nil)
        }
    } else {
        XCTAssertTrue(rhs.keys == nil)
    }

    XCTAssertTrue(lhs.global == rhs.global)
    XCTAssertEqual(lhs.localCommands, rhs.localCommands)
    XCTAssertEqual(lhs.engineConfiguration, rhs.engineConfiguration)
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
