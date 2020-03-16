// Tests/SwiftProtobufPluginLibraryTests/Test_SwiftLanguage.swift - Test language utilities
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Tests for tools to ensure identifiers are valid in Swift or protobuf{2,3}.
///
// -----------------------------------------------------------------------------

import XCTest
import SwiftProtobufPluginLibrary

class Test_SwiftLanguage: XCTestCase {
    func testIsValidSwiftIdentifier() {
        for identifier in ["H9000", "\u{1f436}\u{1f431}"] {
            XCTAssert(isValidSwiftIdentifier(identifier), "Should be valid: \(identifier)")
        }
    }

    func testIsNotValidSwiftIdentifier() {
        for identifier in ["_", "$0", "$f00", "12Hour", "This is bad"] {
            XCTAssert(!isValidSwiftIdentifier(identifier), "Should not be valid: \(identifier)")
        }
    }
}
