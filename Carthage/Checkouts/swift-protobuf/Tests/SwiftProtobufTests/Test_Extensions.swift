// Tests/SwiftProtobufTests/Test_Extensions.swift - Exercise proto2 extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test support for Proto2 extensions.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

// Exercise the support for Proto2 extensions.

class Test_Extensions: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestAllExtensions
    var extensions = SwiftProtobuf.SimpleExtensionMap()

    func assertEncode(_ expected: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> Void) {
        let empty = MessageTestType()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        do {
            let encoded = try configured.serializedData()
            XCTAssert(Data(expected) == encoded, "Did not encode correctly: got \(encoded)", file: file, line: line)
            do {
                let decoded = try MessageTestType(serializedData: encoded, extensions: extensions)
                XCTAssert(decoded == configured, "Encode/decode cycle should generate equal object: \(decoded) != \(configured)", file: file, line: line)
            } catch {
                XCTFail("Failed to decode protobuf: \(encoded)", file: file, line: line)
            }
        } catch {
            XCTFail("Failed to encode \(configured)", file: file, line: line)
        }
    }

    func assertDecodeSucceeds(_ bytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line, check: (MessageTestType) -> Bool) {
        do {
            let decoded = try MessageTestType(serializedData: Data(bytes), extensions: extensions)
            XCTAssert(check(decoded), "Condition failed for \(decoded)", file: file, line: line)

            let encoded = try decoded.serializedData()
            do {
                let redecoded = try MessageTestType(serializedData: encoded, extensions: extensions)
                XCTAssert(check(redecoded), "Condition failed for redecoded \(redecoded)", file: file, line: line)
                XCTAssertEqual(decoded, redecoded, file: file, line: line)
            } catch {
                XCTFail("Failed to redecode", file: file, line: line)
            }
        } catch {
            XCTFail("Failed to decode", file: file, line: line)
        }
    }

    func assertDecodeFails(_ bytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let _ = try MessageTestType(serializedData: Data(bytes), extensions: extensions)
            XCTFail("Swift decode should have failed: \(bytes)", file: file, line: line)
        } catch {
            // Yay!  It failed!
        }

    }


    override func setUp() {
        // Start with all the extensions from the unittest.proto file:
        extensions = ProtobufUnittest_Unittest_Extensions
        // Append another file's worth:
        extensions.formUnion(ProtobufUnittest_UnittestCustomOptions_Extensions)
        // Append an array of extensions
        extensions.insert(contentsOf:
            [
                Extensions_RepeatedExtensionGroup,
                Extensions_ExtensionGroup
            ]
        )
    }

    func test_optionalInt32Extension() throws {
        assertEncode([8, 17]) { (o: inout MessageTestType) in
            o.ProtobufUnittest_optionalInt32Extension = 17
        }
        assertDecodeSucceeds([8, 99]) {$0.ProtobufUnittest_optionalInt32Extension == 99}
        assertDecodeFails([9])
        assertDecodeFails([9, 0])
        assertDecodesAsUnknownFields([9, 0, 0, 0, 0, 0, 0, 0, 0])  // Wrong wire type (fixed64), valid as an unknown field
        assertDecodeFails([10])
        assertDecodesAsUnknownFields([10, 0])  // Wrong wire type (length delimited), valid as an unknown field
        assertDecodeFails([11])
        assertDecodeFails([11, 0])
        assertDecodesAsUnknownFields([11, 12])  // Wrong wire type (startGroup, endGroup), valid as an unknown field
        assertDecodeFails([12])
        assertDecodeFails([12, 0])
        assertDecodeFails([13])
        assertDecodeFails([13, 0])
        assertDecodesAsUnknownFields([13, 0, 0, 0, 0])  // Wrong wire type (fixed32), valid as an unknown field
        assertDecodeFails([14])
        assertDecodeFails([14, 0])
        assertDecodeFails([15])
        assertDecodeFails([15, 0])

        // Decoded extension should correctly compare to a manually-set extension
        let m1 = try ProtobufUnittest_TestAllExtensions(serializedData: Data([8, 17]), extensions: extensions)
        var m2 = ProtobufUnittest_TestAllExtensions()
        m2.ProtobufUnittest_optionalInt32Extension = 17
        XCTAssertEqual(m1, m2)
        m2.ProtobufUnittest_optionalInt32Extension = 18
        XCTAssertNotEqual(m1, m2)

        XCTAssertEqual(m2.debugDescription, "SwiftProtobufTests.ProtobufUnittest_TestAllExtensions:\n[protobuf_unittest.optional_int32_extension]: 18\n")
        XCTAssertNotEqual(m1.hashValue, m2.hashValue)
    }

    func test_extensionMessageSpecificity() throws {
        // An extension set with two extensions for field #5, but for
        // different messages and with different types
        var extensions = SimpleExtensionMap()
        extensions.insert(ProtobufUnittest_Extensions_optional_sint32_extension)
        extensions.insert(ProtobufUnittest_Extensions_my_extension_int)

        // This should decode with optionalSint32Extension
        let m1 = try ProtobufUnittest_TestAllExtensions(serializedData: Data([40, 1]), extensions: extensions)
        XCTAssertEqual(m1.ProtobufUnittest_optionalSint32Extension, -1)

        // This should decode with myExtensionInt
        let m2 = try ProtobufUnittest_TestFieldOrderings(serializedData: Data([40, 1]), extensions: extensions)
        XCTAssertEqual(m2.ProtobufUnittest_myExtensionInt, 1)
    }

    func test_optionalStringExtension() throws {
        assertEncode([114, 5, 104, 101, 108, 108, 111]) { (o: inout MessageTestType) in
            o.ProtobufUnittest_optionalStringExtension = "hello"
        }
        assertDecodeSucceeds([114, 2, 97, 98]) {$0.ProtobufUnittest_optionalStringExtension == "ab"}

        var m1 = ProtobufUnittest_TestAllExtensions()
        m1.ProtobufUnittest_optionalStringExtension = "ab"
        XCTAssertEqual(m1.debugDescription, "SwiftProtobufTests.ProtobufUnittest_TestAllExtensions:\n[protobuf_unittest.optional_string_extension]: \"ab\"\n")
    }

    func test_repeatedInt32Extension() throws {
        assertEncode([248, 1, 7, 248, 1, 8]) { (o: inout MessageTestType) in
            o.ProtobufUnittest_repeatedInt32Extension = [7, 8]
        }
        assertDecodeSucceeds([248, 1, 7]) {$0.ProtobufUnittest_repeatedInt32Extension == [7]}
        assertDecodeSucceeds([248, 1, 7, 248, 1, 8]) {$0.ProtobufUnittest_repeatedInt32Extension == [7, 8]}
        assertDecodeSucceeds([250, 1, 2, 7, 8]) {$0.ProtobufUnittest_repeatedInt32Extension == [7, 8]}

        // Verify that the usual array access/modification operations work correctly
        var m = ProtobufUnittest_TestAllExtensions()
        m.ProtobufUnittest_repeatedInt32Extension = [7]
        m.ProtobufUnittest_repeatedInt32Extension.append(8)
        XCTAssertEqual(m.ProtobufUnittest_repeatedInt32Extension, [7, 8])
        XCTAssertEqual(m.ProtobufUnittest_repeatedInt32Extension[0], 7)
        m.ProtobufUnittest_repeatedInt32Extension[1] = 9
        XCTAssertNotEqual(m.ProtobufUnittest_repeatedInt32Extension, [7, 8])
        XCTAssertEqual(m.ProtobufUnittest_repeatedInt32Extension, [7, 9])

        XCTAssertEqual(m.debugDescription, "SwiftProtobufTests.ProtobufUnittest_TestAllExtensions:\n[protobuf_unittest.repeated_int32_extension]: 7\n[protobuf_unittest.repeated_int32_extension]: 9\n")
    }

    func test_defaultInt32Extension() throws {
        var m = ProtobufUnittest_TestAllExtensions()
        XCTAssertEqual(m.ProtobufUnittest_defaultInt32Extension, 41)
        XCTAssertEqual(try m.serializedBytes(), [])
        XCTAssertEqual(m.debugDescription, "SwiftProtobufTests.ProtobufUnittest_TestAllExtensions:\n")
        m.ProtobufUnittest_defaultInt32Extension = 100
        XCTAssertEqual(try m.serializedBytes(), [232, 3, 100])
        XCTAssertEqual(m.debugDescription, "SwiftProtobufTests.ProtobufUnittest_TestAllExtensions:\n[protobuf_unittest.default_int32_extension]: 100\n")
        m.clearProtobufUnittest_defaultInt32Extension()
        XCTAssertEqual(try m.serializedBytes(), [])
        XCTAssertEqual(m.debugDescription, "SwiftProtobufTests.ProtobufUnittest_TestAllExtensions:\n")
        m.ProtobufUnittest_defaultInt32Extension = 41 // Default value
        XCTAssertEqual(try m.serializedBytes(), [232, 3, 41])
        XCTAssertEqual(m.debugDescription, "SwiftProtobufTests.ProtobufUnittest_TestAllExtensions:\n[protobuf_unittest.default_int32_extension]: 41\n")

        assertEncode([232, 3, 17]) { (o: inout MessageTestType) in
            o.ProtobufUnittest_defaultInt32Extension = 17
        }
    }

    ///
    /// Verify group extensions and handling of unknown groups
    ///
    func test_groupExtension() throws {
        var m = SwiftTestGroupExtensions()
        var group = ExtensionGroup()
        group.a = 7
        m.extensionGroup = group
        let coded = try m.serializedData()

        // Deserialize into a message that lacks the group extension, then reserialize
        // Group should be preserved as an unknown field
        do {
            let m2 = try SwiftTestGroupUnextended(serializedData: coded)
            XCTAssert(!m2.hasA)
            let recoded = try m2.serializedData()

            // Deserialize, check the group contents were preserved.
            do {
                let m3 = try SwiftTestGroupExtensions(serializedData: recoded, extensions: extensions)
                XCTAssertEqual(m3.extensionGroup.a, 7)
            } catch {
                XCTFail("Bad decode/recode/decode cycle")
            }
        } catch {
            XCTFail("Decoding into unextended message failed for \(coded)")
        }
    }


    func test_repeatedGroupExtension() throws {
        var m = SwiftTestGroupExtensions()
        var group1 = RepeatedExtensionGroup()
        group1.a = 7
        var group2 = RepeatedExtensionGroup()
        group2.a = 7
        m.repeatedExtensionGroup = [group1, group2]
        let coded = try m.serializedData()

        // Deserialize into a message that lacks the group extension, then reserialize
        // Group should be preserved as an unknown field
        do {
            let m2 = try SwiftTestGroupUnextended(serializedData: coded)
            XCTAssert(!m2.hasA)
            do {
                let recoded = try m2.serializedData()

                // Deserialize, check the group contents were preserved.
                do {
                    let m3 = try SwiftTestGroupExtensions(serializedData: recoded, extensions: extensions)
                    XCTAssertEqual(m3.repeatedExtensionGroup, [group1, group2])
                } catch {
                    XCTFail("Bad decode/recode/decode cycle")
                }
            } catch {
                XCTFail("Recoding failed for \(m2)")
            }
        } catch {
            XCTFail("Decoding into unextended message failed for \(coded)")
        }
    }

    func test_MessageNoStorageClass() {
        var msg1 = ProtobufUnittest_Extend_MsgNoStorage()
        XCTAssertFalse(msg1.hasProtobufUnittest_Extend_extA)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extA, 0)
        XCTAssertFalse(msg1.hasProtobufUnittest_Extend_extB)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extB, 0)

        msg1.ProtobufUnittest_Extend_extA = 1
        msg1.ProtobufUnittest_Extend_extB = 2
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extA)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extA, 1)
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extB)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extB, 2)

        var msg2 = msg1
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extA)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extA, 1)
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extB)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extB, 2)

        msg2.ProtobufUnittest_Extend_extA = 10
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extA)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extA, 10)
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extB)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extB, 2)
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extA)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extA, 1)
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extB)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extB, 2)

        msg1.ProtobufUnittest_Extend_extB = 3
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extA)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extA, 10)
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extB)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extB, 2)
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extA)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extA, 1)
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extB)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extB, 3)

        msg2 = msg1
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extA)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extA, 1)
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extB)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extB, 3)

        msg2.clearProtobufUnittest_Extend_extA()
        XCTAssertFalse(msg2.hasProtobufUnittest_Extend_extA)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extA, 0)
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extB)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extB, 3)
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extA)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extA, 1)
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extB)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extB, 3)

        msg1.clearProtobufUnittest_Extend_extB()
        XCTAssertFalse(msg2.hasProtobufUnittest_Extend_extA)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extA, 0)
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extB)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extB, 3)
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extA)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extA, 1)
        XCTAssertFalse(msg1.hasProtobufUnittest_Extend_extB)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extB, 0)
    }

    func test_MessageUsingStorageClass() {
        var msg1 = ProtobufUnittest_Extend_MsgUsesStorage()
        XCTAssertFalse(msg1.hasProtobufUnittest_Extend_extC)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extC, 0)
        XCTAssertFalse(msg1.hasProtobufUnittest_Extend_extD)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extD, 0)

        msg1.ProtobufUnittest_Extend_extC = 1
        msg1.ProtobufUnittest_Extend_extD = 2
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extC)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extC, 1)
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extD)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extD, 2)

        var msg2 = msg1
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extC)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extC, 1)
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extD)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extD, 2)

        msg2.ProtobufUnittest_Extend_extC = 10
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extC)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extC, 10)
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extD)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extD, 2)
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extC)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extC, 1)
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extD)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extD, 2)

        msg1.ProtobufUnittest_Extend_extD = 3
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extC)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extC, 10)
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extD)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extD, 2)
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extC)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extC, 1)
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extD)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extD, 3)

        msg2 = msg1
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extC)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extC, 1)
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extD)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extD, 3)

        msg2.clearProtobufUnittest_Extend_extC()
        XCTAssertFalse(msg2.hasProtobufUnittest_Extend_extC)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extC, 0)
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extD)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extD, 3)
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extC)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extC, 1)
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extD)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extD, 3)

        msg1.clearProtobufUnittest_Extend_extD()
        XCTAssertFalse(msg2.hasProtobufUnittest_Extend_extC)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extC, 0)
        XCTAssertTrue(msg2.hasProtobufUnittest_Extend_extD)
        XCTAssertEqual(msg2.ProtobufUnittest_Extend_extD, 3)
        XCTAssertTrue(msg1.hasProtobufUnittest_Extend_extC)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extC, 1)
        XCTAssertFalse(msg1.hasProtobufUnittest_Extend_extD)
        XCTAssertEqual(msg1.ProtobufUnittest_Extend_extD, 0)
    }
}
