// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class TabGroupIconTests: XCTestCase {
    func testEncodeDecode_withSFSymbol_preservesIcon() throws {
        let expected = TabGroupIcon.sfSymbol("house.fill")

        let data = try JSONEncoder().encode(expected)
        let result = try JSONDecoder().decode(TabGroupIcon.self, from: data)

        XCTAssertEqual(result, expected)
    }

    func testEncode_withSFSymbol_storesKindAndName() throws {
        let data = try JSONEncoder().encode(TabGroupIcon.sfSymbol("house.fill"))

        let result = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: [String: String]])

        XCTAssertEqual(result, ["sfSymbol": ["_0": "house.fill"]])
    }

    func testDecode_withUnknownKind_throwsDecodingError() {
        let data = Data(#"{"futureKind":{"_0":"house.fill"}}"#.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode(TabGroupIcon.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testEncodeDecode_withUnknownSymbolName_preservesName() throws {
        let expected = TabGroupIcon.sfSymbol("future.symbol.name")

        let data = try JSONEncoder().encode(expected)
        let result = try JSONDecoder().decode(TabGroupIcon.self, from: data)

        XCTAssertEqual(result, expected)
    }

    func testInit_withoutIcon_defaultsToTabsSymbol() {
        let subject = TabGroup(title: "Work")

        XCTAssertEqual(subject.icon, .sfSymbol("rectangle.portrait.on.rectangle.portrait.angled.fill"))
    }
}
