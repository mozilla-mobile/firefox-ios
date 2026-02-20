// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import CopyWithUpdates

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
// If you want to run these tests without skipping, open the CopyWithUpdates package folder separately in Xcode.
#if canImport(CopyWithUpdatesMacros)
import CopyWithUpdatesMacros

nonisolated(unsafe) let testMacros: [String: Macro.Type] = [
    "CopyWithUpdates": CopyWithUpdatesMacro.self,
]
#endif

final class CopyWithUpdatesTests: XCTestCase {
    func testMacro_withOptionalProperty() throws {
        #if canImport(CopyWithUpdatesMacros)
        assertMacroExpansion(
            """
            @CopyWithUpdates
            struct TestType {
                let prop1: String?
            }
            """,
            expandedSource: """
            struct TestType {
                let prop1: String?

                public func copyWithUpdates(prop1: String?? = .some(nil)) -> Self {
                    return Self (
                    prop1: prop1.map {
                            $0 ?? self.prop1
                        } ?? nil
                    )
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacro_forMultiplePropertyTypes() throws {
        // swiftlint:disable line_length
        #if canImport(CopyWithUpdatesMacros)
        assertMacroExpansion(
            """
            @CopyWithUpdates
            struct Report {
                let venue: String
                let sponsor: String?
                let drinks: [String]
                let complexStructure: [Date: [(String, Int)]]
                let characters: [String]?
                let budget: Double
            }
            """,
            expandedSource: """
            struct Report {
                let venue: String
                let sponsor: String?
                let drinks: [String]
                let complexStructure: [Date: [(String, Int)]]
                let characters: [String]?
                let budget: Double

                public func copyWithUpdates(venue: String? = nil, sponsor: String?? = .some(nil), drinks: [String]? = nil, complexStructure: [Date: [(String, Int)]]? = nil, characters: [String]?? = .some(nil), budget: Double? = nil) -> Self {
                    return Self (
                        venue: venue ?? self.venue,
                        sponsor: sponsor == .none ? nil : self.sponsor,
                        drinks: drinks ?? self.drinks,
                        complexStructure: complexStructure ?? self.complexStructure,
                        characters: characters == .none ? nil : self.characters,
                        budget: budget ?? self.budget
                    )
                }
            }
            """,
            macros: testMacros
        )
        // swiftlint:enable line_length
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacro_withStaticProperty() throws {
        #if canImport(CopyWithUpdatesMacros)
        assertMacroExpansion(
            """
            @CopyWithUpdates
            struct SomeState {
                var prop1: UUID
                var prop2: String

                static let reducer: Reducer<Self> = { state, action, actionWindowUUID in
                    return state
                }
            }
            """,
            expandedSource: """
            struct SomeState {
                var prop1: UUID
                var prop2: String

                static let reducer: Reducer<Self> = { state, action, actionWindowUUID in
                    return state
                }

                public func copyWithUpdates(prop1: UUID? = nil, prop2: String? = nil) -> Self {
                    return Self (
                        prop1: prop1 ?? self.prop1,
                        prop2: prop2 ?? self.prop2
                    )
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testIntegration_withOptionalSet() {
        @CopyWithUpdates
        struct TestType {
            let property1: String?
            let property2: Int
        }

        let initialString = "Initial String"
        let initialInt = 3

        // Initialize the type to be copied with a non-nil string for property1
        let testNoOptional = TestType(property1: initialString, property2: initialInt)

        // Change the optional property to a new non-optional value
        let test1 = testNoOptional.copyWithUpdates(property1: "Some value")
        XCTAssertEqual(test1.property1, "Some value")
        XCTAssertEqual(test1.property2, initialInt)

        // Change the non-optional property without touching other values
        let test2 = testNoOptional.copyWithUpdates(property2: 6)
        XCTAssertEqual(test2.property1, initialString)
        XCTAssertEqual(test2.property2, 6)

        // Change the non-optional value to .some(nil) -- (!) This is considered a misuse, this is a no-op (!)
        let test3 = testNoOptional.copyWithUpdates(property1: .some(nil))
        XCTAssertEqual(test3.property1, initialString, "This is a no-op outside intended use, so value should NOT change")
        XCTAssertEqual(test3.property2, initialInt)

        // Change the non-optional value to nil -- Semantically, we expect the value to be set to nil after copy
        let test4 = testNoOptional.copyWithUpdates(property1: nil)
        XCTAssertEqual(test4.property1, nil)
        XCTAssertEqual(test4.property2, initialInt)
    }

    func testIntegration_withOptionalNotSet() {
        @CopyWithUpdates
        struct TestType {
            let property1: String?
            let property2: Int
        }

        let initialString: String? = nil
        let initialInt = 3

        // Initialize the type to be copied with nil for property1
        let testWithOptional = TestType(property1: initialString, property2: initialInt)

        // Change the optional property to a new non-optional value
        let test1 = testWithOptional.copyWithUpdates(property1: "Some value")
        XCTAssertEqual(test1.property1, "Some value")
        XCTAssertEqual(test1.property2, initialInt)

        // Change the non-optional property without touching other values
        let test2 = testWithOptional.copyWithUpdates(property2: 2)
        XCTAssertEqual(test2.property1, initialString)
        XCTAssertEqual(test2.property2, 2)
    }
}
