/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class TestProfilePrefs: ProfileTest {
    func withTestPrefs(callback: (prefs: ProfilePrefs) -> Void) {
        withTestProfile { profile in
            callback(prefs: NSUserDefaultsProfilePrefs(profile: profile))
        }
    }

    func testStringForKey() {
        withTestPrefs { prefs in
            prefs.setObject("value", forKey: "key")
            XCTAssertEqual(prefs.stringForKey("key")!, "value")
            // Non-String values return nil.
            prefs.setObject(1, forKey: "key")
            XCTAssertNil(prefs.stringForKey("key"))
        }
    }

    func testBoolForKey() {
        withTestPrefs { prefs in
            prefs.setObject(true, forKey: "key")
            XCTAssertEqual(prefs.boolForKey("key")!, true)
            prefs.setObject(false, forKey: "key")
            XCTAssertEqual(prefs.boolForKey("key")!, false)
            // We would like non-Bool values to return nil, but I can't figure out how to differentiate.
            // Instead, this documents the undesired behaviour.
            prefs.setObject(1, forKey: "key")
            XCTAssertEqual(prefs.boolForKey("key")!, true)
            prefs.setObject("1", forKey: "key")
            XCTAssertEqual(prefs.boolForKey("key")!, true)
            prefs.setObject("x", forKey: "key")
            XCTAssertEqual(prefs.boolForKey("key")!, false)
        }
    }

    func testStringArrayForKey() {
        withTestPrefs { prefs in
            prefs.setObject(["value1", "value2"], forKey: "key")
            XCTAssertEqual(prefs.stringArrayForKey("key")!, ["value1", "value2"])
            // Non-[String] values return nil.
            prefs.setObject(1, forKey: "key")
            XCTAssertNil(prefs.stringArrayForKey("key"))
            // [Non-String] values return nil.
            prefs.setObject([1, 2], forKey: "key")
            XCTAssertNil(prefs.stringArrayForKey("key"))
        }
    }
}
