// Tests/SwiftProtobufTests/Test_Required.swift - Test required field handling
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// The current Swift backend implementation:
///  * Always serializes all required fields.
///  * Does not fail deserialization if a required field is missing.
///  * Getter always returns a non-nil value (even for message and group fields)
///  * Accessor uses a non-optional type
///
/// In particular, this means that you cannot clear a required field by
/// setting it to nil as you can with an optional field.  With an
/// optional field, assigning nil clears it (after which reading it
/// will return the default value or nil if no default was specified).
///
/// Note: Google's documentation says that "...  old readers will
/// consider messages without [a required] field to be incomplete".
/// This suggests that newer readers should not reject messages that
/// are missing required fields.  It also appears that Google's
/// serializers simply omit unset required fields.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

import SwiftProtobuf

class Test_Required: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestAllRequiredTypes

    func test_IsInitialized() {
        // message declared in proto2 syntax file with required fields.
        var msg = ProtobufUnittest_TestRequired()
        XCTAssertFalse(msg.isInitialized)
        msg.a = 1
        XCTAssertFalse(msg.isInitialized)
        msg.b = 2
        XCTAssertFalse(msg.isInitialized)
        msg.c = 3
        XCTAssertTrue(msg.isInitialized)
    }

    func test_OneOf_IsInitialized() {
        // message declared in proto2 syntax file with a message in a oneof where that message
        // has a required field.
        var msg = ProtobufUnittest_TestRequiredOneof()
        XCTAssertTrue(msg.isInitialized)
        msg.fooMessage = ProtobufUnittest_TestRequiredOneof.NestedMessage()
        XCTAssertFalse(msg.isInitialized)
        msg.fooInt = 1
        XCTAssertTrue(msg.isInitialized)
        msg.fooMessage = ProtobufUnittest_TestRequiredOneof.NestedMessage()
        XCTAssertFalse(msg.isInitialized)
        msg.fooMessage.requiredDouble = 1.1
        XCTAssertTrue(msg.isInitialized)

        // group within the oneof that has a required field.
        var msg2 = ProtobufUnittest_OneOfContainer()
        XCTAssertTrue(msg2.isInitialized)
        msg2.option3 = ProtobufUnittest_OneOfContainer.Option3()
        XCTAssertFalse(msg2.isInitialized)
        msg2.option4 = 1
        XCTAssertTrue(msg2.isInitialized)
        msg2.option3 = ProtobufUnittest_OneOfContainer.Option3()
        XCTAssertFalse(msg2.isInitialized)
        msg2.option3.a = 1
        XCTAssertTrue(msg2.isInitialized)
    }


    func test_NestedInProto2_IsInitialized() {
        // message declared in proto2 syntax file, with fields that are another message that has
        // required fields.
        var msg = ProtobufUnittest_TestRequiredForeign()

        XCTAssertTrue(msg.isInitialized)

        msg.optionalMessage = ProtobufUnittest_TestRequired()
        XCTAssertFalse(msg.isInitialized)
        msg.optionalMessage.a = 1
        msg.optionalMessage.b = 2
        XCTAssertFalse(msg.isInitialized)
        msg.optionalMessage.c = 3
        XCTAssertTrue(msg.isInitialized)

        msg.repeatedMessage.append(ProtobufUnittest_TestRequired())
        XCTAssertFalse(msg.isInitialized)
        msg.repeatedMessage[0].a = 1
        msg.repeatedMessage[0].b = 2
        XCTAssertFalse(msg.isInitialized)
        msg.repeatedMessage[0].c = 3
        XCTAssertTrue(msg.isInitialized)
    }

    func test_NestedInProto3_IsInitialized() {
        // message declared in proto3 syntax file, with fields that are another message that has
        // required fields.
        var msg = Proto2NofieldpresenceUnittest_TestProto2Required()

        XCTAssertTrue(msg.isInitialized)

        msg.proto2 = ProtobufUnittest_TestRequired()
        XCTAssertFalse(msg.isInitialized)
        msg.proto2.a = 1
        msg.proto2.b = 2
        XCTAssertFalse(msg.isInitialized)
        msg.proto2.c = 3
        XCTAssertTrue(msg.isInitialized)
    }

    func test_map_isInitialized() {
        var msg = ProtobufUnittest_TestRequiredMessageMap()

        XCTAssertTrue(msg.isInitialized)

        msg.mapField[0] = ProtobufUnittest_TestRequired()
        XCTAssertFalse(msg.isInitialized)

        msg.mapField[0]!.a = 1
        msg.mapField[0]!.b = 2
        XCTAssertFalse(msg.isInitialized)
        msg.mapField[0]!.c = 3
        XCTAssertTrue(msg.isInitialized)
    }

    func test_Extensions_isInitialized() {
        var msg = ProtobufUnittest_TestAllExtensions()

        XCTAssertTrue(msg.isInitialized)

        msg.ProtobufUnittest_TestRequired_single = ProtobufUnittest_TestRequired()
        XCTAssertFalse(msg.isInitialized)
        msg.ProtobufUnittest_TestRequired_single.a = 1
        msg.ProtobufUnittest_TestRequired_single.b = 2
        XCTAssertFalse(msg.isInitialized)
        msg.ProtobufUnittest_TestRequired_single.c = 3
        XCTAssertTrue(msg.isInitialized)

        msg.ProtobufUnittest_TestRequired_multi.append(ProtobufUnittest_TestRequired())
        XCTAssertFalse(msg.isInitialized)
        msg.ProtobufUnittest_TestRequired_multi[0].a = 1
        msg.ProtobufUnittest_TestRequired_multi[0].b = 2
        XCTAssertFalse(msg.isInitialized)
        msg.ProtobufUnittest_TestRequired_multi[0].c = 3
        XCTAssertTrue(msg.isInitialized)
    }

    // Helper to assert decoding fails with a not initialized error.
    fileprivate func assertDecodeFailsNotInitialized(_ bytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let _ = try MessageTestType(serializedData: Data(bytes))
            XCTFail("Swift decode should have failed: \(bytes)", file: file, line: line)
        } catch BinaryDecodingError.missingRequiredFields {
            // Correct error!
        } catch let e {
            XCTFail("Decoding \(bytes) got wrong error: \(e)", file: file, line: line)
        }
    }

    // Helper to assert decoding partial succeeds.
    fileprivate func assertPartialDecodeSucceeds(_ bytes: [UInt8], _ expectedTextFormat: String, file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let msg = try MessageTestType(serializedData: Data(bytes), partial: true)
            var expected = "SwiftProtobufTests.ProtobufUnittest_TestAllRequiredTypes:\n"
            if !expectedTextFormat.isEmpty {
                expected += expectedTextFormat + "\n"
            }
            XCTAssertEqual(msg.debugDescription, expected, "While decoding \(bytes)", file: file, line: line)
        } catch let e {
            XCTFail("Decoding \(bytes) failed with error: \(e)", file: file, line: line)
        }
    }

    func test_decodeRequired() throws {
        // Empty message.
        assertDecodeFailsNotInitialized([])
        assertPartialDecodeSucceeds([], "")

        // Test every field on its own.
        let testInputs: [([UInt8], String)] = [
            ([8, 1], "required_int32: 1"),
            ([16, 2], "required_int64: 2"),
            ([24, 3], "required_uint32: 3"),
            ([32, 4], "required_uint64: 4"),
            ([40, 10], "required_sint32: 5"),
            ([48, 12], "required_sint64: 6"),
            ([61, 7, 0, 0, 0], "required_fixed32: 7"),
            ([65, 8, 0, 0, 0, 0, 0, 0, 0], "required_fixed64: 8"),
            ([77, 9, 0, 0, 0], "required_sfixed32: 9"),
            ([81, 10, 0, 0, 0, 0, 0, 0, 0], "required_sfixed64: 10"),
            ([93, 0, 0, 48, 65], "required_float: 11.0"),
            ([97, 0, 0, 0, 0, 0, 0, 40, 64], "required_double: 12.0"),
            ([104, 1], "required_bool: true"),
            ([114, 2, 49, 52], "required_string: \"14\""),
            ([122, 1, 15], "required_bytes: \"\\017\""),
            ([131, 1, 136, 1, 16, 132, 1], "RequiredGroup {\n  a: 16\n}"),
            ([146, 1, 2, 8, 18], "required_nested_message {\n  bb: 18\n}"),
            ([154, 1, 2, 8, 19], "required_foreign_message {\n  c: 19\n}"),
            ([162, 1, 2, 8, 20], "required_import_message {\n  d: 20\n}"),
            ([168, 1, 3], "required_nested_enum: BAZ"),
            ([176, 1, 5], "required_foreign_enum: FOREIGN_BAR"),
            ([184, 1, 9], "required_import_enum: IMPORT_BAZ"),
            ([194, 1, 2, 50, 52], "required_string_piece: \"24\""),
            ([202, 1, 2, 50, 53], "required_cord: \"25\""),
            ([210, 1, 2, 8, 26], "required_public_import_message {\n  e: 26\n}"),
            ([218, 1, 2, 8, 27], "required_lazy_message {\n  bb: 27\n}"),
            ([232, 3, 61], "default_int32: 61"),
            ([240, 3, 62], "default_int64: 62"),
            ([248, 3, 63], "default_uint32: 63"),
            ([128, 4, 64], "default_uint64: 64"),
            ([136, 4, 130, 1], "default_sint32: 65"),
            ([144, 4, 132, 1], "default_sint64: 66"),
            ([157, 4, 67, 0, 0, 0], "default_fixed32: 67"),
            ([161, 4, 68, 0, 0, 0, 0, 0, 0, 0], "default_fixed64: 68"),
            ([173, 4, 69, 0, 0, 0], "default_sfixed32: 69"),
            ([177, 4, 70, 0, 0, 0, 0, 0, 0, 0], "default_sfixed64: 70"),
            ([189, 4, 0, 0, 142, 66], "default_float: 71.0"),
            ([193, 4, 0, 0, 0, 0, 0, 0, 82, 64], "default_double: 72.0"),
            ([200, 4, 0], "default_bool: false"),
            ([210, 4, 2, 55, 52], "default_string: \"74\""),
            ([218, 4, 1, 75], "default_bytes: \"K\""),
            ([136, 5, 3], "default_nested_enum: BAZ"),
            ([144, 5, 6], "default_foreign_enum: FOREIGN_BAZ"),
            ([152, 5, 9], "default_import_enum: IMPORT_BAZ"),
            ([162, 5, 2, 56, 52], "default_string_piece: \"84\""),
            ([170, 5, 2, 56, 53], "default_cord: \"85\""),
        ]
        for (bytes, textFormattedField) in testInputs {
            assertDecodeFailsNotInitialized(bytes)
            assertPartialDecodeSucceeds(bytes, textFormattedField)
        }

        // Glue it all together and it should decode ok as it will be complete.
        var allBytesData = Data()
        var allTextFormattedField = "SwiftProtobufTests.ProtobufUnittest_TestAllRequiredTypes:\n"
        for (bytes, textFormattedField) in testInputs {
          allBytesData.append(Data(bytes))
          allTextFormattedField.append(textFormattedField)
          allTextFormattedField.append("\n")
        }
        let fullMsg = try ProtobufUnittest_TestAllRequiredTypes(serializedData: allBytesData)
        XCTAssertEqual(fullMsg.debugDescription, allTextFormattedField)
    }

    // Helper to assert encoding fails with a not initialized error.
    fileprivate func assertEncodeFailsNotInitialized(_ message: MessageTestType, file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let _ = try message.serializedData()
            XCTFail("Swift encode should have failed: \(message)", file: file, line: line)
        } catch BinaryEncodingError.missingRequiredFields {
            // Correct error!
        } catch let e {
            XCTFail("Encoding got wrong error: \(e) for \(message)", file: file, line: line)
        }
    }

    // Helper to assert encoding partial succeeds.
    fileprivate func assertPartialEncodeSucceeds(_ message: MessageTestType, _ expectedBytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let data = try message.serializedData(partial: true)
            XCTAssertEqual(data, Data(expectedBytes), "While encoding \(message)", file: file, line: line)
        } catch let e {
            XCTFail("Encoding failed with error: \(e) for \(message)", file: file, line: line)
        }
    }

    func test_encodeRequired() throws {
        var msg = MessageTestType()

        // Empty message.
        assertEncodeFailsNotInitialized(msg)
        assertPartialEncodeSucceeds(msg, [])

        typealias ConfigurationBlock = (inout MessageTestType) -> Void

        // Test every field on its own.
        let testInputs: [([UInt8], ConfigurationBlock)] = [
            ([8, 1], { (m) in m.requiredInt32 = 1 }),
            ([16, 2], { (m) in m.requiredInt64 = 2 }),
            ([24, 3], { (m) in m.requiredUint32 = 3 }),
            ([32, 4], { (m) in m.requiredUint64 = 4 }),
            ([40, 10], { (m) in m.requiredSint32 = 5 }),
            ([48, 12], { (m) in m.requiredSint64 = 6 }),
            ([61, 7, 0, 0, 0], { (m) in m.requiredFixed32 = 7 }),
            ([65, 8, 0, 0, 0, 0, 0, 0, 0], { (m) in m.requiredFixed64 = 8 }),
            ([77, 9, 0, 0, 0], { (m) in m.requiredSfixed32 = 9 }),
            ([81, 10, 0, 0, 0, 0, 0, 0, 0], { (m) in m.requiredSfixed64 = 10 }),
            ([93, 0, 0, 48, 65], { (m) in m.requiredFloat = 11 }),
            ([97, 0, 0, 0, 0, 0, 0, 40, 64], { (m) in m.requiredDouble = 12 }),
            ([104, 1], { (m) in m.requiredBool = true }),
            ([114, 2, 49, 52], { (m) in m.requiredString = "14" }),
            ([122, 1, 15], { (m) in m.requiredBytes = Data([15]) }),
            ([131, 1, 136, 1, 16, 132, 1], { (m) in m.requiredGroup.a = 16 }),
            ([146, 1, 2, 8, 18], { (m) in m.requiredNestedMessage.bb = 18 }),
            ([154, 1, 2, 8, 19], { (m) in m.requiredForeignMessage.c = 19 }),
            ([162, 1, 2, 8, 20], { (m) in m.requiredImportMessage.d = 20 }),
            ([168, 1, 3], { (m) in m.requiredNestedEnum = .baz }),
            ([176, 1, 5], { (m) in m.requiredForeignEnum = .foreignBar }),
            ([184, 1, 9], { (m) in m.requiredImportEnum = .importBaz }),
            ([194, 1, 2, 50, 52], { (m) in m.requiredStringPiece = "24" }),
            ([202, 1, 2, 50, 53], { (m) in m.requiredCord = "25" }),
            ([210, 1, 2, 8, 26], { (m) in m.requiredPublicImportMessage.e = 26 }),
            ([218, 1, 2, 8, 27], { (m) in m.requiredLazyMessage.bb = 27 }),
            ([232, 3, 61], { (m) in m.defaultInt32 = 61 }),
            ([240, 3, 62], { (m) in m.defaultInt64 = 62 }),
            ([248, 3, 63], { (m) in m.defaultUint32 = 63 }),
            ([128, 4, 64], { (m) in m.defaultUint64 = 64 }),
            ([136, 4, 130, 1], { (m) in m.defaultSint32 = 65 }),
            ([144, 4, 132, 1], { (m) in m.defaultSint64 = 66 }),
            ([157, 4, 67, 0, 0, 0], { (m) in m.defaultFixed32 = 67 }),
            ([161, 4, 68, 0, 0, 0, 0, 0, 0, 0], { (m) in m.defaultFixed64 = 68 }),
            ([173, 4, 69, 0, 0, 0], { (m) in m.defaultSfixed32 = 69 }),
            ([177, 4, 70, 0, 0, 0, 0, 0, 0, 0], { (m) in m.defaultSfixed64 = 70 }),
            ([189, 4, 0, 0, 142, 66], { (m) in m.defaultFloat = 71 }),
            ([193, 4, 0, 0, 0, 0, 0, 0, 82, 64], { (m) in m.defaultDouble = 72 }),
            ([200, 4, 0], { (m) in m.defaultBool = false }),
            ([210, 4, 2, 55, 52], { (m) in m.defaultString = "74" }),
            ([218, 4, 1, 75], { (m) in m.defaultBytes = Data([75]) }),
            ([136, 5, 3], { (m) in m.defaultNestedEnum = .baz }),
            ([144, 5, 6], { (m) in m.defaultForeignEnum = .foreignBaz }),
            ([152, 5, 9], { (m) in m.defaultImportEnum = .importBaz }),
            ([162, 5, 2, 56, 52], { (m) in m.defaultStringPiece = "84" }),
            ([170, 5, 2, 56, 53], { (m) in m.defaultCord = "85" }),
        ]
        for (expected, configure) in testInputs {
            var message = MessageTestType()
            configure(&message)
            assertEncodeFailsNotInitialized(message)
            assertPartialEncodeSucceeds(message, expected)
        }

        // Glue it all together and it should encode ok as it will be complete.
        var allExpectedData = Data()
        msg = MessageTestType()
        for (expected, configure) in testInputs {
            allExpectedData.append(Data(expected))
            configure(&msg)
        }
        let serialized = try msg.serializedData()
        XCTAssertEqual(serialized, allExpectedData)
    }
}

