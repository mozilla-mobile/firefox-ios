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
