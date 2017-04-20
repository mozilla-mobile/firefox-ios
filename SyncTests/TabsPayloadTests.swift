/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
@testable import Sync

class TabsPayloadTests: XCTestCase {

    func testFromInvalidJSON() {
        let tabsPayload1 = TabsPayload("")
        XCTAssertFalse(tabsPayload1.isValid())

        let tabsPayload2 = TabsPayload("null")
        XCTAssertFalse(tabsPayload2.isValid())

        let tabsPayload3 = TabsPayload("{}")
        XCTAssertFalse(tabsPayload3.isValid())

        let tabsPayload4 = TabsPayload("{\"id\": \"abc\"}")
        XCTAssertFalse(tabsPayload4.isValid())
    }

    func testFromJSON() {
        let tabsPayload = TabsPayload("{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": []}")
        XCTAssertTrue(tabsPayload.isValid())
    }

    func testFromJSONWithInvalidRecord() {
        let tabsPayload = TabsPayload("{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": null}")
        XCTAssertFalse(tabsPayload.isValid())

        let tabsPayload2 = TabsPayload("{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": 1}")
        XCTAssertFalse(tabsPayload2.isValid())

        let tabsPayload3 = TabsPayload("{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": {}}")
        XCTAssertFalse(tabsPayload3.isValid())

        let tabsPayload4 = TabsPayload("{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": true}")
        XCTAssertFalse(tabsPayload4.isValid())
    }

    func testTabWithBadTabs() {
        let tabsPayload1 = TabsPayload("{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": [{}]}")
        XCTAssertTrue(tabsPayload1.isValid())
        let tabs1 = tabsPayload1.tabs
        XCTAssert(tabs1.count == 0)

        let tabsPayload2 = TabsPayload("{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": [null, {}, [], 123, false, true, \"\"]}")
        XCTAssertTrue(tabsPayload2.isValid())
        let tabs2 = tabsPayload2.tabs
        XCTAssert(tabs2.count == 0)
    }

    func testTabWithCorrectTabLastUsed() {
        let payloads = [
            "{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": [{\"title\": \"Some Title\", \"urlHistory\": [\"http://www.example.com\"], \"icon\": null, \"lastUsed\": 1492649651}]}",
            "{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": [{\"title\": \"Some Title\", \"urlHistory\": [\"http://www.example.com\"], \"icon\": null, \"lastUsed\": \"1492316843992\"}]}"
        ]

        for payload in payloads {
            let tabsPayload = TabsPayload(payload)
            XCTAssertTrue(tabsPayload.isValid())
            let tabs = tabsPayload.tabs
            XCTAssert(tabs.count == 1)
        }
    }

    func testTabWithBadTabLastUsed() {
        let payloads = [
            "{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": [{\"title\": \"Some Title\", \"urlHistory\": [\"http://www.example.com\"], \"icon\": null, \"lastUsed\": null}]}",
            "{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": [{\"title\": \"Some Title\", \"urlHistory\": [\"http://www.example.com\"], \"icon\": null, \"lastUsed\": \"\"}]}",
            "{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": [{\"title\": \"Some Title\", \"urlHistory\": [\"http://www.example.com\"], \"icon\": null, \"lastUsed\": \"cheese\"}]}",
            "{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": [{\"title\": \"Some Title\", \"urlHistory\": [\"http://www.example.com\"], \"icon\": null, \"lastUsed\": true}]}",
            "{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": [{\"title\": \"Some Title\", \"urlHistory\": [\"http://www.example.com\"], \"icon\": null, \"lastUsed\": false}]}",
            "{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": [{\"title\": \"Some Title\", \"urlHistory\": [\"http://www.example.com\"], \"icon\": null, \"lastUsed\": 9223372036854775807}]}",
            "{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": [{\"title\": \"Some Title\", \"urlHistory\": [\"http://www.example.com\"], \"icon\": null, \"lastUsed\": 123456789012345678901234567890}]}",
            "{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": [{\"title\": \"Some Title\", \"urlHistory\": [\"http://www.example.com\"], \"icon\": null, \"lastUsed\": -1}]}",
            "{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": [{\"title\": \"Some Title\", \"urlHistory\": [\"http://www.example.com\"], \"icon\": null, \"lastUsed\": \"123456789012345678901234567890\"}]}",
            "{\"id\": \"abc\", \"deleted\": false, \"clientName\": \"Foo\", \"tabs\": [{\"title\": \"Some Title\", \"urlHistory\": [\"http://www.example.com\"], \"icon\": null, \"lastUsed\": \"-1\"}]}"
        ]

        for payload in payloads {
            let tabsPayload = TabsPayload(payload)
            XCTAssertTrue(tabsPayload.isValid(), "Should not be valid: \(payload)")
            let tabs = tabsPayload.tabs
            XCTAssert(tabs.count == 0, "Should not have valid tabs: \(payload)")
        }
    }
}