class Test_SmallRequired: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestSomeRequiredTypes
    // Check behavior of a small message (non-heap-stored) with required fields

    // Helper to assert decoding fails with a not initialized error.
    fileprivate func assertDecodeFailsNotInitialized(_ bytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let _ = try MessageTestType(serializedData: Data(bytes))
            XCTFail("Swift decode should have failed: \(bytes)", file: file, line: line)
        } catch BinaryDecodingError.missingRequiredFields {
            // Correct error!
        } catch let e {
            XCTFail("Decoding \(bytes) got wrong error: \(e)", file: file, line: line)
        }
    }

    // Helper to assert decoding partial succeeds.
    fileprivate func assertPartialDecodeSucceeds(_ bytes: [UInt8], _ expectedTextFormat: String, file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let msg = try MessageTestType(serializedData: Data(bytes), partial: true)
            var expected = "SwiftProtobufTests.ProtobufUnittest_TestSomeRequiredTypes:\n"
            if !expectedTextFormat.isEmpty {
                expected += expectedTextFormat + "\n"
            }
            XCTAssertEqual(msg.debugDescription, expected, "While decoding \(bytes)", file: file, line: line)
        } catch let e {
            XCTFail("Decoding \(bytes) failed with error: \(e)", file: file, line: line)
        }
    }

    func test_decodeRequired() throws {
        // Empty message.
        assertDecodeFailsNotInitialized([])
        assertPartialDecodeSucceeds([], "")

        // Test every field on its own.
        let testInputs: [([UInt8], String)] = [
            ([8, 1], "required_int32: 1"),
            ([21, 0, 0, 0, 64], "required_float: 2.0"),
            ([24, 1], "required_bool: true"),
            ([34, 1, 52], "required_string: \"4\""),
            ([42, 1, 5], "required_bytes: \"\\005\""),
            ([48, 1], "required_nested_enum: FOO"),
        ]
        for (bytes, textFormattedField) in testInputs {
            assertDecodeFailsNotInitialized(bytes)
            assertPartialDecodeSucceeds(bytes, textFormattedField)
        }

        // Glue it all together and it should decode ok as it will be complete.
        var allBytesData = Data()
        var allTextFormattedField = "SwiftProtobufTests.ProtobufUnittest_TestSomeRequiredTypes:\n"
        for (bytes, textFormattedField) in testInputs {
          allBytesData.append(Data(bytes))
          allTextFormattedField.append(textFormattedField)
          allTextFormattedField.append("\n")
        }
        let fullMsg = try ProtobufUnittest_TestSomeRequiredTypes(serializedData: allBytesData)
        XCTAssertEqual(fullMsg.debugDescription, allTextFormattedField)
    }

    // Helper to assert encoding fails with a not initialized error.
    fileprivate func assertEncodeFailsNotInitialized(_ message: MessageTestType, file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let _ = try message.serializedData()
            XCTFail("Swift encode should have failed: \(message)", file: file, line: line)
        } catch BinaryEncodingError.missingRequiredFields {
            // Correct error!
        } catch let e {
            XCTFail("Encoding got wrong error: \(e) for \(message)", file: file, line: line)
        }
    }

    // Helper to assert encoding partial succeeds.
    fileprivate func assertPartialEncodeSucceeds(_ message: MessageTestType, _ expectedBytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let data = try message.serializedData(partial: true)
            XCTAssertEqual(data, Data(expectedBytes), "While encoding \(message)", file: file, line: line)
        } catch let e {
            XCTFail("Encoding failed with error: \(e) for \(message)", file: file, line: line)
        }
    }

    func test_encodeRequired() throws {
        var msg = MessageTestType()

        // Empty message.
        assertEncodeFailsNotInitialized(msg)
        assertPartialEncodeSucceeds(msg, [])

        typealias ConfigurationBlock = (inout MessageTestType) -> Void

        // Test every field on its own.
        let testInputs: [([UInt8], ConfigurationBlock)] = [
            ([8, 1], { (m) in m.requiredInt32 = 1 }),
            ([21, 0, 0, 0, 64], { (m) in m.requiredFloat = 2 }),
            ([24, 1], { (m) in m.requiredBool = true }),
            ([34, 1, 52], { (m) in m.requiredString = "4" }),
            ([42, 1, 5], { (m) in m.requiredBytes = Data([5]) }),
            ([48, 1], { (m) in m.requiredNestedEnum = .foo }),
        ]
        for (expected, configure) in testInputs {
            var message = MessageTestType()
            configure(&message)
            assertEncodeFailsNotInitialized(message)
            assertPartialEncodeSucceeds(message, expected)
        }

        // Glue it all together and it should encode ok as it will be complete.
        var allExpectedData = Data()
        msg = MessageTestType()
        for (expected, configure) in testInputs {
            allExpectedData.append(Data(expected))
            configure(&msg)
        }
        let serialized = try msg.serializedData()
        XCTAssertEqual(serialized, allExpectedData)
    }
}
