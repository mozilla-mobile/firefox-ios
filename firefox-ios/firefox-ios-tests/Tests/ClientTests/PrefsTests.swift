// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Foundation
import Shared

import XCTest

class PrefsTests: XCTestCase {
    var prefs: NSUserDefaultsPrefs!

    override func setUp() {
        super.setUp()
        prefs = NSUserDefaultsPrefs(prefix: "PrefsTests")
    }

    override func tearDown() {
        prefs.clearAll()
        super.tearDown()
        prefs = nil
    }

    func testClearPrefs() {
        prefs.setObject("foo", forKey: "bar")
        XCTAssertEqual(prefs.stringForKey("bar")!, "foo")

        // Ensure clearing prefs is branch-specific.
        let otherPrefs = NSUserDefaultsPrefs(prefix: "othermockaccount")
        otherPrefs.clearAll()
        XCTAssertEqual(prefs.stringForKey("bar")!, "foo")

        prefs.clearAll()
        XCTAssertNil(prefs.stringForKey("bar"))
    }

    func testStringForKey() {
        XCTAssertNil(prefs.stringForKey("key"))
        prefs.setObject("value", forKey: "key")
        XCTAssertEqual(prefs.stringForKey("key")!, "value")
        // Non-String values return nil.
        prefs.setObject(1, forKey: "key")
        XCTAssertNil(prefs.stringForKey("key"))
    }

    func testBoolForKey() {
        XCTAssertNil(prefs.boolForKey("key"))
        prefs.setObject(true, forKey: "key")
        XCTAssertEqual(prefs.boolForKey("key")!, true)
        prefs.setObject(false, forKey: "key")
        XCTAssertEqual(prefs.boolForKey("key")!, false)
        // We would like non-Bool values to return nil, but I can't figure out how to differentiate.
        // Instead, this documents the undesired behaviour.
        prefs.setObject(1, forKey: "key")
        XCTAssertEqual(prefs.boolForKey("key")!, true)
        prefs.setObject("1", forKey: "key")
        XCTAssertNil(prefs.boolForKey("key"))
        prefs.setObject("x", forKey: "key")
        XCTAssertNil(prefs.boolForKey("key"))
    }

    func testStringArrayForKey() {
        XCTAssertNil(prefs.stringArrayForKey("key"))
        prefs.setObject(["value1", "value2"], forKey: "key")
        XCTAssertEqual(prefs.stringArrayForKey("key")!, ["value1", "value2"])
        // Non-[String] values return nil.
        prefs.setObject(1, forKey: "key")
        XCTAssertNil(prefs.stringArrayForKey("key"))
        // [Non-String] values return nil.
        prefs.setObject([1, 2], forKey: "key")
        XCTAssertNil(prefs.stringArrayForKey("key"))
    }

    func testMockProfilePrefsRoundtripsTimestamps() {
        let prefs = MockProfilePrefs().branch("baz")
        let val: Timestamp = Date.now()
        prefs.setLong(val, forKey: "foobar")
        XCTAssertEqual(val, prefs.unsignedLongForKey("foobar")!)
    }

    func testMockProfilePrefsKeys() {
        guard let prefs = MockProfilePrefs().branch("baz") as? MockProfilePrefs else {
            return XCTFail("Expected MockProfilePrefs instance from branch 'baz'")
        }
        let val: Timestamp = Date.now()
        prefs.setLong(val, forKey: "foobar")
        guard let numberValue = prefs.things["baz.foobar"] as? NSNumber else {
            return XCTFail("Expected NSNumber for key 'baz.foobar'")
        }
        XCTAssertEqual(val, numberValue.uint64Value)
    }

    func testMockProfilePrefsClearAll() {
        guard let prefs1 = MockProfilePrefs().branch("bar") as? MockProfilePrefs else {
            return XCTFail("Failed to cast branch 'bar' to MockProfilePrefs")
        }

        guard let prefs2 = MockProfilePrefs().branch("baz") as? MockProfilePrefs else {
            return XCTFail("Failed to cast branch 'baz' to MockProfilePrefs")
        }

        // Ensure clearing prefs is branch-specific.
        prefs1.setInt(123, forKey: "foo")
        prefs2.clearAll()
        XCTAssertEqual(123, prefs1.intForKey("foo")!)

        prefs1.clearAll()
        XCTAssertNil(prefs1.intForKey("foo") as AnyObject?)
    }
}
