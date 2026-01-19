// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import CopyWithChanges

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
// If you want to run these tests without skipping, open the CopyWithChanges package folder separately in Xcode.
#if canImport(CopyWithChangesMacros)
import CopyWithChangesMacros

let testMacros: [String: Macro.Type] = [
    "CopyWithChanges": CopyWithChangesMacro.self,
]
#endif

final class CopyWithChangesTests: XCTestCase {
    func testMacro_forMultiplePropertyTypes() throws {
        // swiftlint:disable line_length
        #if canImport(CopyWithChangesMacros)
        assertMacroExpansion(
            """
            @CopyWithChanges
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

                public func copyWith(venue: String? = nil, sponsor: String?? = .some(nil), drinks: [String]? = nil, complexStructure: [Date: [(String, Int)]]? = nil, characters: [String]?? = .some(nil), budget: Double? = nil) -> Self {
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
        #if canImport(CopyWithChangesMacros)
        assertMacroExpansion(
            """
            @CopyWithChanges
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

                public func copyWith(prop1: UUID? = nil, prop2: String? = nil) -> Self {
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
}
