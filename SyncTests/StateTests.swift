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

    XCTAssertEqual(lhs.collectionLastFetched, rhs.collectionLastFetched)
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
}

func roundtrip(s: Scratchpad) -> (Scratchpad, Scratchpad) {
    let prefs = MockProfilePrefs()
    s.pickle(prefs)
    return (s, Scratchpad.restoreFromPrefs(prefs, syncKeyBundle: s.syncKeyBundle)!)
}

class StateTests: XCTestCase {
    func getGlobal() -> Fetched<MetaGlobal> {
        let g = MetaGlobal(syncID: "abcdefghiklm", storageVersion: 5, engines: ["bookmarks": EngineMeta(version: 1, syncID: "dddddddddddd")], declined: ["tabs"])
        return Fetched(value: g, timestamp: NSDate.now())
    }

    func baseScratchpad() -> Scratchpad {
        let syncKeyBundle = KeyBundle.fromKB(Bytes.generateRandomBytes(32))
        let keys = Fetched(value: Keys(defaultBundle: syncKeyBundle), timestamp: 1001)
        return Scratchpad(b: syncKeyBundle, persistingTo: MockProfilePrefs()).evolve().setKeys(keys).build()
    }

    func testPickling() {
        compareScratchpads(roundtrip(baseScratchpad()))
        compareScratchpads(roundtrip(baseScratchpad().evolve().setGlobal(getGlobal()).build()))
    }
}
