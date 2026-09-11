// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import XCTest

class PrefsEnvironmentTrackingTests: XCTestCase {
    private let lastUsedKey = "testLastUsedEnvironment"

    func testResetIfEnvironmentChanged_doesNotReset_whenNothingRecordedYet() {
        let prefs = MockProfilePrefs()
        var resetCount = 0

        prefs.resetIfEnvironmentChanged("prod", forKey: lastUsedKey) { resetCount += 1 }

        XCTAssertEqual(resetCount, 0, "A first recording has no stored credentials to invalidate")
        XCTAssertEqual(prefs.stringForKey(lastUsedKey), "prod")
    }

    func testResetIfEnvironmentChanged_doesNotReset_whenUnchanged() {
        let prefs = MockProfilePrefs()
        prefs.setString("prod", forKey: lastUsedKey)
        var resetCount = 0

        prefs.resetIfEnvironmentChanged("prod", forKey: lastUsedKey) { resetCount += 1 }

        XCTAssertEqual(resetCount, 0)
        XCTAssertEqual(prefs.stringForKey(lastUsedKey), "prod")
    }

    func testResetIfEnvironmentChanged_resetsAndRecords_whenChanged() {
        let prefs = MockProfilePrefs()
        prefs.setString("stage", forKey: lastUsedKey)
        var resetCount = 0

        prefs.resetIfEnvironmentChanged("prod", forKey: lastUsedKey) { resetCount += 1 }

        XCTAssertEqual(resetCount, 1)
        XCTAssertEqual(prefs.stringForKey(lastUsedKey), "prod", "Should record the environment it reset for")
    }

    func testResetIfEnvironmentChanged_resetsOnlyOnce_acrossRepeatedCalls() {
        let prefs = MockProfilePrefs()
        prefs.setString("stage", forKey: lastUsedKey)
        var resetCount = 0

        for _ in 0..<3 {
            prefs.resetIfEnvironmentChanged("prod", forKey: lastUsedKey) { resetCount += 1 }
        }

        XCTAssertEqual(resetCount, 1, "Recording the new environment must stop later calls from resetting again")
    }

    func testResetIfEnvironmentChanged_isolatesKeys() {
        let prefs = MockProfilePrefs()
        prefs.setString("stage", forKey: "environmentA")
        var resetCount = 0

        prefs.resetIfEnvironmentChanged("prod", forKey: "environmentB") { resetCount += 1 }

        XCTAssertEqual(resetCount, 0, "An unrelated key must not be read as a previous environment")
        XCTAssertEqual(prefs.stringForKey("environmentA"), "stage")
        XCTAssertEqual(prefs.stringForKey("environmentB"), "prod")
    }
}
