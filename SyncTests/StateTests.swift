/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest

func compareScratchpads(lhs: Scratchpad, rhs: Scratchpad) {
    // This one is set in the constructor!
    XCTAssertEqual(lhs.syncKeyBundle, rhs.syncKeyBundle)

    XCTAssertEqual(lhs.collectionLastFetched, rhs.collectionLastFetched)
    XCTAssertEqual(lhs.clientName, rhs.clientName)
    XCTAssertEqual(lhs.clientRecordLastUpload, rhs.clientRecordLastUpload)

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
        return Scratchpad(b: syncKeyBundle, persistingTo: MockProfilePrefs())
    }

    func testPickling() {

        compareScratchpads(roundtrip(baseScratchpad()))
        compareScratchpads(roundtrip(baseScratchpad().evolve().setGlobal(getGlobal()).build()))
    }
}
