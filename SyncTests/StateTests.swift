// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Account
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

    // Equal charCounts of JSON data is sufficiently high probability of equality
    func charCount(_ s: String) -> [Character: Int] {
        var counts = [Character: Int]()
        s.forEach { c in
            if let x = counts[c] { counts[c] = x + 1 } else { counts[c] = 1 }
        }
        return counts
    }

    var lhsCounts = [Character: Int]()
    tuple.lhs.localCommands.forEach {
        lhsCounts.merge(charCount($0.description)) { (a, b) in a + b }
    }

    var rhsCounts = [Character: Int]()
    tuple.rhs.localCommands.forEach {
        rhsCounts.merge(charCount($0.description)) { (a, b) in a + b }
    }

    XCTAssertTrue(lhsCounts == rhsCounts)
    XCTAssertEqual(tuple.lhs.engineConfiguration, tuple.rhs.engineConfiguration)
}

func roundtrip(s: Scratchpad) -> (Scratchpad, rhs: Scratchpad) {
    let prefs = MockProfilePrefs()
    let _ = s.pickle(prefs)
    return (s, rhs: Scratchpad.restoreFromPrefs(prefs, syncKeyBundle: s.syncKeyBundle)!)
}

class StateTests: XCTestCase {
    func getGlobal() -> Fetched<MetaGlobal> {
        let g = MetaGlobal(syncID: "abcdefghiklm", storageVersion: 5, engines: ["bookmarks": EngineMeta(version: 1, syncID: "dddddddddddd")], declined: ["tabs"])
        return Fetched(value: g, timestamp: Date.now())
    }

    func getEngineConfiguration() -> EngineConfiguration {
        return EngineConfiguration(enabled: ["bookmarks", "clients"], declined: ["tabs"])
    }

    func baseScratchpad() -> Scratchpad {
        let syncKeyBundle = KeyBundle.fromKSync(Bytes.generateRandomBytes(64))
        let keys = Fetched(value: Keys(defaultBundle: syncKeyBundle), timestamp: 1001)
        let b = Scratchpad(b: syncKeyBundle, persistingTo: MockProfilePrefs()).evolve()
        let _ = b.setKeys(keys)
        b.localCommands = Set([
            .enableEngine(engine: "tabs"),
            .disableEngine(engine: "passwords"),
            .resetAllEngines(except: Set<String>(["bookmarks", "clients"])),
            .resetEngine(engine: "clients")])
        return b.build()
    }

    func testPickling() {
        compareScratchpads(tuple: roundtrip(s: baseScratchpad()))
        compareScratchpads(tuple: roundtrip(s: baseScratchpad().evolve().setGlobal(getGlobal()).build()))
        compareScratchpads(tuple: roundtrip(s: baseScratchpad().evolve().clearLocalCommands().build()))
        compareScratchpads(tuple: roundtrip(s: baseScratchpad().evolve().setEngineConfiguration(getEngineConfiguration()).build()))
    }
}
