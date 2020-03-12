// Tests/SwiftProtobufTests/Test_TextFormat_WKT_proto3.swift - Exercise proto3 text format coding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This is a set of tests for text format protobuf files.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_TextFormat_WKT_proto3: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestWellKnownTypes

    func assertAnyTest<M: Message & Equatable>(_ message: M, expected: String, file: XCTestFileArgType = #file, line: UInt = #line) {
        let empty = MessageTestType()
        var configured = empty
        do {
            configured.anyField = try Google_Protobuf_Any(message: message)
        } catch {
            XCTFail("Assigning to any field failed: \(error)", file: file, line: line)
        }
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        let encoded = configured.textFormatString()
        XCTAssert(expected == encoded, "Did not encode correctly: got \(encoded)", file: file, line: line)
        do {
            let decoded = try MessageTestType(textFormatString: encoded)
            let decodedMessage = try M(unpackingAny: decoded.anyField)
            let r = (message == decodedMessage)
            XCTAssert(r, "Encode/decode cycle should generate equal object: \(decoded) != \(configured)", file: file, line: line)
        } catch {
            XCTFail("Encode/decode cycle should not throw error, decoding: \(error)", file: file, line: line)
        }
    }

    // Any equality is a little tricky, so this directly tests the inner
    // contained object after unpacking the Any.
    func testAny() throws {
        assertAnyTest(Google_Protobuf_Duration(seconds: 123, nanos: 123456789),
                      expected: "any_field {\n  [type.googleapis.com/google.protobuf.Duration] {\n    seconds: 123\n    nanos: 123456789\n  }\n}\n")
        assertAnyTest(Google_Protobuf_Empty(),
                      expected: "any_field {\n  [type.googleapis.com/google.protobuf.Empty] {\n  }\n}\n")

        // Nested any
        let a = try ProtobufUnittest_TestWellKnownTypes.with {
            $0.anyField = try Google_Protobuf_Any(message: Google_Protobuf_Any(message: Google_Protobuf_Duration(seconds: 123, nanos: 234567890)))
        }
        let a_encoded = a.textFormatString()
        XCTAssertEqual(a_encoded, "any_field {\n  [type.googleapis.com/google.protobuf.Any] {\n    [type.googleapis.com/google.protobuf.Duration] {\n      seconds: 123\n      nanos: 234567890\n    }\n  }\n}\n")

        let a_decoded = try ProtobufUnittest_TestWellKnownTypes(textFormatString: a_encoded)
        let a_decoded_any = a_decoded.anyField
        let a_decoded_any_any = try Google_Protobuf_Any(unpackingAny: a_decoded_any)
        let a_decoded_any_any_duration = try Google_Protobuf_Duration(unpackingAny: a_decoded_any_any)
        XCTAssertEqual(a_decoded_any_any_duration.seconds, 123)
        XCTAssertEqual(a_decoded_any_any_duration.nanos, 234567890)
    }

    // Any supports a "verbose" text encoding that uses the URL as the key
    // and then encloses the serialization of the object.
    func testAny_verbose() {
        let a: ProtobufUnittest_TestWellKnownTypes
        do {
            a = try ProtobufUnittest_TestWellKnownTypes(textFormatString: "any_field {[type.googleapis.com/google.protobuf.Duration] {seconds:77,nanos:123456789}}")
        } catch let e {
            XCTFail("Decoding failed: \(e)")
            return
        }
        do {
            let a_any = a.anyField
            let a_duration = try Google_Protobuf_Duration(unpackingAny: a_any)
            XCTAssertEqual(a_duration.seconds, 77)
            XCTAssertEqual(a_duration.nanos, 123456789)
        } catch let e {
            XCTFail("Any field doesn't hold a duration?: \(e)")
        }

        // Nested Any is a particularly tricky decode problem
        let b: ProtobufUnittest_TestWellKnownTypes
        do {
            b = try ProtobufUnittest_TestWellKnownTypes(textFormatString: "any_field {[type.googleapis.com/google.protobuf.Any]{[type.googleapis.com/google.protobuf.Duration] {seconds:88,nanos:987654321}}}")
        } catch let e {
            XCTFail("Decoding failed: \(e)")
            return
        }
        let b_any: Google_Protobuf_Any
        do {
            b_any = try Google_Protobuf_Any(unpackingAny: b.anyField)
        } catch let e {
            XCTFail("Any field doesn't hold an Any?: \(e)")
            return
        }
        do {
            let b_duration = try Google_Protobuf_Duration(unpackingAny: b_any)
            XCTAssertEqual(b_duration.seconds, 88)
            XCTAssertEqual(b_duration.nanos, 987654321)
        } catch let e {
            XCTFail("Inner Any field doesn't hold a Duration: \(e)")
        }
    }

    func testApi() {
    }

    func testDuration() {
        assertTextFormatEncode(
            "duration_field {\n  seconds: 123\n  nanos: 123456789\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.durationField = Google_Protobuf_Duration(seconds: 123, nanos: 123456789)
        }
    }

    func testEmpty() {
        assertTextFormatEncode(
            "empty_field {\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.emptyField = Google_Protobuf_Empty()
        }
    }

    func testFieldMask() {
        assertTextFormatEncode(
            "field_mask_field {\n  paths: \"foo\"\n  paths: \"bar.baz\"\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.fieldMaskField = Google_Protobuf_FieldMask(protoPaths: "foo", "bar.baz")
        }
    }

    func tesetSourceContext() {
    }

    func testStruct() {
    }

    func testTimestamp() {
        assertTextFormatEncode(
            "timestamp_field {\n  seconds: 123\n  nanos: 123456789\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.timestampField = Google_Protobuf_Timestamp(seconds: 123, nanos: 123456789)
        }
    }

    func testType() {
    }

    func testDoubleValue() {
        assertTextFormatEncode(
            "double_field {\n  value: 1.125\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.doubleField = Google_Protobuf_DoubleValue(1.125)
        }
        assertTextFormatEncode(
            "double_field {\n  value: inf\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.doubleField = Google_Protobuf_DoubleValue(Double.infinity)
        }
        assertTextFormatEncode(
            "double_field {\n  value: -inf\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.doubleField = Google_Protobuf_DoubleValue(-Double.infinity)
        }
    }

    func testFloatValue() {
        assertTextFormatEncode(
            "float_field {\n  value: 1.125\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.floatField = Google_Protobuf_FloatValue(1.125)
        }
        assertTextFormatEncode(
            "float_field {\n  value: inf\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.floatField = Google_Protobuf_FloatValue(Float.infinity)
        }
        assertTextFormatEncode(
            "float_field {\n  value: -inf\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.floatField = Google_Protobuf_FloatValue(-Float.infinity)
        }
    }

    func testInt64Value() {
        assertTextFormatEncode(
            "int64_field {\n  value: 9223372036854775807\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.int64Field = Google_Protobuf_Int64Value(Int64.max)
        }
        assertTextFormatEncode(
            "int64_field {\n  value: -9223372036854775808\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.int64Field = Google_Protobuf_Int64Value(Int64.min)
        }
    }

    func testUInt64Value() {
        assertTextFormatEncode(
            "uint64_field {\n  value: 18446744073709551615\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.uint64Field = Google_Protobuf_UInt64Value(UInt64.max)
        }
    }

    func testInt32Value() {
        assertTextFormatEncode(
            "int32_field {\n  value: 2147483647\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.int32Field = Google_Protobuf_Int32Value(Int32.max)
        }
        assertTextFormatEncode(
            "int32_field {\n  value: -2147483648\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.int32Field = Google_Protobuf_Int32Value(Int32.min)
        }
    }

    func testUInt32Value() {
        assertTextFormatEncode(
            "uint32_field {\n  value: 4294967295\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.uint32Field = Google_Protobuf_UInt32Value(UInt32.max)
        }
    }

    func testBoolValue() {
        assertTextFormatEncode(
            "bool_field {\n  value: true\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.boolField = Google_Protobuf_BoolValue(true)
        }
        // false is the default, so encodes as empty (verified against C++ implementation)
        assertTextFormatEncode(
            "bool_field {\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.boolField = Google_Protobuf_BoolValue(false)
        }
    }

    func testStringValue() {
        assertTextFormatEncode(
            "string_field {\n  value: \"abc\"\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.stringField = Google_Protobuf_StringValue("abc")
        }
    }

    func testBytesValue() {
        assertTextFormatEncode(
            "bytes_field {\n  value: \"abc\"\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.bytesField = Google_Protobuf_BytesValue(Data([97, 98, 99]))
        }
    }

    func testValue() {
    }
}
