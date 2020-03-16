// Tests/SwiftProtobufTests/Test_TextFormat_proto3.swift - Exercise proto3 text format coding
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
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

class Test_TextFormat_proto3: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Proto3Unittest_TestAllTypes

    func testDecoding_comments() {
        assertTextFormatDecodeSucceeds("optional_int32: 41#optional_int32: 42\noptional_int64: 8") {
            (o: MessageTestType) in
            return o.optionalInt32 == 41 && o.optionalInt64 == 8
        }
    }

    func testDecoding_comments_numbers() {
        assertTextFormatDecodeSucceeds("1: 41#optional_int32: 42\n2: 8") {
            (o: MessageTestType) in
            return o.optionalInt32 == 41 && o.optionalInt64 == 8
        }
    }

    //
    // Singular types
    //

    func testEncoding_optionalInt32() {
        var a = MessageTestType()
        a.optionalInt32 = 41

        XCTAssertEqual("optional_int32: 41\n", a.textFormatString())

        assertTextFormatEncode("optional_int32: 1\n") {(o: inout MessageTestType) in o.optionalInt32 = 1 }
        assertTextFormatEncode("optional_int32: 12\n") {(o: inout MessageTestType) in o.optionalInt32 = 12 }
        assertTextFormatEncode("optional_int32: 123\n") {(o: inout MessageTestType) in o.optionalInt32 = 123 }
        assertTextFormatEncode("optional_int32: 1234\n") {(o: inout MessageTestType) in o.optionalInt32 = 1234 }
        assertTextFormatEncode("optional_int32: 12345\n") {(o: inout MessageTestType) in o.optionalInt32 = 12345 }
        assertTextFormatEncode("optional_int32: 123456\n") {(o: inout MessageTestType) in o.optionalInt32 = 123456 }
        assertTextFormatEncode("optional_int32: 1234567\n") {(o: inout MessageTestType) in o.optionalInt32 = 1234567 }
        assertTextFormatEncode("optional_int32: 12345678\n") {(o: inout MessageTestType) in o.optionalInt32 = 12345678 }
        assertTextFormatEncode("optional_int32: 123456789\n") {(o: inout MessageTestType) in o.optionalInt32 = 123456789 }
        assertTextFormatEncode("optional_int32: 1234567890\n") {(o: inout MessageTestType) in o.optionalInt32 = 1234567890 }

        assertTextFormatEncode("optional_int32: 1\n") {(o: inout MessageTestType) in o.optionalInt32 = 1 }
        assertTextFormatEncode("optional_int32: 10\n") {(o: inout MessageTestType) in o.optionalInt32 = 10 }
        assertTextFormatEncode("optional_int32: 100\n") {(o: inout MessageTestType) in o.optionalInt32 = 100 }
        assertTextFormatEncode("optional_int32: 1000\n") {(o: inout MessageTestType) in o.optionalInt32 = 1000 }
        assertTextFormatEncode("optional_int32: 10000\n") {(o: inout MessageTestType) in o.optionalInt32 = 10000 }
        assertTextFormatEncode("optional_int32: 100000\n") {(o: inout MessageTestType) in o.optionalInt32 = 100000 }
        assertTextFormatEncode("optional_int32: 1000000\n") {(o: inout MessageTestType) in o.optionalInt32 = 1000000 }
        assertTextFormatEncode("optional_int32: 10000000\n") {(o: inout MessageTestType) in o.optionalInt32 = 10000000 }
        assertTextFormatEncode("optional_int32: 100000000\n") {(o: inout MessageTestType) in o.optionalInt32 = 100000000 }
        assertTextFormatEncode("optional_int32: 1000000000\n") {(o: inout MessageTestType) in o.optionalInt32 = 1000000000 }


        assertTextFormatEncode("optional_int32: 41\n") {(o: inout MessageTestType) in
            o.optionalInt32 = 41 }
        assertTextFormatEncode("optional_int32: 1\n") {(o: inout MessageTestType) in
            o.optionalInt32 = 1
        }
        assertTextFormatEncode("optional_int32: -1\n") {(o: inout MessageTestType) in
            o.optionalInt32 = -1
        }
        assertTextFormatDecodeSucceeds("optional_int32:0x1234") {(o: MessageTestType) in
            return o.optionalInt32 == 0x1234
        }
        assertTextFormatDecodeSucceeds("optional_int32:41") {(o: MessageTestType) in
            return o.optionalInt32 == 41
        }
        assertTextFormatDecodeSucceeds("optional_int32: 41#optional_int32: 42") {
            (o: MessageTestType) in
            return o.optionalInt32 == 41
        }
        assertTextFormatDecodeSucceeds("optional_int32: 41 optional_int32: 42") {
            (o: MessageTestType) in
            return o.optionalInt32 == 42
        }
        assertTextFormatDecodeFails("optional_int32: a\n")
        assertTextFormatDecodeFails("optional_int32: 999999999999999999999999999999999999\n")
        assertTextFormatDecodeFails("optional_int32: 1,2\n")
        assertTextFormatDecodeFails("optional_int32: 1.2\n")
        assertTextFormatDecodeFails("optional_int32: { }\n")
        assertTextFormatDecodeFails("optional_int32: \"hello\"\n")
        assertTextFormatDecodeFails("optional_int32: true\n")
        assertTextFormatDecodeFails("optional_int32: 0x80000000\n")
        assertTextFormatDecodeSucceeds("optional_int32: -0x80000000\n") {(o: MessageTestType) in
            return o.optionalInt32 == -0x80000000
        }
        assertTextFormatDecodeFails("optional_int32: -0x80000001\n")
    }

    func testEncoding_optionalInt64() {
        var a = MessageTestType()
        a.optionalInt64 = 2

        XCTAssertEqual("optional_int64: 2\n", a.textFormatString())

        assertTextFormatEncode("optional_int64: 1\n") {(o: inout MessageTestType) in o.optionalInt64 = 1 }
        assertTextFormatEncode("optional_int64: 12\n") {(o: inout MessageTestType) in o.optionalInt64 = 12 }
        assertTextFormatEncode("optional_int64: 123\n") {(o: inout MessageTestType) in o.optionalInt64 = 123 }
        assertTextFormatEncode("optional_int64: 1234\n") {(o: inout MessageTestType) in o.optionalInt64 = 1234 }
        assertTextFormatEncode("optional_int64: 12345\n") {(o: inout MessageTestType) in o.optionalInt64 = 12345 }
        assertTextFormatEncode("optional_int64: 123456\n") {(o: inout MessageTestType) in o.optionalInt64 = 123456 }
        assertTextFormatEncode("optional_int64: 1234567\n") {(o: inout MessageTestType) in o.optionalInt64 = 1234567 }
        assertTextFormatEncode("optional_int64: 12345678\n") {(o: inout MessageTestType) in o.optionalInt64 = 12345678 }
        assertTextFormatEncode("optional_int64: 123456789\n") {(o: inout MessageTestType) in o.optionalInt64 = 123456789 }
        assertTextFormatEncode("optional_int64: 1234567890\n") {(o: inout MessageTestType) in o.optionalInt64 = 1234567890 }

        assertTextFormatEncode("optional_int64: 1\n") {(o: inout MessageTestType) in o.optionalInt64 = 1 }
        assertTextFormatEncode("optional_int64: 10\n") {(o: inout MessageTestType) in o.optionalInt64 = 10 }
        assertTextFormatEncode("optional_int64: 100\n") {(o: inout MessageTestType) in o.optionalInt64 = 100 }
        assertTextFormatEncode("optional_int64: 1000\n") {(o: inout MessageTestType) in o.optionalInt64 = 1000 }
        assertTextFormatEncode("optional_int64: 10000\n") {(o: inout MessageTestType) in o.optionalInt64 = 10000 }
        assertTextFormatEncode("optional_int64: 100000\n") {(o: inout MessageTestType) in o.optionalInt64 = 100000 }
        assertTextFormatEncode("optional_int64: 1000000\n") {(o: inout MessageTestType) in o.optionalInt64 = 1000000 }
        assertTextFormatEncode("optional_int64: 10000000\n") {(o: inout MessageTestType) in o.optionalInt64 = 10000000 }
        assertTextFormatEncode("optional_int64: 100000000\n") {(o: inout MessageTestType) in o.optionalInt64 = 100000000 }
        assertTextFormatEncode("optional_int64: 1000000000\n") {(o: inout MessageTestType) in o.optionalInt64 = 1000000000 }

        assertTextFormatEncode("optional_int64: -2\n") {(o: inout MessageTestType) in o.optionalInt64 = -2 }
        assertTextFormatDecodeSucceeds("optional_int64: 0x1234567812345678\n") {(o: MessageTestType) in
            return o.optionalInt64 == 0x1234567812345678
        }

        assertTextFormatDecodeFails("optional_int64: a\n")
        assertTextFormatDecodeFails("optional_int64: 999999999999999999999999999999999999\n")
        assertTextFormatDecodeFails("optional_int64: 1,2\n")
    }

    func testEncoding_optionalUint32() {
        var a = MessageTestType()
        a.optionalUint32 = 3

        XCTAssertEqual("optional_uint32: 3\n", a.textFormatString())

        assertTextFormatEncode("optional_uint32: 3\n") {(o: inout MessageTestType) in
            o.optionalUint32 = 3
        }
        assertTextFormatDecodeSucceeds("optional_uint32: 3u") {
            (o: MessageTestType) in
            return o.optionalUint32 == 3
        }
        assertTextFormatDecodeSucceeds("optional_uint32: 3u optional_int32: 1") {
            (o: MessageTestType) in
            return o.optionalUint32 == 3 && o.optionalInt32 == 1
        }
        assertTextFormatDecodeFails("optional_uint32: -3\n")
        assertTextFormatDecodeFails("optional_uint32: 3x\n")
        assertTextFormatDecodeFails("optional_uint32: 3,4\n")
        assertTextFormatDecodeFails("optional_uint32: 999999999999999999999999999999999999\n")
        assertTextFormatDecodeFails("optional_uint32 3\n")
        assertTextFormatDecodeFails("3u")
        assertTextFormatDecodeFails("optional_uint32: a\n")
        assertTextFormatDecodeFails("optional_uint32 optional_uint32: 7\n")
    }

    func testEncoding_optionalUint64() {
        var a = MessageTestType()
        a.optionalUint64 = 4

        XCTAssertEqual("optional_uint64: 4\n", a.textFormatString())

        assertTextFormatEncode("optional_uint64: 4\n") {(o: inout MessageTestType) in
            o.optionalUint64 = 4
        }

        assertTextFormatDecodeSucceeds("optional_uint64: 0xf234567812345678\n") {(o: MessageTestType) in
            return o.optionalUint64 == 0xf234567812345678
        }
        assertTextFormatDecodeFails("optional_uint64: a\n")
        assertTextFormatDecodeFails("optional_uint64: 999999999999999999999999999999999999\n")
        assertTextFormatDecodeFails("optional_uint64: 7,8")
        assertTextFormatDecodeFails("optional_uint64: [7]")
    }

    func testEncoding_optionalSint32() {
        var a = MessageTestType()
        a.optionalSint32 = 5

        XCTAssertEqual("optional_sint32: 5\n", a.textFormatString())

        assertTextFormatEncode("optional_sint32: 5\n") {(o: inout MessageTestType) in
            o.optionalSint32 = 5
        }
        assertTextFormatEncode("optional_sint32: -5\n") {(o: inout MessageTestType) in
            o.optionalSint32 = -5
        }
        assertTextFormatDecodeSucceeds("    optional_sint32:-5    ") {
            (o: MessageTestType) in
            return o.optionalSint32 == -5
        }

        assertTextFormatDecodeFails("optional_sint32: a\n")
    }

    func testEncoding_optionalSint64() {
        var a = MessageTestType()
        a.optionalSint64 = 6

        XCTAssertEqual("optional_sint64: 6\n", a.textFormatString())

        assertTextFormatEncode("optional_sint64: 6\n") {(o: inout MessageTestType) in
            o.optionalSint64 = 6
        }
        assertTextFormatDecodeFails("optional_sint64: a\n")
    }

    func testEncoding_optionalFixed32() {
        var a = MessageTestType()
        a.optionalFixed32 = 7

        XCTAssertEqual("optional_fixed32: 7\n", a.textFormatString())

        assertTextFormatEncode("optional_fixed32: 7\n") {(o: inout MessageTestType) in
            o.optionalFixed32 = 7
        }

        assertTextFormatDecodeFails("optional_fixed32: a\n")
    }

    func testEncoding_optionalFixed64() {
        var a = MessageTestType()
        a.optionalFixed64 = 8

        XCTAssertEqual("optional_fixed64: 8\n", a.textFormatString())

        assertTextFormatEncode("optional_fixed64: 8\n") {(o: inout MessageTestType) in
            o.optionalFixed64 = 8
        }

        assertTextFormatDecodeFails("optional_fixed64: a\n")
    }

    func testEncoding_optionalSfixed32() {
        var a = MessageTestType()
        a.optionalSfixed32 = 9

        XCTAssertEqual("optional_sfixed32: 9\n", a.textFormatString())

        assertTextFormatEncode("optional_sfixed32: 9\n") {(o: inout MessageTestType) in
            o.optionalSfixed32 = 9
        }

        assertTextFormatDecodeFails("optional_sfixed32: a\n")
    }

    func testEncoding_optionalSfixed64() {
        var a = MessageTestType()
        a.optionalSfixed64 = 10

        XCTAssertEqual("optional_sfixed64: 10\n", a.textFormatString())

        assertTextFormatEncode("optional_sfixed64: 10\n") {(o: inout MessageTestType) in
            o.optionalSfixed64 = 10
        }

        assertTextFormatDecodeFails("optional_sfixed64: a\n")
    }

    private func assertRoundTripText(file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> Void) {
        var original = MessageTestType()
        configure(&original)
        let text = original.textFormatString()
        do {
            let decoded = try MessageTestType(textFormatString: text)
            XCTAssertEqual(original, decoded)
        } catch let e {
            XCTFail("Failed to decode \(e): \(text)", file: file, line: line)
        }
    }

    func testEncoding_optionalFloat() {
        var a = MessageTestType()
        a.optionalFloat = 11

        XCTAssertEqual("optional_float: 11.0\n", a.textFormatString())

        assertTextFormatEncode("optional_float: 11.0\n") {(o: inout MessageTestType) in
            o.optionalFloat = 11
        }
        assertTextFormatDecodeSucceeds("optional_float: 1.0f") {
            (o: MessageTestType) in
            return o.optionalFloat == 1.0
        }
        assertTextFormatDecodeSucceeds("optional_float: 1.5e3") {
            (o: MessageTestType) in
            return o.optionalFloat == 1.5e3
        }
        assertTextFormatDecodeSucceeds("optional_float: -4.75") {
            (o: MessageTestType) in
            return o.optionalFloat == -4.75
        }
        assertTextFormatDecodeSucceeds("optional_float: 1.0f optional_int32: 1") {
            (o: MessageTestType) in
            return o.optionalFloat == 1.0 && o.optionalInt32 == 1
        }
        assertTextFormatDecodeSucceeds("optional_float: 1.0 optional_int32: 1") {
            (o: MessageTestType) in
            return o.optionalFloat == 1.0 && o.optionalInt32 == 1
        }
        assertTextFormatDecodeSucceeds("optional_float: 1.0f\n") {
            (o: MessageTestType) in
            return o.optionalFloat == 1.0
        }
        assertTextFormatDecodeSucceeds("optional_float: 11\n") {
            (o: MessageTestType) in
            return o.optionalFloat == 11.0
        }
        assertTextFormatDecodeSucceeds("optional_float: 11f\n") {
            (o: MessageTestType) in
            return o.optionalFloat == 11.0
        }
        assertTextFormatDecodeSucceeds("optional_float: 0\n") {
            (o: MessageTestType) in
            return o.optionalFloat == 0.0
        }
        assertTextFormatDecodeSucceeds("optional_float: 0f\n") {
            (o: MessageTestType) in
            return o.optionalFloat == 0.0
        }
        assertTextFormatEncode("optional_float: inf\n") {(o: inout MessageTestType) in o.optionalFloat = Float.infinity}
        assertTextFormatEncode("optional_float: -inf\n") {(o: inout MessageTestType) in o.optionalFloat = -Float.infinity}

        // protobuf conformance requires too-large floats to round to Infinity
        assertTextFormatDecodeSucceeds("optional_float: 3.4028235e+39\n") {
            (o: MessageTestType) in
            return o.optionalFloat == Float.infinity
        }
        assertTextFormatDecodeSucceeds("optional_float: -3.4028235e+39\n") {
            (o: MessageTestType) in
            return o.optionalFloat == -Float.infinity
        }
        // Too-small values round to zero (not currently checked by conformance)
        assertTextFormatDecodeSucceeds("optional_float: 1e-50\n") {
            (o: MessageTestType) in
            return o.optionalFloat == 0.0 && o.optionalFloat.sign == .plus
        }
        assertTextFormatDecodeSucceeds("optional_float: -1e-50\n") {
            (o: MessageTestType) in
            return o.optionalFloat == 0.0 && o.optionalFloat.sign == .minus
        }
        // protobuf conformance requires subnormals to be handled
        assertTextFormatDecodeSucceeds("optional_float: 1.17549e-39\n") {
            (o: MessageTestType) in
            return o.optionalFloat == Float(1.17549e-39)
        }
        assertTextFormatDecodeSucceeds("optional_float: -1.17549e-39\n") {
            (o: MessageTestType) in
            return o.optionalFloat == Float(-1.17549e-39)
        }
        // protobuf conformance requires integer forms larger than Int64 to be accepted
        assertTextFormatDecodeSucceeds("optional_float: 18446744073709551616\n") {
            (o: MessageTestType) in
            return o.optionalFloat == 1.84467441e+19
        }
        assertTextFormatDecodeSucceeds("optional_float: -18446744073709551616\n") {
            (o: MessageTestType) in
            return o.optionalFloat == -1.84467441e+19
        }

        let b = Proto3Unittest_TestAllTypes.with {$0.optionalFloat = Float.nan}
        XCTAssertEqual("optional_float: nan\n", b.textFormatString())

        do {
            let nan1 = try Proto3Unittest_TestAllTypes(textFormatString: "optional_float: nan\n")
            XCTAssert(nan1.optionalFloat.isNaN)
        } catch let e {
            XCTFail("Decoding nan failed: \(e)")
        }

        do {
            let nan2 = try Proto3Unittest_TestAllTypes(textFormatString: "optional_float: NaN\n")
            XCTAssert(nan2.optionalFloat.isNaN)
        } catch let e {
            XCTFail("Decoding nan failed: \(e)")
        }

        assertTextFormatDecodeFails("optional_float: nanoptional_int32: 1\n")

        assertTextFormatDecodeSucceeds("optional_float: INFINITY\n") {(o: MessageTestType) in
            return o.optionalFloat == Float.infinity
        }
        assertTextFormatDecodeSucceeds("optional_float: Infinity\n") {(o: MessageTestType) in
            return o.optionalFloat == Float.infinity
        }
        assertTextFormatDecodeSucceeds("optional_float: -INFINITY\n") {(o: MessageTestType) in
            return o.optionalFloat == -Float.infinity
        }
        assertTextFormatDecodeSucceeds("optional_float: -Infinity\n") {(o: MessageTestType) in
            return o.optionalFloat == -Float.infinity
        }
        assertTextFormatDecodeFails("optional_float: INFINITY_AND_BEYOND\n")
        assertTextFormatDecodeFails("optional_float: infinityoptional_int32: 1\n")

        assertTextFormatDecodeFails("optional_float: a\n")
        assertTextFormatDecodeFails("optional_float: 1,2\n")
        assertTextFormatDecodeFails("optional_float: 0xf\n")
        assertTextFormatDecodeFails("optional_float: 012\n")

        // A wide range of numbers should exactly round-trip
        assertRoundTripText {$0.optionalFloat = 0.1}
        assertRoundTripText {$0.optionalFloat = 0.01}
        assertRoundTripText {$0.optionalFloat = 0.001}
        assertRoundTripText {$0.optionalFloat = 0.0001}
        assertRoundTripText {$0.optionalFloat = 0.00001}
        assertRoundTripText {$0.optionalFloat = 0.000001}
        assertRoundTripText {$0.optionalFloat = 1e-10}
        assertRoundTripText {$0.optionalFloat = 1e-20}
        assertRoundTripText {$0.optionalFloat = 1e-30}
        assertRoundTripText {$0.optionalFloat = Float(1e-40)}
        assertRoundTripText {$0.optionalFloat = Float(1e-50)}
        assertRoundTripText {$0.optionalFloat = Float(1e-60)}
        assertRoundTripText {$0.optionalFloat = Float(1e-100)}
        assertRoundTripText {$0.optionalFloat = Float(1e-200)}
        assertRoundTripText {$0.optionalFloat = Float.pi}
        assertRoundTripText {$0.optionalFloat = 123456.789123456789123}
        assertRoundTripText {$0.optionalFloat = 1999.9999999999}
        assertRoundTripText {$0.optionalFloat = 1999.9}
        assertRoundTripText {$0.optionalFloat = 1999.99}
        assertRoundTripText {$0.optionalFloat = 1999.999}
        assertRoundTripText {$0.optionalFloat = 3.402823567e+38}
        assertRoundTripText {$0.optionalFloat = 1.1754944e-38}
    }

    func testEncoding_optionalDouble() {
        var a = MessageTestType()
        a.optionalDouble = 12

        XCTAssertEqual("optional_double: 12.0\n", a.textFormatString())

        assertTextFormatEncode("optional_double: 12.0\n") {(o: inout MessageTestType) in o.optionalDouble = 12 }
        assertTextFormatEncode("optional_double: inf\n") {(o: inout MessageTestType) in o.optionalDouble = Double.infinity}
        assertTextFormatEncode("optional_double: -inf\n") {(o: inout MessageTestType) in o.optionalDouble = -Double.infinity}
        let b = Proto3Unittest_TestAllTypes.with {$0.optionalDouble = Double.nan}
        XCTAssertEqual("optional_double: nan\n", b.textFormatString())

        assertTextFormatDecodeSucceeds("optional_double: 1.0\n") {(o: MessageTestType) in
            return o.optionalDouble == 1.0
        }
        assertTextFormatDecodeSucceeds("optional_double: 1\n") {(o: MessageTestType) in
            return o.optionalDouble == 1.0
        }
        assertTextFormatDecodeSucceeds("optional_double: 0\n") {(o: MessageTestType) in
            return o.optionalDouble == 0.0
        }
        assertTextFormatDecodeSucceeds("12: 1.0\n") {(o: MessageTestType) in
            return o.optionalDouble == 1.0
        }
        assertTextFormatDecodeSucceeds("optional_double: INFINITY\n") {(o: MessageTestType) in
            return o.optionalDouble == Double.infinity
        }
        assertTextFormatDecodeSucceeds("optional_double: Infinity\n") {(o: MessageTestType) in
            return o.optionalDouble == Double.infinity
        }
        assertTextFormatDecodeSucceeds("optional_double: -INFINITY\n") {(o: MessageTestType) in
            return o.optionalDouble == -Double.infinity
        }
        assertTextFormatDecodeSucceeds("optional_double: -Infinity\n") {(o: MessageTestType) in
            return o.optionalDouble == -Double.infinity
        }
        assertTextFormatDecodeFails("optional_double: INFINITY_AND_BEYOND\n")
        assertTextFormatDecodeFails("optional_double: INFIN\n")
        assertTextFormatDecodeFails("optional_double: a\n")
        assertTextFormatDecodeFails("optional_double: 1.2.3\n")
        assertTextFormatDecodeFails("optional_double: 0xf\n")
        assertTextFormatDecodeFails("optional_double: 0123\n")

        // A wide range of numbers should exactly round-trip
        assertRoundTripText {$0.optionalDouble = 0.1}
        assertRoundTripText {$0.optionalDouble = 0.01}
        assertRoundTripText {$0.optionalDouble = 0.001}
        assertRoundTripText {$0.optionalDouble = 0.0001}
        assertRoundTripText {$0.optionalDouble = 0.00001}
        assertRoundTripText {$0.optionalDouble = 0.000001}
        assertRoundTripText {$0.optionalDouble = 1e-10}
        assertRoundTripText {$0.optionalDouble = 1e-20}
        assertRoundTripText {$0.optionalDouble = 1e-30}
        assertRoundTripText {$0.optionalDouble = 1e-40}
        assertRoundTripText {$0.optionalDouble = 1e-50}
        assertRoundTripText {$0.optionalDouble = 1e-60}
        assertRoundTripText {$0.optionalDouble = 1e-100}
        assertRoundTripText {$0.optionalDouble = 1e-200}
        assertRoundTripText {$0.optionalDouble = Double.pi}
        assertRoundTripText {$0.optionalDouble = 123456.789123456789123}
        assertRoundTripText {$0.optionalDouble = 1.7976931348623157e+308}
        assertRoundTripText {$0.optionalDouble = 2.22507385850720138309e-308}
    }

    func testEncoding_optionalBool() {
        var a = MessageTestType()
        a.optionalBool = true
        XCTAssertEqual("optional_bool: true\n", a.textFormatString())

        a.optionalBool = false
        XCTAssertEqual("", a.textFormatString())

        assertTextFormatEncode("optional_bool: true\n") {(o: inout MessageTestType) in
            o.optionalBool = true
        }
        assertTextFormatDecodeSucceeds("optional_bool:true") {(o: MessageTestType) in
            return o.optionalBool == true
        }
        assertTextFormatDecodeSucceeds("optional_bool:true ") {(o: MessageTestType) in
            return o.optionalBool == true
        }
        assertTextFormatDecodeSucceeds("optional_bool:true\n ") {(o: MessageTestType) in
            return o.optionalBool == true
        }
        assertTextFormatDecodeSucceeds("optional_bool:True\n ") {(o: MessageTestType) in
            return o.optionalBool == true
        }
        assertTextFormatDecodeSucceeds("optional_bool:t\n ") {(o: MessageTestType) in
            return o.optionalBool == true
        }
        assertTextFormatDecodeSucceeds("optional_bool:1\n ") {(o: MessageTestType) in
            return o.optionalBool == true
        }
        assertTextFormatDecodeSucceeds("optional_bool:false\n ") {(o: MessageTestType) in
            return o.optionalBool == false
        }
        assertTextFormatDecodeSucceeds("optional_bool:False\n ") {(o: MessageTestType) in
            return o.optionalBool == false
        }
        assertTextFormatDecodeSucceeds("optional_bool:f\n ") {(o: MessageTestType) in
            return o.optionalBool == false
        }
        assertTextFormatDecodeSucceeds("optional_bool:0\n ") {(o: MessageTestType) in
            return o.optionalBool == false
        }
        assertTextFormatDecodeSucceeds("13:0\n ") {(o: MessageTestType) in
            return o.optionalBool == false
        }
        assertTextFormatDecodeSucceeds("13:1\n ") {(o: MessageTestType) in
            return o.optionalBool == true
        }

        assertTextFormatDecodeFails("optional_bool: 10\n")
        assertTextFormatDecodeFails("optional_bool: 1optional_double: 1.0\n")
        assertTextFormatDecodeFails("optional_bool: t12: 1.0\n")
        assertTextFormatDecodeFails("optional_bool: true12: 1.0\n")
        assertTextFormatDecodeFails("optional_bool: tRue\n")
        assertTextFormatDecodeFails("optional_bool: tr\n")
        assertTextFormatDecodeFails("optional_bool: tru\n")
        assertTextFormatDecodeFails("optional_bool: truE\n")
        assertTextFormatDecodeFails("optional_bool: TRUE\n")
        assertTextFormatDecodeFails("optional_bool: faLse\n")
        assertTextFormatDecodeFails("optional_bool: 2\n")
        assertTextFormatDecodeFails("optional_bool: -0\n")
        assertTextFormatDecodeFails("optional_bool: on\n")
        assertTextFormatDecodeFails("optional_bool: a\n")
    }

    // TODO: Need to verify the behavior here with extended Unicode text
    // and UTF-8 encoded by C++ implementation
    func testEncoding_optionalString() {
        var a = MessageTestType()
        a.optionalString = "abc"

        XCTAssertEqual("optional_string: \"abc\"\n", a.textFormatString())

        assertTextFormatEncode("optional_string: \" !\\\"#$%&'\"\n") {
            (o: inout MessageTestType) in
            o.optionalString = "\u{20}\u{21}\u{22}\u{23}\u{24}\u{25}\u{26}\u{27}"
        }

        assertTextFormatEncode("optional_string: \"XYZ[\\\\]^_\"\n") {
            (o: inout MessageTestType) in
            o.optionalString = "\u{58}\u{59}\u{5a}\u{5b}\u{5c}\u{5d}\u{5e}\u{5f}"
        }

        assertTextFormatEncode("optional_string: \"xyz{|}~\\177\"\n") {
            (o: inout MessageTestType) in
            o.optionalString = "\u{78}\u{79}\u{7a}\u{7b}\u{7c}\u{7d}\u{7e}\u{7f}"
        }
        assertTextFormatEncode("optional_string: \"\u{80}\u{81}\u{82}\u{83}\u{84}\u{85}\"\n") {
            (o: inout MessageTestType) in
            o.optionalString = "\u{80}\u{81}\u{82}\u{83}\u{84}\u{85}"
        }
        assertTextFormatEncode("optional_string: \"øùúûüýþÿ\"\n") {
            (o: inout MessageTestType) in
            o.optionalString = "\u{f8}\u{f9}\u{fa}\u{fb}\u{fc}\u{fd}\u{fe}\u{ff}"
        }


        // Adjacent quoted strings concatenate, see
        //   google/protobuf/text_format_unittest.cc#L597
        assertTextFormatDecodeSucceeds("optional_string: \"abc\"\"def\"") {
            (o: MessageTestType) in
            return o.optionalString == "abcdef"
        }
        assertTextFormatDecodeSucceeds("optional_string: \"abc\" \"def\"") {
            (o: MessageTestType) in
            return o.optionalString == "abcdef"
        }
        assertTextFormatDecodeSucceeds("optional_string: \"abc\"   \"def\"") {
            (o: MessageTestType) in
            return o.optionalString == "abcdef"
        }
        // Adjacent quoted strings concatenate across multiple lines
        assertTextFormatDecodeSucceeds("optional_string: \"abc\"\n\"def\"") {
            (o: MessageTestType) in
            return o.optionalString == "abcdef"
        }
        assertTextFormatDecodeSucceeds("optional_string: \"abc\"\n      \t   \"def\"\n\"ghi\"\n") {
            (o: MessageTestType) in
            return o.optionalString == "abcdefghi"
        }
        assertTextFormatDecodeSucceeds("optional_string: \"abc\"\n\'def\'\n\"ghi\"\n") {
            (o: MessageTestType) in
            return o.optionalString == "abcdefghi"
        }
        assertTextFormatDecodeSucceeds("optional_string: \"abcdefghi\"") {
            (o: MessageTestType) in
            return o.optionalString == "abcdefghi"
        }
        // Note: Values 0-127 are same whether viewed as Unicode code
        // points or UTF-8 bytes.
        assertTextFormatDecodeSucceeds("optional_string: \"\\a\\b\\f\\n\\r\\t\\v\\\"\\'\\\\\\?\"") {
            (o: MessageTestType) in
            return o.optionalString == "\u{07}\u{08}\u{0C}\u{0A}\u{0D}\u{09}\u{0B}\"'\\?"
        }
        assertTextFormatDecodeFails("optional_string: \"\\z\"")
        assertTextFormatDecodeSucceeds("optional_string: \"\\001\\01\\1\\0011\\010\\289\"") {
            (o: MessageTestType) in
            return o.optionalString == "\u{01}\u{01}\u{01}\u{01}\u{31}\u{08}\u{02}89"
        }
        assertTextFormatDecodeSucceeds("optional_string: \"\\x1\\x12\\x123\\x1234\"") {
            (o: MessageTestType) in
            return o.optionalString == "\u{01}\u{12}\u{12}3\u{12}34"
        }
        assertTextFormatDecodeSucceeds("optional_string: \"\\x0f\\x3g\"") {
            (o: MessageTestType) in
            return o.optionalString == "\u{0f}\u{03}g"
        }
        assertTextFormatEncode("optional_string: \"abc\"\n") {(o: inout MessageTestType) in
            o.optionalString = "abc"
        }
        assertTextFormatDecodeFails("optional_string:hello")
        assertTextFormatDecodeFails("optional_string: \"hello\'")
        assertTextFormatDecodeFails("optional_string: \'hello\"")
        assertTextFormatDecodeFails("optional_string: \"hello")
    }

    func testEncoding_optionalString_controlCharacters() throws {
        // This is known to fail on Swift Linux 4.1 and earlier,
        // so skip it there.
        // See https://bugs.swift.org/browse/SR-4218 for details.
#if !os(Linux) || swift(>=4.2)
        assertTextFormatEncode("optional_string: \"\\001\\002\\003\\004\\005\\006\\007\"\n") {
            (o: inout MessageTestType) in
            o.optionalString = "\u{01}\u{02}\u{03}\u{04}\u{05}\u{06}\u{07}"
        }
        assertTextFormatEncode("optional_string: \"\\b\\t\\n\\v\\f\\r\\016\\017\"\n") {
            (o: inout MessageTestType) in
            o.optionalString = "\u{08}\u{09}\u{0a}\u{0b}\u{0c}\u{0d}\u{0e}\u{0f}"
        }
        assertTextFormatEncode("optional_string: \"\\020\\021\\022\\023\\024\\025\\026\\027\"\n") {
            (o: inout MessageTestType) in
            o.optionalString = "\u{10}\u{11}\u{12}\u{13}\u{14}\u{15}\u{16}\u{17}"
        }
        assertTextFormatEncode("optional_string: \"\\030\\031\\032\\033\\034\\035\\036\\037\"\n") {
            (o: inout MessageTestType) in
            o.optionalString = "\u{18}\u{19}\u{1a}\u{1b}\u{1c}\u{1d}\u{1e}\u{1f}"
        }
#endif
    }

    func testEncoding_optionalString_UTF8() throws {
        // We encode to/from a string, not a sequence of bytes, so valid
        // Unicode characters just get preserved on both encode and decode:
        assertTextFormatEncode("optional_string: \"☞\"\n") {(o: inout MessageTestType) in
            o.optionalString = "☞"
        }
        // Other encoders write each byte of a UTF-8 sequence, maybe in hex:
        assertTextFormatDecodeSucceeds("optional_string: \"\\xE2\\x98\\x9E\"") {(o: MessageTestType) in
            return o.optionalString == "☞"
        }
        // Or maybe in octal:
        assertTextFormatDecodeSucceeds("optional_string: \"\\342\\230\\236\"") {(o: MessageTestType) in
            return o.optionalString == "☞"
        }
        // Each string piece is decoded separately, broken UTF-8 is an error
        assertTextFormatDecodeFails("optional_string: \"\\342\\230\" \"\\236\"")
    }

    func testEncoding_optionalBytes() throws {
        let o = Proto3Unittest_TestAllTypes.with { $0.optionalBytes = Data() }
        XCTAssertEqual("", o.textFormatString())

        assertTextFormatEncode("optional_bytes: \"AB\"\n") {(o: inout MessageTestType) in
            o.optionalBytes = Data([65, 66])
        }
        assertTextFormatEncode("optional_bytes: \"\\000\\001AB\\177\\200\\377\"\n") {(o: inout MessageTestType) in
            o.optionalBytes = Data([0, 1, 65, 66, 127, 128, 255])
        }
        assertTextFormatEncode("optional_bytes: \"\\b\\t\\n\\v\\f\\r\\\"'?\\\\\"\n") {(o: inout MessageTestType) in
            o.optionalBytes = Data([8, 9, 10, 11, 12, 13, 34, 39, 63, 92])
        }
        assertTextFormatDecodeSucceeds("optional_bytes: \"A\" \"B\"\n") {(o: MessageTestType) in
            return o.optionalBytes == Data([65, 66])
        }
        assertTextFormatDecodeSucceeds("optional_bytes: \"\\0\\1AB\\178\\189\\x61\\xdq\\x123456789\"\n") {(o: MessageTestType) in
            return o.optionalBytes == Data([0, 1, 65, 66, 15, 56, 1, 56, 57, 97, 13, 113, 18, 51, 52, 53, 54, 55, 56, 57])
        }
        // "\1" followed by "2", not "\12"
        assertTextFormatDecodeSucceeds("optional_bytes: \"\\1\" \"2\"") {(o: MessageTestType) in
            return o.optionalBytes == Data([1, 50]) // Not [10]
        }
        // "\x6" followed by "2", not "\x62"
        assertTextFormatDecodeSucceeds("optional_bytes: \"\\x6\" \"2\"") {(o: MessageTestType) in
            return o.optionalBytes == Data([6, 50]) // Not [98]
        }
        assertTextFormatDecodeSucceeds("optional_bytes: \"\"\n") {(o: MessageTestType) in
            return o.optionalBytes == Data()
        }
        assertTextFormatDecodeSucceeds("optional_bytes: \"\\b\\t\\n\\v\\f\\r\\\"\\'\\?'\"\n") {(o: MessageTestType) in
            return o.optionalBytes == Data([8, 9, 10, 11, 12, 13, 34, 39, 63, 39])
        }

        assertTextFormatDecodeFails("optional_bytes: 10\n")
        assertTextFormatDecodeFails("optional_bytes: \"\\\"\n")
        assertTextFormatDecodeFails("optional_bytes: \"\\x\"\n")
        assertTextFormatDecodeFails("optional_bytes: \"\\x&\"\n")
        assertTextFormatDecodeFails("optional_bytes: \"\\xg\"\n")
        assertTextFormatDecodeFails("optional_bytes: \"\\q\"\n")
        assertTextFormatDecodeFails("optional_bytes: \"\\777\"\n") // Out-of-range octal
        assertTextFormatDecodeFails("optional_bytes: \"")
        assertTextFormatDecodeFails("optional_bytes: \"abcde")
        assertTextFormatDecodeFails("optional_bytes: \"\\")
        assertTextFormatDecodeFails("optional_bytes: \"\\3")
        assertTextFormatDecodeFails("optional_bytes: \"\\32")
        assertTextFormatDecodeFails("optional_bytes: \"\\232")
        assertTextFormatDecodeFails("optional_bytes: \"\\x")
        assertTextFormatDecodeFails("optional_bytes: \"\\x1")
        assertTextFormatDecodeFails("optional_bytes: \"\\x12")
        assertTextFormatDecodeFails("optional_bytes: \"\\x12q")
    }

    func testEncoding_optionalBytes_roundtrip() throws {
        for i in UInt8(0)...UInt8(255) {
            let d = Data([i])
            let message = Proto3Unittest_TestAllTypes.with { $0.optionalBytes = d }
            let text = message.textFormatString()
            let decoded = try Proto3Unittest_TestAllTypes(textFormatString: text)
            XCTAssertEqual(decoded, message)
            XCTAssertEqual(message.optionalBytes[0], i)
        }
    }

    func testEncoding_optionalNestedMessage() {
        var nested = MessageTestType.NestedMessage()
        nested.bb = 7

        var a = MessageTestType()
        a.optionalNestedMessage = nested

        XCTAssertEqual("optional_nested_message {\n  bb: 7\n}\n", a.textFormatString())

        assertTextFormatEncode("optional_nested_message {\n  bb: 7\n}\n") {(o: inout MessageTestType) in
            o.optionalNestedMessage = nested
        }
        // Google permits reading a message field with or without the separating ':'
        assertTextFormatDecodeSucceeds("optional_nested_message: {bb:7}") {(o: MessageTestType) in
            return o.optionalNestedMessage.bb == 7
        }
        // Messages can be wrapped in {...} or <...>
        assertTextFormatDecodeSucceeds("optional_nested_message <bb:7>") {(o: MessageTestType) in
            return o.optionalNestedMessage.bb == 7
        }
        // Google permits reading a message field with or without the separating ':'
        assertTextFormatDecodeSucceeds("optional_nested_message: <bb:7>") {(o: MessageTestType) in
            return o.optionalNestedMessage.bb == 7
        }

        assertTextFormatDecodeFails("optional_nested_message: a\n")
    }

    func testEncoding_optionalForeignMessage() {
        var foreign = Proto3Unittest_ForeignMessage()
        foreign.c = 88

        var a = MessageTestType()
        a.optionalForeignMessage = foreign

        XCTAssertEqual("optional_foreign_message {\n  c: 88\n}\n", a.textFormatString())

        assertTextFormatEncode("optional_foreign_message {\n  c: 88\n}\n") {(o: inout MessageTestType) in o.optionalForeignMessage = foreign }

        do {
            let message = try MessageTestType(textFormatString:"optional_foreign_message: {\n  c: 88\n}\n")
            XCTAssertEqual(message.optionalForeignMessage.c, 88)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextFormatDecodeFails("optional_foreign_message: a\n")
    }

    func testEncoding_optionalImportMessage() {
        var importMessage = ProtobufUnittestImport_ImportMessage()
        importMessage.d = -9

        var a = MessageTestType()
        a.optionalImportMessage = importMessage

        XCTAssertEqual("optional_import_message {\n  d: -9\n}\n", a.textFormatString())

        assertTextFormatEncode("optional_import_message {\n  d: -9\n}\n") {(o: inout MessageTestType) in o.optionalImportMessage = importMessage }

        do {
            let message = try MessageTestType(textFormatString:"optional_import_message: {\n  d: -9\n}\n")
            XCTAssertEqual(message.optionalImportMessage.d, -9)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextFormatDecodeFails("optional_import_message: a\n")
    }

    func testEncoding_optionalNestedEnum() throws {
        var a = MessageTestType()
        a.optionalNestedEnum = .baz

        XCTAssertEqual("optional_nested_enum: BAZ\n", a.textFormatString())

        assertTextFormatEncode("optional_nested_enum: BAZ\n") {(o: inout MessageTestType) in
            o.optionalNestedEnum = .baz
        }
        assertTextFormatDecodeSucceeds("optional_nested_enum:BAZ"){(o: MessageTestType) in
            return o.optionalNestedEnum == .baz
        }
        assertTextFormatDecodeSucceeds("optional_nested_enum:1"){(o: MessageTestType) in
            return o.optionalNestedEnum == .foo
        }
        assertTextFormatDecodeSucceeds("optional_nested_enum:2"){(o: MessageTestType) in
            return o.optionalNestedEnum == .bar
        }
        assertTextFormatDecodeFails("optional_nested_enum: a\n")
        assertTextFormatDecodeFails("optional_nested_enum: FOOBAR")
        assertTextFormatDecodeFails("optional_nested_enum: \"BAR\"\n")

        // Note: This implementation currently preserves numeric unknown
        // enum values, unlike Google's C++ implementation, which considers
        // it a parse error.
        let b = try Proto3Unittest_TestAllTypes(textFormatString: "optional_nested_enum: 999\n")
        XCTAssertEqual("optional_nested_enum: 999\n", b.textFormatString())
    }

    func testEncoding_optionalForeignEnum() {
        var a = MessageTestType()
        a.optionalForeignEnum = .foreignBaz

        XCTAssertEqual("optional_foreign_enum: FOREIGN_BAZ\n", a.textFormatString())

        assertTextFormatEncode("optional_foreign_enum: FOREIGN_BAZ\n") {(o: inout MessageTestType) in o.optionalForeignEnum = .foreignBaz }
        assertTextFormatDecodeSucceeds("optional_foreign_enum: 6\n") {(o: MessageTestType) in o.optionalForeignEnum == .foreignBaz }

        assertTextFormatEncode("optional_foreign_enum: 99\n") {(o: inout MessageTestType) in o.optionalForeignEnum = .UNRECOGNIZED(99) }

        assertTextFormatDecodeFails("optional_foreign_enum: a\n")
    }

    func testEncoding_optionalPublicImportMessage() {
        var publicImportMessage = ProtobufUnittestImport_PublicImportMessage()
        publicImportMessage.e = -999999

        var a = MessageTestType()
        a.optionalPublicImportMessage = publicImportMessage

        XCTAssertEqual("optional_public_import_message {\n  e: -999999\n}\n", a.textFormatString())

        assertTextFormatEncode("optional_public_import_message {\n  e: -999999\n}\n") {(o: inout MessageTestType) in o.optionalPublicImportMessage = publicImportMessage }

        do {
            let message = try MessageTestType(textFormatString:"optional_public_import_message: {\n  e: -999999\n}\n")
            XCTAssertEqual(message.optionalPublicImportMessage.e, -999999)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextFormatDecodeFails("optional_public_import_message: a\n")
    }

    //
    // Repeated types
    //

    func testEncoding_repeatedInt32() {
        var a = MessageTestType()
        a.repeatedInt32 = [1, 2]
        XCTAssertEqual("repeated_int32: [1, 2]\n", a.textFormatString())

        assertTextFormatEncode("repeated_int32: [1, 2]\n") {(o: inout MessageTestType) in
            o.repeatedInt32 = [1, 2]
        }

        assertTextFormatDecodeSucceeds("repeated_int32: 1\n repeated_int32: 2\n") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }
        assertTextFormatDecodeSucceeds("repeated_int32:[1, 2]") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }
        assertTextFormatDecodeSucceeds("repeated_int32: [1] repeated_int32: 2\n") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }
        assertTextFormatDecodeSucceeds("repeated_int32: 1 repeated_int32: [2]\n") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }
        assertTextFormatDecodeSucceeds("repeated_int32:[]\nrepeated_int32: [1, 2]\nrepeated_int32:[]\n") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }
        assertTextFormatDecodeSucceeds("repeated_int32:1\nrepeated_int32:2\n") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }

        assertTextFormatDecodeFails("repeated_int32: 1\nrepeated_int32: a\n")
        assertTextFormatDecodeFails("repeated_int32: [")
        assertTextFormatDecodeFails("repeated_int32: [\n")
        assertTextFormatDecodeFails("repeated_int32: [,]\n")
        assertTextFormatDecodeFails("repeated_int32: [1\n")
        assertTextFormatDecodeFails("repeated_int32: [1,\n")
        assertTextFormatDecodeFails("repeated_int32: [1,]\n")
        assertTextFormatDecodeFails("repeated_int32: [1,2\n")
        assertTextFormatDecodeFails("repeated_int32: [1,2,]\n")
    }

    func testEncoding_repeatedInt64() {
        assertTextFormatEncode("repeated_int64: [3, 4]\n") {(o: inout MessageTestType) in
            o.repeatedInt64 = [3, 4]
        }

        assertTextFormatDecodeSucceeds("repeated_int64: 3\nrepeated_int64: 4\n") {(o: MessageTestType) in
            return o.repeatedInt64 == [3, 4]
        }
        assertTextFormatDecodeFails("repeated_int64: 3\nrepeated_int64: a\n")
    }

    func testEncoding_repeatedUint32() {
        assertTextFormatEncode("repeated_uint32: [5, 6]\n") {(o: inout MessageTestType) in
            o.repeatedUint32 = [5, 6]
        }

        assertTextFormatDecodeFails("repeated_uint32: 5\nrepeated_uint32: a\n")
    }

    func testEncoding_repeatedUint64() {
        assertTextFormatEncode("repeated_uint64: [7, 8]\n") {(o: inout MessageTestType) in
            o.repeatedUint64 = [7, 8]
        }

        assertTextFormatDecodeSucceeds("repeated_uint64: 7\nrepeated_uint64: 8\n") {
            $0.repeatedUint64 == [7, 8]
        }

        assertTextFormatDecodeFails("repeated_uint64: 7\nrepeated_uint64: a\n")
    }

    func testEncoding_repeatedSint32() {
        assertTextFormatEncode("repeated_sint32: [9, 10]\n") {(o: inout MessageTestType) in
            o.repeatedSint32 = [9, 10]
        }

        assertTextFormatDecodeFails("repeated_sint32: 9\nrepeated_sint32: a\n")
    }

    func testEncoding_repeatedSint64() {
        assertTextFormatEncode("repeated_sint64: [11, 12]\n") {(o: inout MessageTestType) in
            o.repeatedSint64 = [11, 12]
        }

        assertTextFormatDecodeFails("repeated_sint64: 11\nrepeated_sint64: a\n")
    }

    func testEncoding_repeatedFixed32() {
        assertTextFormatEncode("repeated_fixed32: [13, 14]\n") {(o: inout MessageTestType) in
            o.repeatedFixed32 = [13, 14]
        }

        assertTextFormatDecodeFails("repeated_fixed32: 13\nrepeated_fixed32: a\n")
    }

    func testEncoding_repeatedFixed64() {
        assertTextFormatEncode("repeated_fixed64: [15, 16]\n") {(o: inout MessageTestType) in
            o.repeatedFixed64 = [15, 16]
        }

        assertTextFormatDecodeFails("repeated_fixed64: 15\nrepeated_fixed64: a\n")
    }

    func testEncoding_repeatedSfixed32() {
        assertTextFormatEncode("repeated_sfixed32: [17, 18]\n") {(o: inout MessageTestType) in
            o.repeatedSfixed32 = [17, 18]
        }

        assertTextFormatDecodeFails("repeated_sfixed32: 17\nrepeated_sfixed32: a\n")
    }

    func testEncoding_repeatedSfixed64() {
        assertTextFormatEncode("repeated_sfixed64: [19, 20]\n") {(o: inout MessageTestType) in
            o.repeatedSfixed64 = [19, 20]
        }

        assertTextFormatDecodeFails("repeated_sfixed64: 19\nrepeated_sfixed64: a\n")
    }

    func testEncoding_repeatedFloat() {
        assertTextFormatEncode("repeated_float: [21.0, 22.0]\n") {(o: inout MessageTestType) in
            o.repeatedFloat = [21, 22]
        }

        assertTextFormatDecodeFails("repeated_float: 21\nrepeated_float: a\n")
    }

    func testEncoding_repeatedDouble() {
        assertTextFormatEncode("repeated_double: [23.0, 24.0]\n") {(o: inout MessageTestType) in
            o.repeatedDouble = [23, 24]
        }
        assertTextFormatEncode("repeated_double: [2.25, 2.5]\n") {(o: inout MessageTestType) in
            o.repeatedDouble = [2.25, 2.5]
        }

        assertTextFormatDecodeFails("repeated_double: 23\nrepeated_double: a\n")
    }

    func testEncoding_repeatedBool() {
        assertTextFormatEncode("repeated_bool: [true, false]\n") {(o: inout MessageTestType) in
            o.repeatedBool = [true, false]
        }
        assertTextFormatDecodeSucceeds("repeated_bool: [true, false, True, False, t, f, 1, 0]") {
            (o: MessageTestType) in
            return o.repeatedBool == [true, false, true, false, true, false, true, false]
        }

        assertTextFormatDecodeFails("repeated_bool: true\nrepeated_bool: a\n")
    }

    func testEncoding_repeatedString() {
        assertTextFormatDecodeSucceeds("repeated_string: \"abc\"\nrepeated_string: \"def\"\n") {
            (o: MessageTestType) in
            return o.repeatedString == ["abc", "def"]
        }
        assertTextFormatDecodeSucceeds("repeated_string: \"a\" \"bc\"\nrepeated_string: 'd' \"e\" \"f\"\n") {
            (o: MessageTestType) in
            return o.repeatedString == ["abc", "def"]
        }
        assertTextFormatDecodeSucceeds("repeated_string:[\"abc\", \"def\"]") {
            (o: MessageTestType) in
            return o.repeatedString == ["abc", "def"]
        }
        assertTextFormatDecodeSucceeds("repeated_string:[\"a\"\"bc\", \"d\" 'e' \"f\"]") {
            (o: MessageTestType) in
            return o.repeatedString == ["abc", "def"]
        }
        assertTextFormatDecodeSucceeds("repeated_string:[\"abc\", 'def']") {
            (o: MessageTestType) in
            return o.repeatedString == ["abc", "def"]
        }
        assertTextFormatDecodeSucceeds("repeated_string:[\"abc\"] repeated_string: \"def\"") {
            (o: MessageTestType) in
            return o.repeatedString == ["abc", "def"]
        }
        assertTextFormatDecodeFails("repeated_string:[\"abc\", \"def\",]")
        assertTextFormatDecodeFails("repeated_string:[\"abc\"")
        assertTextFormatDecodeFails("repeated_string:[\"abc\",")
        assertTextFormatDecodeFails("repeated_string:[\"abc\",]")
        assertTextFormatDecodeFails("repeated_string: \"abc\"]")
        assertTextFormatDecodeFails("repeated_string: abc")

        assertTextFormatEncode("repeated_string: \"abc\"\nrepeated_string: \"def\"\n") {(o: inout MessageTestType) in o.repeatedString = ["abc", "def"] }
    }

    func testEncoding_repeatedBytes() {
        var a = MessageTestType()
        a.repeatedBytes = [Data(), Data([65, 66])]
        XCTAssertEqual("repeated_bytes: \"\"\nrepeated_bytes: \"AB\"\n", a.textFormatString())

        assertTextFormatEncode("repeated_bytes: \"\"\nrepeated_bytes: \"AB\"\n") {(o: inout MessageTestType) in
            o.repeatedBytes = [Data(), Data([65, 66])]
        }
        assertTextFormatDecodeSucceeds("repeated_bytes: \"\"\nrepeated_bytes: \"A\" \"B\"\n") {(o: MessageTestType) in
            return o.repeatedBytes == [Data(), Data([65, 66])]
        }
        assertTextFormatDecodeSucceeds("repeated_bytes: [\"\", \"AB\"]\n") {(o: MessageTestType) in
            return o.repeatedBytes == [Data(), Data([65, 66])]
        }
        assertTextFormatDecodeSucceeds("repeated_bytes: [\"\", \"A\" \"B\"]\n") {(o: MessageTestType) in
            return o.repeatedBytes == [Data(), Data([65, 66])]
        }
    }

    func testEncoding_repeatedNestedMessage() {
        var nested = MessageTestType.NestedMessage()
        nested.bb = 7

        var nested2 = nested
        nested2.bb = -7

        var a = MessageTestType()
        a.repeatedNestedMessage = [nested, nested2]

        XCTAssertEqual("repeated_nested_message {\n  bb: 7\n}\nrepeated_nested_message {\n  bb: -7\n}\n", a.textFormatString())

        assertTextFormatEncode("repeated_nested_message {\n  bb: 7\n}\nrepeated_nested_message {\n  bb: -7\n}\n") {(o: inout MessageTestType) in o.repeatedNestedMessage = [nested, nested2] }

        assertTextFormatDecodeSucceeds("repeated_nested_message: {\n bb: 7\n}\nrepeated_nested_message: {\n  bb: -7\n}\n") {
            (o: MessageTestType) in
            return o.repeatedNestedMessage == [
                MessageTestType.NestedMessage.with {$0.bb = 7},
                MessageTestType.NestedMessage.with {$0.bb = -7}
            ]
        }
        assertTextFormatDecodeSucceeds("repeated_nested_message:[{bb: 7}, {bb: -7}]") {
            (o: MessageTestType) in
            return o.repeatedNestedMessage == [
                MessageTestType.NestedMessage.with {$0.bb = 7},
                MessageTestType.NestedMessage.with {$0.bb = -7}
            ]
        }

        assertTextFormatDecodeFails("repeated_nested_message {\n  bb: 7\n}\nrepeated_nested_message {\n  bb: a\n}\n")
    }

    func testEncoding_repeatedForeignMessage() {
        var foreign = Proto3Unittest_ForeignMessage()
        foreign.c = 88

        var foreign2 = foreign
        foreign2.c = -88

        var a = MessageTestType()
        a.repeatedForeignMessage = [foreign, foreign2]

        XCTAssertEqual("repeated_foreign_message {\n  c: 88\n}\nrepeated_foreign_message {\n  c: -88\n}\n", a.textFormatString())

        assertTextFormatEncode("repeated_foreign_message {\n  c: 88\n}\nrepeated_foreign_message {\n  c: -88\n}\n") {(o: inout MessageTestType) in o.repeatedForeignMessage = [foreign, foreign2] }

        do {
            let message = try MessageTestType(textFormatString:"repeated_foreign_message: {\n  c: 88\n}\nrepeated_foreign_message: {\n  c: -88\n}\n")
            XCTAssertEqual(message.repeatedForeignMessage[0].c, 88)
            XCTAssertEqual(message.repeatedForeignMessage[1].c, -88)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextFormatDecodeFails("repeated_foreign_message {\n  c: 88\n}\nrepeated_foreign_message {\n  c: a\n}\n")
    }


    func testEncoding_repeatedImportMessage() {
        var importMessage = ProtobufUnittestImport_ImportMessage()
        importMessage.d = -9

        var importMessage2 = importMessage
        importMessage2.d = 999999

        var a = MessageTestType()
        a.repeatedImportMessage = [importMessage, importMessage2]

        XCTAssertEqual("repeated_import_message {\n  d: -9\n}\nrepeated_import_message {\n  d: 999999\n}\n", a.textFormatString())

        assertTextFormatEncode("repeated_import_message {\n  d: -9\n}\nrepeated_import_message {\n  d: 999999\n}\n") {(o: inout MessageTestType) in o.repeatedImportMessage = [importMessage, importMessage2] }

        do {
            let message = try MessageTestType(textFormatString:"repeated_import_message: {\n  d: -9\n}\nrepeated_import_message: {\n  d: 999999\n}\n")
            XCTAssertEqual(message.repeatedImportMessage[0].d, -9)
            XCTAssertEqual(message.repeatedImportMessage[1].d, 999999)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextFormatDecodeFails("repeated_import_message {\n  d: -9\n}\nrepeated_import_message {\n  d: a\n}\n")
    }

    func testEncoding_repeatedNestedEnum() {
        assertTextFormatEncode("repeated_nested_enum: [BAR, BAZ]\n") {(o: inout MessageTestType) in
            o.repeatedNestedEnum = [.bar, .baz]
        }

        assertTextFormatDecodeSucceeds("repeated_nested_enum: BAR repeated_nested_enum: BAZ") {
            (o: MessageTestType) in
            return o.repeatedNestedEnum == [.bar, .baz]
        }

        assertTextFormatDecodeSucceeds("repeated_nested_enum: [2, BAZ]") {
            (o: MessageTestType) in
            return o.repeatedNestedEnum == [.bar, .baz]
        }
        assertTextFormatDecodeSucceeds("repeated_nested_enum: [] repeated_nested_enum: [2] repeated_nested_enum: [BAZ] repeated_nested_enum: []") {
            (o: MessageTestType) in
            return o.repeatedNestedEnum == [.bar, .baz]
        }

        assertTextFormatDecodeFails("repeated_nested_enum: BAR\nrepeated_nested_enum: a\n")
    }

    func testEncoding_repeatedForeignEnum() {
        assertTextFormatEncode("repeated_foreign_enum: [FOREIGN_BAR, FOREIGN_BAZ]\n") {(o: inout MessageTestType) in
            o.repeatedForeignEnum = [.foreignBar, .foreignBaz]
        }

        assertTextFormatDecodeSucceeds("repeated_foreign_enum: [5, 6]\n") {(o: MessageTestType) in
            o.repeatedForeignEnum == [.foreignBar, .foreignBaz]
        }

        assertTextFormatEncode("repeated_foreign_enum: [123, 321]\n") {(o: inout MessageTestType) in
            o.repeatedForeignEnum = [.UNRECOGNIZED(123), .UNRECOGNIZED(321)]
        }

        assertTextFormatDecodeFails("repeated_foreign_enum: FOREIGN_BAR\nrepeated_foreign_enum: a\n")
    }


    func testEncoding_oneofUint32() {
        var a = MessageTestType()
        a.oneofUint32 = 99

        XCTAssertEqual("oneof_uint32: 99\n", a.textFormatString())

        assertTextFormatEncode("oneof_uint32: 99\n") {(o: inout MessageTestType) in o.oneofUint32 = 99 }

        assertTextFormatDecodeFails("oneof_uint32: a\n")
    }

    //
    // Various odd cases...
    //
    func testInvalidToken() {
        assertTextFormatDecodeFails("optional_bool: true\n-5\n")
        assertTextFormatDecodeFails("optional_bool: true!\n")
        assertTextFormatDecodeFails("\"optional_bool\": true\n")
    }

    func testInvalidFieldName() {
        assertTextFormatDecodeFails("invalid_field: value\n")
    }

    func testInvalidCapitalization() {
        assertTextFormatDecodeFails("optionalgroup {\na: 15\n}\n")
        assertTextFormatDecodeFails("OPTIONALgroup {\na: 15\n}\n")
        assertTextFormatDecodeFails("Optional_Bool: true\n")
    }

    func testExplicitDelimiters() {
        assertTextFormatDecodeSucceeds("optional_int32:1,optional_int64:3;optional_uint32:4") {(o: MessageTestType) in
            return o.optionalInt32 == 1 && o.optionalInt64 == 3 && o.optionalUint32 == 4
        }
        assertTextFormatDecodeSucceeds("optional_int32:1,\n") {(o: MessageTestType) in
            return o.optionalInt32 == 1
        }
        assertTextFormatDecodeSucceeds("optional_int32:1;\n") {(o: MessageTestType) in
            return o.optionalInt32 == 1
        }
    }

    //
    // Multiple fields at once
    //

    private func configureLargeObject(_ o: inout MessageTestType) {
        o.optionalInt32 = 1
        o.optionalInt64 = 2
        o.optionalUint32 = 3
        o.optionalUint64 = 4
        o.optionalSint32 = 5
        o.optionalSint64 = 6
        o.optionalFixed32 = 7
        o.optionalFixed64 = 8
        o.optionalSfixed32 = 9
        o.optionalSfixed64 = 10
        o.optionalFloat = 11
        o.optionalDouble = 12
        o.optionalBool = true
        o.optionalString = "abc"
        o.optionalBytes = Data([65, 66])
        var nested = MessageTestType.NestedMessage()
        nested.bb = 7
        o.optionalNestedMessage = nested
        var foreign = Proto3Unittest_ForeignMessage()
        foreign.c = 88
        o.optionalForeignMessage = foreign
        var importMessage = ProtobufUnittestImport_ImportMessage()
        importMessage.d = -9
        o.optionalImportMessage = importMessage
        o.optionalNestedEnum = .baz
        o.optionalForeignEnum = .foreignBaz
        var publicImportMessage = ProtobufUnittestImport_PublicImportMessage()
        publicImportMessage.e = -999999
        o.optionalPublicImportMessage = publicImportMessage
        o.repeatedInt32 = [1, 2]
        o.repeatedInt64 = [3, 4]
        o.repeatedUint32 = [5, 6]
        o.repeatedUint64 = [7, 8]
        o.repeatedSint32 = [9, 10]
        o.repeatedSint64 = [11, 12]
        o.repeatedFixed32 = [13, 14]
        o.repeatedFixed64 = [15, 16]
        o.repeatedSfixed32 = [17, 18]
        o.repeatedSfixed64 = [19, 20]
        o.repeatedFloat = [21, 22]
        o.repeatedDouble = [23, 24]
        o.repeatedBool = [true, false]
        o.repeatedString = ["abc", "def"]
        o.repeatedBytes = [Data(), Data([65, 66])]
        var nested2 = nested
        nested2.bb = -7
        o.repeatedNestedMessage = [nested, nested2]
        var foreign2 = foreign
        foreign2.c = -88
        o.repeatedForeignMessage = [foreign, foreign2]
        var importMessage2 = importMessage
        importMessage2.d = 999999
        o.repeatedImportMessage = [importMessage, importMessage2]
        o.repeatedNestedEnum = [.bar, .baz]
        o.repeatedForeignEnum = [.foreignBar, .foreignBaz]
        o.oneofUint32 = 99
    }

    func testMultipleFields() {
        let expected: String = ("optional_int32: 1\n"
            + "optional_int64: 2\n"
            + "optional_uint32: 3\n"
            + "optional_uint64: 4\n"
            + "optional_sint32: 5\n"
            + "optional_sint64: 6\n"
            + "optional_fixed32: 7\n"
            + "optional_fixed64: 8\n"
            + "optional_sfixed32: 9\n"
            + "optional_sfixed64: 10\n"
            + "optional_float: 11.0\n"
            + "optional_double: 12.0\n"
            + "optional_bool: true\n"
            + "optional_string: \"abc\"\n"
            + "optional_bytes: \"AB\"\n"
            + "optional_nested_message {\n"
            + "  bb: 7\n"
            + "}\n"
            + "optional_foreign_message {\n"
            + "  c: 88\n"
            + "}\n"
            + "optional_import_message {\n"
            + "  d: -9\n"
            + "}\n"
            + "optional_nested_enum: BAZ\n"
            + "optional_foreign_enum: FOREIGN_BAZ\n"
            + "optional_public_import_message {\n"
            + "  e: -999999\n"
            + "}\n"
            + "repeated_int32: [1, 2]\n"
            + "repeated_int64: [3, 4]\n"
            + "repeated_uint32: [5, 6]\n"
            + "repeated_uint64: [7, 8]\n"
            + "repeated_sint32: [9, 10]\n"
            + "repeated_sint64: [11, 12]\n"
            + "repeated_fixed32: [13, 14]\n"
            + "repeated_fixed64: [15, 16]\n"
            + "repeated_sfixed32: [17, 18]\n"
            + "repeated_sfixed64: [19, 20]\n"
            + "repeated_float: [21.0, 22.0]\n"
            + "repeated_double: [23.0, 24.0]\n"
            + "repeated_bool: [true, false]\n"
            + "repeated_string: \"abc\"\n"
            + "repeated_string: \"def\"\n"
            + "repeated_bytes: \"\"\n"
            + "repeated_bytes: \"AB\"\n"
            + "repeated_nested_message {\n"
            + "  bb: 7\n"
            + "}\n"
            + "repeated_nested_message {\n"
            + "  bb: -7\n"
            + "}\n"
            + "repeated_foreign_message {\n"
            + "  c: 88\n"
            + "}\n"
            + "repeated_foreign_message {\n"
            + "  c: -88\n"
            + "}\n"
            + "repeated_import_message {\n"
            + "  d: -9\n"
            + "}\n"
            + "repeated_import_message {\n"
            + "  d: 999999\n"
            + "}\n"
            + "repeated_nested_enum: [BAR, BAZ]\n"
            + "repeated_foreign_enum: [FOREIGN_BAR, FOREIGN_BAZ]\n"
            + "oneof_uint32: 99\n")

        assertTextFormatEncode(expected, configure: configureLargeObject)
    }

    func testMultipleFields_numbers() {
        let text: String = ("1: 1\n"
            + "2: 2\n"
            + "3: 3\n"
            + "4: 4\n"
            + "5: 5\n"
            + "6: 6\n"
            + "7: 7\n"
            + "8: 8\n"
            + "9: 9\n"
            + "10: 10\n"
            + "11: 11\n"
            + "12: 12\n"
            + "13: true\n"
            + "14: \"abc\"\n"
            + "15: \"AB\"\n"
            + "18 {\n"
            + "  bb: 7\n"
            + "}\n"
            + "19 {\n"
            + "  c: 88\n"
            + "}\n"
            + "20 {\n"
            + "  d: -9\n"
            + "}\n"
            + "21: BAZ\n"
            + "22: FOREIGN_BAZ\n"
            + "26 {\n"
            + "  e: -999999\n"
            + "}\n"
            + "31: [1, 2]\n"
            + "32: [3, 4]\n"
            + "33: [5, 6]\n"
            + "34: [7, 8]\n"
            + "35: [9, 10]\n"
            + "36: [11, 12]\n"
            + "37: [13, 14]\n"
            + "38: [15, 16]\n"
            + "39: [17, 18]\n"
            + "40: [19, 20]\n"
            + "41: [21, 22]\n"
            + "42: [23, 24]\n"
            + "43: [true, false]\n"
            + "44: \"abc\"\n"
            + "44: \"def\"\n"
            + "45: \"\"\n"
            + "45: \"AB\"\n"
            + "48 {\n"
            + "  bb: 7\n"
            + "}\n"
            + "48 {\n"
            + "  bb: -7\n"
            + "}\n"
            + "49 {\n"
            + "  c: 88\n"
            + "}\n"
            + "49 {\n"
            + "  c: -88\n"
            + "}\n"
            + "50 {\n"
            + "  d: -9\n"
            + "}\n"
            + "50 {\n"
            + "  d: 999999\n"
            + "}\n"
            + "51: [BAR, BAZ]\n"
            + "52: [FOREIGN_BAR, FOREIGN_BAZ]\n"
            + "111: 99\n")

        let expected = MessageTestType.with { configureLargeObject(&$0) }
        assertTextFormatDecodeSucceeds(text) {(o: MessageTestType) in
            o == expected
        }
    }
}
