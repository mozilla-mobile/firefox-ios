/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import MozillaRustComponents
@testable import MozillaAppServices
import XCTest

class NimbusFeatureVariablesTests: XCTestCase {
    func testScalarTypeCoercion() throws {
        let variables = JSONVariables(with: [
            "intVariable": 3,
            "stringVariable": "string",
            "booleanVariable": true,
            "enumVariable": "one",
        ])

        XCTAssertEqual(variables.getInt("intVariable"), 3)
        XCTAssertEqual(variables.getString("stringVariable"), "string")
        XCTAssertEqual(variables.getBool("booleanVariable"), true)
        XCTAssertEqual(variables.getEnum("enumVariable"), EnumTester.one)
    }

    func testScalarValuesOfWrongTypeAreNil() throws {
        let variables = JSONVariables(with: [
            "intVariable": 3,
            "stringVariable": "string",
            "booleanVariable": true,
        ])
        XCTAssertNil(variables.getString("intVariable"))
        XCTAssertNil(variables.getBool("intVariable"))

        XCTAssertNil(variables.getInt("stringVariable"))
        XCTAssertNil(variables.getBool("stringVariable"))

        XCTAssertEqual(variables.getBool("booleanVariable"), true)
        XCTAssertNil(variables.getInt("booleanVariable"))
        XCTAssertNil(variables.getString("booleanVariable"))

        let value: EnumTester? = variables.getEnum("stringVariable")
        XCTAssertNil(value)
    }

    func testNestedObjectsMakeVariablesObjects() throws {
        let outer = JSONVariables(with: [
            "inner": [
                "stringVariable": "string",
                "intVariable": 3,
                "booleanVariable": true,
            ] as [String: Any],
            "really-a-string": "a string",
        ])

        XCTAssertNil(outer.getVariables("not-there"))
        let inner = outer.getVariables("inner")

        XCTAssertNotNil(inner)
        XCTAssertEqual(inner!.getInt("intVariable"), 3)
        XCTAssertEqual(inner!.getString("stringVariable"), "string")
        XCTAssertEqual(inner!.getBool("booleanVariable"), true)

        XCTAssertNil(outer.getVariables("really-a-string"))
    }

    func testListsOfTypes() throws {
        let variables: Variables = JSONVariables(with: [
            "ints": [1, 2, 3, "not a int"] as [Any],
            "strings": ["a", "b", "c", 4] as [Any],
            "booleans": [true, false, "not a bool"] as [Any],
            "enums": ["one", "two", "three"],
        ])

        XCTAssertEqual(variables.getStringList("strings"), ["a", "b", "c"])
        XCTAssertEqual(variables.getIntList("ints"), [1, 2, 3])
        XCTAssertEqual(variables.getBoolList("booleans"), [true, false])
        XCTAssertEqual(variables.getEnumList("enums"), [EnumTester.one, EnumTester.two])
    }

    func testMapsOfTypes() throws {
        let variables: Variables = JSONVariables(with: [
            "ints": ["one": 1, "two": 2, "three": "string!"] as [String: Any],
            "strings": ["a": "A", "b": "B", "c": 4] as [String: Any],
            "booleans": ["a": true, "b": false, "c": "not a bool"] as [String: Any],
            "enums": ["one": "one", "two": "two", "three": "three"],
        ])

        XCTAssertEqual(variables.getStringMap("strings"), ["a": "A", "b": "B"])
        XCTAssertEqual(variables.getIntMap("ints"), ["one": 1, "two": 2])
        XCTAssertEqual(variables.getBoolMap("booleans"), ["a": true, "b": false])
        XCTAssertEqual(variables.getEnumMap("enums"), ["one": EnumTester.one, "two": EnumTester.two])
    }

    func testCompactMapWithEnums() throws {
        let stringMap = ["one": "one", "two": "two", "three": "three"]

        XCTAssertEqual(stringMap.compactMapKeysAsEnums(), [EnumTester.one: "one", EnumTester.two: "two"])
        XCTAssertEqual(stringMap.compactMapValuesAsEnums(), ["one": EnumTester.one, "two": EnumTester.two])
    }

    func testLargerExample() throws {
        let variables: Variables = JSONVariables(with: [
            "items": [
                "settings": [
                    "label": "Settings",
                    "deepLink": "//settings",
                ],
                "bookmarks": [
                    "label": "Bookmarks",
                    "deepLink": "//bookmark-list",
                ],
                "history": [
                    "label": "History",
                    "deepLink": "//history",
                ],
                "addBookmark": [
                    "label": "Bookmark this page",
                ],
            ],
            "item-order": ["settings", "history", "addBookmark", "bookmarks", "open_bad_site"],
        ])

        let menuItems: [MenuItemId: MenuItem]? = variables.getVariablesMap("items") { v in
            guard let label = v.getText("label"),
                  let deepLink = v.getString("deepLink")
            else {
                return nil
            }
            return MenuItem(deepLink: deepLink, label: label)
        }?.compactMapKeysAsEnums()

        XCTAssertNotNil(menuItems)
        XCTAssertEqual(menuItems?.count, 3)
        XCTAssertNil(menuItems?[.addBookmark])

        let ordering: [MenuItemId]? = variables.getEnumList("item-order")
        XCTAssertEqual(ordering, [.settings, .history, .addBookmark, .bookmarks])
    }
}

enum MenuItemId: String {
    case settings
    case bookmarks
    case history
    case addBookmark
}

struct MenuItem {
    let deepLink: String
    let label: String
}

enum EnumTester: String {
    case one
    case two
}
