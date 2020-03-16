// Tests/SwiftProtobufTests/Test_Reserved.swift - Verify handling of reserved words
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Proto files may have fields, enum cases, or messages whose names happen
/// to be reserved in various languages.  In Swift, some of these reserved
/// words can be used if we put them in backticks.  Others must be modified
/// by appending an underscore so they don't conflict.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
@testable import SwiftProtobuf

class Test_Reserved: XCTestCase {
    func testEnumNaming() {
        XCTAssertEqual(ProtobufUnittest_SwiftReservedTest.Enum.double.rawValue, 1)
        XCTAssertEqual(String(describing: ProtobufUnittest_SwiftReservedTest.Enum.double.name!), "DOUBLE")
        XCTAssertEqual(ProtobufUnittest_SwiftReservedTest.Enum.json.rawValue, 2)
        XCTAssertEqual(String(describing: ProtobufUnittest_SwiftReservedTest.Enum.json.name!), "JSON")
        XCTAssertEqual(ProtobufUnittest_SwiftReservedTest.Enum.`class`.rawValue, 3)
        XCTAssertEqual(String(describing: ProtobufUnittest_SwiftReservedTest.Enum.`class`.name!), "CLASS")
        XCTAssertEqual(ProtobufUnittest_SwiftReservedTest.Enum.___.rawValue, 4)
        XCTAssertEqual(String(describing: ProtobufUnittest_SwiftReservedTest.Enum.___.name!), "_")
        XCTAssertEqual(ProtobufUnittest_SwiftReservedTest.Enum.self_.rawValue, 5)
        XCTAssertEqual(String(describing: ProtobufUnittest_SwiftReservedTest.Enum.self_.name!), "SELF")
        XCTAssertEqual(ProtobufUnittest_SwiftReservedTest.Enum.type.rawValue, 6)
        XCTAssertEqual(String(describing: ProtobufUnittest_SwiftReservedTest.Enum.type.name!), "TYPE")
    }

    func testMessageNames() {
        XCTAssertEqual(ProtobufUnittest_SwiftReservedTest.classMessage.protoMessageName, "protobuf_unittest.SwiftReservedTest.class")
        XCTAssertEqual(ProtobufUnittest_SwiftReservedTest.isEqual.protoMessageName, "protobuf_unittest.SwiftReservedTest.isEqual")
        XCTAssertEqual(ProtobufUnittest_SwiftReservedTest.TypeMessage.protoMessageName, "protobuf_unittest.SwiftReservedTest.Type")
    }

    func testFieldNamesMatchingMetadata() {
        // A chunk of this test is just that things compile because it is calling the names
        // we expect to have generated.

        var msg = ProtobufUnittest_SwiftReservedTest()

        msg.protoMessageName = 1
        msg.protoPackageName = 2
        msg.anyTypePrefix = 3
        msg.anyTypeURL = 4

        msg.isInitialized_p = "foo"
        msg.hashValue_p = "bar"
        msg.debugDescription_p = 5

        XCTAssertEqual(msg.debugDescription, "SwiftProtobufTests.ProtobufUnittest_SwiftReservedTest:\nproto_message_name: 1\nproto_package_name: 2\nany_type_prefix: 3\nany_type_url: 4\nis_initialized: \"foo\"\nhash_value: \"bar\"\ndebug_description: 5\n")

        msg.clearIsInitialized_p()
        msg.clearHashValue_p()
        msg.clearDebugDescription_p()
        XCTAssertFalse(msg.hasIsInitialized_p)
        XCTAssertFalse(msg.hasHashValue_p)
        XCTAssertFalse(msg.hasDebugDescription_p)
    }

    func testExtensionNamesMatching() {
        // This is really just a compile test, if things don't compile, check that the
        // new names really make sense.

        var msg = ProtobufUnittest_SwiftReservedTest.TypeMessage()

        msg.debugDescription_p = true
        XCTAssertTrue(msg.hasDebugDescription_p)
        msg.clearDebugDescription_p()

        msg.SwiftReservedTestExt2_hashValue = true
        XCTAssertTrue(msg.hasSwiftReservedTestExt2_hashValue)
        msg.clearSwiftReservedTestExt2_hashValue()
    }
}
