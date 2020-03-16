// Tests/SwiftProtobufTests/Test_AllTypes.swift - Basic encoding/decoding test
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This is a thorough test of the binary protobuf encoding and decoding.
/// It attempts to verify the encoded form for every basic proto type
/// and verify correct decoding, including handling of unusual-but-valid
/// sequences and error reporting for invalid sequences.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

class Test_AllTypes: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestAllTypes

    // Custom decodeSucceeds that also does a round-trip through the Empty
    // message to make sure unknown fields are consistently preserved by proto2.
    func assertDecodeSucceeds(_ bytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line, check: (MessageTestType) -> Bool) {
        baseAssertDecodeSucceeds(bytes, file: file, line: line, check: check)
        do {
            // Make sure unknown fields are preserved by empty message decode/encode
            let empty = try ProtobufUnittest_TestEmptyMessage(serializedBytes: bytes)
            do {
                let newBytes = try empty.serializedBytes()
                XCTAssertEqual(bytes, newBytes, "Empty decode/recode did not match", file: file, line: line)
            } catch let e {
                XCTFail("Reserializing empty threw an error: \(e)", file: file, line: line)
            }
        } catch {
            XCTFail("Empty decoding threw an error", file: file, line: line)
        }
    }

    func assertDebugDescription(_ expected: String, file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> ()) {
        var m = MessageTestType()
        configure(&m)
        let actual = m.debugDescription
        XCTAssertEqual(actual, expected, file: file, line: line)
    }

    //
    // Unknown field
    //
    func testEncoding_unknown() {
        assertDecodeFails([208, 41]) // Field 666, wiretype 0
        assertDecodeSucceeds([208, 41, 0]) {$0 != MessageTestType()} // Ditto, with varint body
    }

    //
    // Singular types
    //
    func testEncoding_optionalInt32() {
        assertEncode([8, 1]) {(o: inout MessageTestType) in o.optionalInt32 = 1}
        assertEncode([8, 255, 255, 255, 255, 7]) {(o: inout MessageTestType) in o.optionalInt32 = Int32.max}
        assertEncode([8, 128, 128, 128, 128, 248, 255, 255, 255, 255, 1]) {(o: inout MessageTestType) in o.optionalInt32 = Int32.min}
        assertDecodeSucceeds([8, 1]) {$0.optionalInt32 == 1}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_int32: 1\n") {(o: inout MessageTestType) in o.optionalInt32 = 1}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_int32: -2147483648\noptional_uint32: 4294967295\n") {(o: inout MessageTestType) in
            o.optionalInt32 = Int32.min
            o.optionalUint32 = UInt32.max
        }
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\n") {(o: inout MessageTestType) in
            o.optionalInt32 = 1
            o.clearOptionalInt32()
        }

        // Technically, this overflows Int32, but we truncate and accept it.
        assertDecodeSucceeds([8, 255, 255, 255, 255, 255, 255, 1]) {
            if $0.hasOptionalInt32 {
                return $0.optionalInt32 == -1
            } else {
                XCTFail("Nonexistent value")
                return false
            }
        }

        // We should recognize a valid field after an unknown field:
        assertDecodeSucceeds([208, 41, 0, 8, 1]) {$0.optionalInt32 == 1}

        assertDecodeFails([8])

        assertDecodeFails([9, 57]) // Cannot use wire type 1
        assertDecodeFails([10, 58]) // Cannot use wire type 2
        assertDecodeFails([11, 59]) // Cannot use wire type 3
        assertDecodeFails([12, 60]) // Cannot use wire type 4
        assertDecodeFails([13, 61]) // Cannot use wire type 5
        assertDecodeFails([14, 62]) // Cannot use wire type 6
        assertDecodeFails([15, 63]) // Cannot use wire type 7
        assertDecodeFails([8, 188])
        assertDecodeFails([8])

        let empty = MessageTestType()
        var a = empty
        a.optionalInt32 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalInt32()
        XCTAssertNotEqual(a, b)
        b.optionalInt32 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalInt32 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalInt32)
        XCTAssertTrue(d.hasOptionalInt32)
        d.clearOptionalInt32()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalInt32)
        XCTAssertFalse(d.hasOptionalInt32)
    }

    func testEncoding_optionalInt64() {
        assertEncode([16, 1]) {(o: inout MessageTestType) in o.optionalInt64 = 1}
        assertEncode([16, 255, 255, 255, 255, 255, 255, 255, 255, 127]) {(o: inout MessageTestType) in o.optionalInt64 = Int64.max}
        assertEncode([16, 128, 128, 128, 128, 128, 128, 128, 128, 128, 1]) {(o: inout MessageTestType) in o.optionalInt64 = Int64.min}
        assertDecodeSucceeds([16, 184, 156, 195, 145, 203, 1]) {$0.optionalInt64 == 54529150520}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_int64: 1\n") {(o: inout MessageTestType) in o.optionalInt64 = 1}
        assertDecodeFails([16])
        assertDecodeFails([16, 184, 156, 195, 145, 203])
        assertDecodeFails([17, 81])
        assertDecodeFails([18, 82])
        assertDecodeFails([19, 83])
        assertDecodeFails([20, 84])
        assertDecodeFails([21, 85])
        assertDecodeFails([22, 86])
        assertDecodeFails([23, 87])

        let empty = MessageTestType()
        var a = empty
        a.optionalInt64 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalInt64 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalInt64()
        XCTAssertNotEqual(a, b)
        b.optionalInt64 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalInt64 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalInt64)
        XCTAssertTrue(d.hasOptionalInt64)
        d.clearOptionalInt64()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalInt64)
        XCTAssertFalse(d.hasOptionalInt64)
    }

    func testEncoding_optionalUint32() {
        assertEncode([24, 255, 255, 255, 255, 15]) {(o: inout MessageTestType) in o.optionalUint32 = UInt32.max}
        assertEncode([24, 0]) {(o: inout MessageTestType) in o.optionalUint32 = UInt32.min}
        assertDecodeSucceeds([24, 149, 88]) {$0.optionalUint32 == 11285}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_uint32: 1\n") {(o: inout MessageTestType) in o.optionalUint32 = 1}
        assertDecodeFails([24])
        assertDecodeFails([24, 149])
        assertDecodeFails([25, 105])
        assertDecodeFails([26, 106])
        assertDecodeFails([27, 107])
        assertDecodeFails([28, 108])
        assertDecodeFails([29, 109])
        assertDecodeFails([30, 110])
        assertDecodeFails([31, 111])

        let empty = MessageTestType()
        var a = empty
        a.optionalUint32 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalUint32 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalUint32()
        XCTAssertNotEqual(a, b)
        b.optionalUint32 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalUint32 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalUint32)
        XCTAssertTrue(d.hasOptionalUint32)
        d.clearOptionalUint32()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalUint32)
        XCTAssertFalse(d.hasOptionalUint32)
    }

    func testEncoding_optionalUint64() {
        assertEncode([32, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1]) {(o: inout MessageTestType) in o.optionalUint64 = UInt64.max}
        assertEncode([32, 0]) {(o: inout MessageTestType) in o.optionalUint64 = UInt64.min}
        assertDecodeSucceeds([32, 149, 7]) {$0.optionalUint64 == 917}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_uint64: 1\n") {(o: inout MessageTestType) in o.optionalUint64 = 1}
        assertDecodeFails([32])
        assertDecodeFails([32, 149])
        assertDecodeFails([32, 149, 190, 193, 230, 186, 233, 166, 219])
        assertDecodeFails([33])
        assertDecodeFails([33, 0])
        assertDecodeFails([33, 8, 0])
        assertDecodeFails([34])
        assertDecodesAsUnknownFields([34, 0]) // Wrong wire type (length delimited), valid as an unknown field
        assertDecodeFails([34, 8, 0])
        assertDecodeFails([35])
        assertDecodeFails([35, 0])
        assertDecodeFails([35, 8, 0])
        assertDecodeFails([36])
        assertDecodeFails([36, 0])
        assertDecodeFails([36, 8, 0])
        assertDecodeFails([37])
        assertDecodeFails([37, 0])
        assertDecodeFails([37, 8, 0])
        assertDecodeFails([38])
        assertDecodeFails([38, 0])
        assertDecodeFails([38, 8, 0])
        assertDecodeFails([39])
        assertDecodeFails([39, 0])
        assertDecodeFails([39, 8, 0])

        let empty = MessageTestType()
        var a = empty
        a.optionalUint64 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalUint64 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalUint64()
        XCTAssertNotEqual(a, b)
        b.optionalUint64 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalUint64 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalUint64)
        XCTAssertTrue(d.hasOptionalUint64)
        d.clearOptionalUint64()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalUint64)
        XCTAssertFalse(d.hasOptionalUint64)
    }

    func testEncoding_optionalSint32() {
        assertEncode([40, 254, 255, 255, 255, 15]) {(o: inout MessageTestType) in o.optionalSint32 = Int32.max}
        assertEncode([40, 255, 255, 255, 255, 15]) {(o: inout MessageTestType) in o.optionalSint32 = Int32.min}
        assertDecodeSucceeds([40, 0x81, 0x82, 0x80, 0x00]) {$0.optionalSint32 == -129}
        assertDecodeSucceeds([40, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00]) {$0.optionalSint32 == 0}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_sint32: 1\n") {(o: inout MessageTestType) in o.optionalSint32 = 1}

        // Truncate on overflow
        assertDecodeSucceeds([40, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f]) {$0.optionalSint32 == -2147483648}
        assertDecodeSucceeds([40, 0xfe, 0xff, 0xff, 0xff, 0xff, 0x7f]) {$0.optionalSint32 == 2147483647}

        assertDecodeFails([40])
        assertDecodeFails([40, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00])
        assertDecodeFails([41])
        assertDecodeFails([41, 0])
        assertDecodeFails([42])
        assertDecodesAsUnknownFields([42, 0])  // Wrong wire type (length delimited), valid as an unknown field
        assertDecodeFails([43])
        assertDecodeFails([43, 0])
        assertDecodeFails([44])
        assertDecodeFails([44, 0])
        assertDecodeFails([45])
        assertDecodeFails([45, 0])
        assertDecodeFails([46])
        assertDecodeFails([46, 0])
        assertDecodeFails([47])
        assertDecodeFails([47, 0])

        let empty = MessageTestType()
        var a = empty
        a.optionalSint32 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalSint32 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalSint32()
        XCTAssertNotEqual(a, b)
        b.optionalSint32 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalSint32 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalSint32)
        XCTAssertTrue(d.hasOptionalSint32)
        d.clearOptionalSint32()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalSint32)
        XCTAssertFalse(d.hasOptionalSint32)
    }

    func testEncoding_optionalSint64() {
        assertEncode([48, 254, 255, 255, 255, 255, 255, 255, 255, 255, 1]) {(o: inout MessageTestType) in o.optionalSint64 = Int64.max}
        assertEncode([48, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1]) {(o: inout MessageTestType) in o.optionalSint64 = Int64.min}
        assertDecodeSucceeds([48, 139, 94]) {$0.optionalSint64 == -6022}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_sint64: 1\n") {(o: inout MessageTestType) in o.optionalSint64 = 1}
        assertDecodeFails([48])
        assertDecodeFails([48, 139])
        assertDecodeFails([49])
        assertDecodeFails([49, 0])
        assertDecodeFails([50])
        assertDecodesAsUnknownFields([50, 0])  // Wrong wire type (length delimited), valid as an unknown field
        assertDecodeFails([51])
        assertDecodeFails([51, 0])
        assertDecodeFails([52])
        assertDecodeFails([52, 0])
        assertDecodeFails([53])
        assertDecodeFails([53, 0])
        assertDecodeFails([54])
        assertDecodeFails([54, 0])
        assertDecodeFails([55])
        assertDecodeFails([55, 0])

        let empty = MessageTestType()
        var a = empty
        a.optionalSint64 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalSint64 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalSint64()
        XCTAssertNotEqual(a, b)
        b.optionalSint64 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalSint64 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalSint64)
        XCTAssertTrue(d.hasOptionalSint64)
        d.clearOptionalSint64()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalSint64)
        XCTAssertFalse(d.hasOptionalSint64)
    }

    func testEncoding_optionalFixed32() {
        assertEncode([61, 255, 255, 255, 255]) {(o: inout MessageTestType) in o.optionalFixed32 = UInt32.max}
        assertEncode([61, 0, 0, 0, 0]) {(o: inout MessageTestType) in o.optionalFixed32 = UInt32.min}
        assertDecodeSucceeds([61, 8, 12, 108, 1]) {$0.optionalFixed32 == 23858184}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_fixed32: 1\n") {(o: inout MessageTestType) in o.optionalFixed32 = 1}
        assertDecodeFails([61])
        assertDecodeFails([61, 255])
        assertDecodeFails([61, 255, 255])
        assertDecodeFails([61, 255, 255, 255])
        assertDecodeFails([56])
        assertDecodesAsUnknownFields([56, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([56, 0, 0, 0, 0])
        assertDecodeFails([57])
        assertDecodeFails([57, 0])
        assertDecodeFails([57, 0, 0, 0, 0])
        assertDecodeFails([58])
        assertDecodesAsUnknownFields([58, 0])  // Wrong wire type (length delimited), valid as an unknown field
        assertDecodeFails([58, 0, 0, 0, 0])
        assertDecodeFails([59])
        assertDecodeFails([59, 0])
        assertDecodeFails([59, 0, 0, 0, 0])
        assertDecodeFails([60])
        assertDecodeFails([60, 0])
        assertDecodeFails([60, 0, 0, 0, 0])
        assertDecodeFails([62])
        assertDecodeFails([62, 0])
        assertDecodeFails([62, 0, 0, 0, 0])
        assertDecodeFails([63])
        assertDecodeFails([63, 0])
        assertDecodeFails([63, 0, 0, 0, 0])

        let empty = MessageTestType()
        var a = empty
        a.optionalFixed32 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalFixed32 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalFixed32()
        XCTAssertNotEqual(a, b)
        b.optionalFixed32 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalFixed32 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalFixed32)
        XCTAssertTrue(d.hasOptionalFixed32)
        d.clearOptionalFixed32()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalFixed32)
        XCTAssertFalse(d.hasOptionalFixed32)
    }

    func testEncoding_optionalFixed64() {
        assertEncode([65, 255, 255, 255, 255, 255, 255, 255, 255]) {(o: inout MessageTestType) in o.optionalFixed64 = UInt64.max}
        assertEncode([65, 0, 0, 0, 0, 0, 0, 0, 0]) {(o: inout MessageTestType) in o.optionalFixed64 = UInt64.min}
        assertDecodeSucceeds([65, 255, 255, 255, 255, 255, 255, 255, 255]) {$0.optionalFixed64 == 18446744073709551615}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_fixed64: 1\n") {(o: inout MessageTestType) in o.optionalFixed64 = 1}
        assertDecodeFails([65])
        assertDecodeFails([65, 255])
        assertDecodeFails([65, 255, 255])
        assertDecodeFails([65, 255, 255, 255])
        assertDecodeFails([65, 255, 255, 255, 255])
        assertDecodeFails([65, 255, 255, 255, 255, 255])
        assertDecodeFails([65, 255, 255, 255, 255, 255, 255])
        assertDecodeFails([65, 255, 255, 255, 255, 255, 255, 255])
        assertDecodeFails([64])
        assertDecodesAsUnknownFields([64, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([64, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([66])
        assertDecodesAsUnknownFields([66, 0])  // Wrong wire type (length delimited), valid as an unknown field
        assertDecodeFails([66, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([67])
        assertDecodeFails([67, 0])
        assertDecodeFails([67, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([68])
        assertDecodeFails([68, 0])
        assertDecodeFails([68, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([69])
        assertDecodeFails([69, 0])
        assertDecodeFails([69, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([69])
        assertDecodeFails([69, 0])
        assertDecodeFails([70, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([71])
        assertDecodeFails([71, 0])
        assertDecodeFails([71, 0, 0, 0, 0, 0, 0, 0, 0])

        let empty = MessageTestType()
        var a = empty
        a.optionalFixed64 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalFixed64 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalFixed64()
        XCTAssertNotEqual(a, b)
        b.optionalFixed64 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalFixed64 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalFixed64)
        XCTAssertTrue(d.hasOptionalFixed64)
        d.clearOptionalFixed64()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalFixed64)
        XCTAssertFalse(d.hasOptionalFixed64)
    }

    func testEncoding_optionalSfixed32() {
        assertEncode([77, 255, 255, 255, 127]) {(o: inout MessageTestType) in o.optionalSfixed32 = Int32.max}
        assertEncode([77, 0, 0, 0, 128]) {(o: inout MessageTestType) in o.optionalSfixed32 = Int32.min}
        assertDecodeSucceeds([77, 0, 0, 0, 0]) {$0.optionalSfixed32 == 0}
        assertDecodeSucceeds([77, 255, 255, 255, 255]) {$0.optionalSfixed32 == -1}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_sfixed32: 1\n") {(o: inout MessageTestType) in o.optionalSfixed32 = 1}
        assertDecodeFails([77])
        assertDecodeFails([77])
        assertDecodeFails([77, 0])
        assertDecodeFails([77, 0, 0])
        assertDecodeFails([77, 0, 0, 0])
        assertDecodeFails([72])
        assertDecodesAsUnknownFields([72, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([72, 0, 0, 0, 0])
        assertDecodeFails([73])
        assertDecodeFails([73, 0])
        assertDecodeFails([73, 0, 0, 0, 0])
        assertDecodeFails([74])
        assertDecodesAsUnknownFields([74, 0])  // Wrong wire type (length delimited), valid as an unknown field
        assertDecodeFails([74, 0, 0, 0, 0])
        assertDecodeFails([75])
        assertDecodeFails([75, 0])
        assertDecodeFails([75, 0, 0, 0, 0])
        assertDecodeFails([76])
        assertDecodeFails([76, 0])
        assertDecodeFails([76, 0, 0, 0, 0])
        assertDecodeFails([78])
        assertDecodeFails([78, 0])
        assertDecodeFails([78, 0, 0, 0, 0])
        assertDecodeFails([79])
        assertDecodeFails([79, 0])
        assertDecodeFails([79, 0, 0, 0, 0])

        let empty = MessageTestType()
        var a = empty
        a.optionalSfixed32 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalSfixed32 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalSfixed32()
        XCTAssertNotEqual(a, b)
        b.optionalSfixed32 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalSfixed32 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalSfixed32)
        XCTAssertTrue(d.hasOptionalSfixed32)
        d.clearOptionalSfixed32()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalSfixed32)
        XCTAssertFalse(d.hasOptionalSfixed32)
    }

    func testEncoding_optionalSfixed64() {
        assertEncode([81, 255, 255, 255, 255, 255, 255, 255, 127]) {(o: inout MessageTestType) in o.optionalSfixed64 = Int64.max}
        assertEncode([81, 0, 0, 0, 0, 0, 0, 0, 128]) {(o: inout MessageTestType) in o.optionalSfixed64 = Int64.min}
        assertDecodeSucceeds([81, 0, 0, 0, 0, 0, 0, 0, 128]) {$0.optionalSfixed64 == -9223372036854775808}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_sfixed64: 1\n") {(o: inout MessageTestType) in o.optionalSfixed64 = 1}
        assertDecodeFails([81])
        assertDecodeFails([81, 0])
        assertDecodeFails([81, 0, 0])
        assertDecodeFails([81, 0, 0, 0])
        assertDecodeFails([81, 0, 0, 0, 0])
        assertDecodeFails([81, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([80])
        assertDecodesAsUnknownFields([80, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([80, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([82])
        assertDecodesAsUnknownFields([82, 0])  // Wrong wire type (length delimited), valid as an unknown field
        assertDecodeFails([82, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([83])
        assertDecodeFails([83, 0])
        assertDecodeFails([83, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([84])
        assertDecodeFails([84, 0])
        assertDecodeFails([84, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([85])
        assertDecodeFails([85, 0])
        assertDecodeFails([85, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([86])
        assertDecodeFails([86, 0])
        assertDecodeFails([86, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([87])
        assertDecodeFails([87, 0])
        assertDecodeFails([87, 0, 0, 0, 0, 0, 0, 0, 0])

        let empty = MessageTestType()
        var a = empty
        a.optionalSfixed64 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalSfixed64 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalSfixed64()
        XCTAssertNotEqual(a, b)
        b.optionalSfixed64 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalSfixed64 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalSfixed64)
        XCTAssertTrue(d.hasOptionalSfixed64)
        d.clearOptionalSfixed64()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalSfixed64)
        XCTAssertFalse(d.hasOptionalSfixed64)
    }

    func testEncoding_optionalFloat() {
        assertEncode([93, 0, 0, 0, 0]) {(o: inout MessageTestType) in o.optionalFloat = 0.0}
        assertEncode([93, 0, 0, 0, 63]) {(o: inout MessageTestType) in o.optionalFloat = 0.5}
        assertEncode([93, 0, 0, 0, 64]) {(o: inout MessageTestType) in o.optionalFloat = 2.0}
        assertDecodeSucceeds([93, 0, 0, 0, 0]) {
            if $0.hasOptionalFloat {
                return $0.optionalFloat == 0
            } else {
                XCTFail("Nonexistent value")
                return false
            }
        }
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_float: 1.0\n") {
            (o: inout MessageTestType) in o.optionalFloat = 1.0}
        assertDecodeFails([93, 0, 0, 0])
        assertDecodeFails([93, 0, 0])
        assertDecodeFails([93, 0])
        assertDecodeFails([93])
        assertDecodeFails([88]) // Float cannot use wire type 0
        assertDecodesAsUnknownFields([88, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([89]) // Float cannot use wire type 1
        assertDecodeFails([89, 0, 0, 0, 0]) // Float cannot use wire type 1
        assertDecodeFails([90]) // Float cannot use wire type 2
        assertDecodesAsUnknownFields([90, 0])  // Wrong wire type (length delimited), valid as an unknown field
        assertDecodeFails([91]) // Float cannot use wire type 3
        assertDecodeFails([91, 0, 0, 0, 0]) // Float cannot use wire type 3
        assertDecodeFails([92]) // Float cannot use wire type 4
        assertDecodeFails([92, 0, 0, 0, 0]) // Float cannot use wire type 4
        assertDecodeFails([94]) // Float cannot use wire type 6
        assertDecodeFails([94, 0, 0, 0, 0]) // Float cannot use wire type 6
        assertDecodeFails([95]) // Float cannot use wire type 7
        assertDecodeFails([95, 0, 0, 0, 0]) // Float cannot use wire type 7

        let empty = MessageTestType()
        var a = empty
        a.optionalFloat = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalFloat = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalFloat()
        XCTAssertNotEqual(a, b)
        b.optionalFloat = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalFloat = 1.0
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalFloat)
        XCTAssertTrue(d.hasOptionalFloat)
        d.clearOptionalFloat()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalFloat)
        XCTAssertFalse(d.hasOptionalFloat)
    }

    func testEncoding_optionalDouble() {
        assertEncode([97, 0, 0, 0, 0, 0, 0, 0, 0]) {(o: inout MessageTestType) in o.optionalDouble = 0.0}
        assertEncode([97, 0, 0, 0, 0, 0, 0, 224, 63]) {(o: inout MessageTestType) in o.optionalDouble = 0.5}
        assertEncode([97, 0, 0, 0, 0, 0, 0, 0, 64]) {(o: inout MessageTestType) in o.optionalDouble = 2.0}
        assertDecodeSucceeds([97, 0, 0, 0, 0, 0, 0, 224, 63]) {$0.optionalDouble == 0.5}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_double: 1.0\n") {
            (o: inout MessageTestType) in o.optionalDouble = 1.0}
        assertDecodeFails([97, 0, 0, 0, 0, 0, 0, 224])
        assertDecodeFails([97])
        assertDecodeFails([96])
        assertDecodesAsUnknownFields([96, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([96, 10, 10, 10, 10, 10, 10, 10, 10])
        assertDecodeFails([98])
        assertDecodesAsUnknownFields([98, 0])  // Wrong wire type (length delimited), valid as an unknown field
        assertDecodeFails([98, 10, 10, 10, 10, 10, 10, 10, 10])
        assertDecodeFails([99])
        assertDecodeFails([99, 0])
        assertDecodeFails([99, 10, 10, 10, 10, 10, 10, 10, 10])
        assertDecodeFails([100])
        assertDecodeFails([100, 0])
        assertDecodeFails([100, 10, 10, 10, 10, 10, 10, 10, 10])
        assertDecodeFails([101])
        assertDecodeFails([101, 0])
        assertDecodeFails([101, 10, 10, 10, 10, 10, 10, 10, 10])
        assertDecodeFails([101])
        assertDecodeFails([102, 0])
        assertDecodeFails([102, 10, 10, 10, 10, 10, 10, 10, 10])
        assertDecodeFails([103])
        assertDecodeFails([103, 0])
        assertDecodeFails([103, 10, 10, 10, 10, 10, 10, 10, 10])

        let empty = MessageTestType()
        var a = empty
        a.optionalDouble = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalDouble = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalDouble()
        XCTAssertNotEqual(a, b)
        b.optionalDouble = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalDouble = 1.0
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalDouble)
        XCTAssertTrue(d.hasOptionalDouble)
        d.clearOptionalDouble()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalDouble)
        XCTAssertFalse(d.hasOptionalDouble)
    }

    func testEncoding_optionalBool() {
        assertEncode([104, 0]) {(o: inout MessageTestType) in o.optionalBool = false}
        assertEncode([104, 1]) {(o: inout MessageTestType) in o.optionalBool = true}
        assertDecodeSucceeds([104, 1]) {
            if $0.hasOptionalBool {
                return $0.optionalBool == true
            } else {
                XCTFail("Nonexistent value")
                return false
            }
        }
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_bool: true\n") {(o: inout MessageTestType) in o.optionalBool = true}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_bool: false\n") {(o: inout MessageTestType) in o.optionalBool = false}
        assertDecodeFails([104])
        assertDecodeFails([104, 255])
        assertDecodeFails([105])
        assertDecodeFails([105, 0])
        assertDecodeFails([106])
        assertDecodesAsUnknownFields([106, 0])  // Wrong wire type (length delimited), valid as an unknown field
        assertDecodeFails([107])
        assertDecodeFails([107, 0])
        assertDecodeFails([108])
        assertDecodeFails([108, 0])
        assertDecodeFails([109])
        assertDecodeFails([109, 0])
        assertDecodeFails([110])
        assertDecodeFails([110, 0])
        assertDecodeFails([111])
        assertDecodeFails([111, 0])

        let empty = MessageTestType()
        var a = empty
        a.optionalBool = false
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalBool = true
        XCTAssertNotEqual(a, b)
        b.clearOptionalBool()
        XCTAssertNotEqual(a, b)
        b.optionalBool = false
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalBool = true
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalBool)
        XCTAssertTrue(d.hasOptionalBool)
        d.clearOptionalBool()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalBool)
        XCTAssertFalse(d.hasOptionalBool)
    }

    func testEncoding_optionalString() {
        assertEncode([114, 0]) {(o: inout MessageTestType) in o.optionalString = ""}
        assertEncode([114, 1, 65]) {(o: inout MessageTestType) in o.optionalString = "A"}
        assertEncode([114, 4, 0xf0, 0x9f, 0x98, 0x84]) {(o: inout MessageTestType) in o.optionalString = "😄"}
        assertEncode([114, 11, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) {(o: inout MessageTestType) in
            o.optionalString = "\u{00}\u{01}\u{02}\u{03}\u{04}\u{05}\u{06}\u{07}\u{08}\u{09}\u{0a}"}
        assertDecodeSucceeds([114, 5, 72, 101, 108, 108, 111]) {
            if $0.hasOptionalString {
                return $0.optionalString == "Hello"
            } else {
                XCTFail("Nonexistent value")
                return false
            }
        }
        assertDecodeSucceeds([114, 4, 97, 0, 98, 99]) {
            return $0.optionalString == "a\0bc"
        }
        assertDecodeSucceeds([114, 16, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]) {
            return $0.optionalString == "\u{00}\u{01}\u{02}\u{03}\u{04}\u{05}\u{06}\u{07}\u{08}\u{09}\u{0a}\u{0b}\u{0c}\u{0d}\u{0e}\u{0f}"
        }
        assertDecodeSucceeds([114, 16, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]) {
            return $0.optionalString == "\u{10}\u{11}\u{12}\u{13}\u{14}\u{15}\u{16}\u{17}\u{18}\u{19}\u{1a}\u{1b}\u{1c}\u{1d}\u{1e}\u{1f}"
        }
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_string: \"abc\"\n") {(o: inout MessageTestType) in o.optionalString = "abc"}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_string: \"\\b\\t\"\n") {(o: inout MessageTestType) in o.optionalString = "\u{08}\u{09}"}
        assertDecodeFails([114])
        assertDecodeFails([114, 1])
        assertDecodeFails([114, 2, 65])
        assertDecodeFails([114, 1, 193]) // Invalid UTF-8
        assertDecodeFails([112])
        assertDecodesAsUnknownFields([112, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([113])
        assertDecodeFails([113, 0])
        assertDecodeFails([115])
        assertDecodeFails([115, 0])
        assertDecodeFails([116])
        assertDecodeFails([116, 0])
        assertDecodeFails([117])
        assertDecodeFails([117, 0])
        assertDecodeFails([118])
        assertDecodeFails([118, 0])
        assertDecodeFails([119])
        assertDecodeFails([119, 0])

        let empty = MessageTestType()
        var a = empty
        a.optionalString = ""
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalString = "a"
        XCTAssertNotEqual(a, b)
        b.clearOptionalString()
        XCTAssertNotEqual(a, b)
        b.optionalString = ""
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalString = "blah"
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalString)
        XCTAssertTrue(d.hasOptionalString)
        d.clearOptionalString()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalString)
        XCTAssertFalse(d.hasOptionalString)
    }

    func testEncoding_optionalGroup() {
        assertEncode([131, 1, 136, 1, 159, 141, 6, 132, 1]) {(o: inout MessageTestType) in
            var g = MessageTestType.OptionalGroup()
            g.a = 99999
            o.optionalGroup = g
        }
        assertDecodeSucceeds([131, 1, 136, 1, 159, 141, 6, 132, 1]) {
            $0.optionalGroup.a == 99999
        }
        // Extra field 1 (varint of zero) within group
        assertDecodeSucceeds([131, 1, 8, 0, 136, 1, 159, 141, 6, 132, 1]) {
            $0.optionalGroup.a == 99999
              && $0.optionalGroup.unknownFields.data == Data([8, 0])
        }
        // Empty group
        assertDecodeSucceeds([131, 1, 132, 1]) {
            $0.optionalGroup == MessageTestType.OptionalGroup()
        }
        assertDebugDescription(
          "SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\nOptionalGroup {\n  a: 1\n}\n") {(o: inout MessageTestType) in
            var g = MessageTestType.OptionalGroup()
            g.a = 1
            o.optionalGroup = g
        }
        assertDecodeFails([131, 1, 136, 1, 159, 141, 6]) // End group missing.
        assertDecodeFails([131, 1, 136, 1, 159, 141, 6, 132, 2]) // Wrong end group.

        assertDecodeFails([128, 1]) // Bad wire type
        assertDecodesAsUnknownFields([128, 1, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodesAsUnknownFields([128, 1, 132, 1])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([129, 1]) // Bad wire type
        assertDecodeFails([129, 1, 0]) // Bad wire type
        assertDecodeFails([130, 1]) // Bad wire type
        assertDecodesAsUnknownFields([130, 1, 0])  // Wrong wire type (length delimited), valid as an unknown field
        assertDecodeFails([131, 1]) // Lone start marker should fail
        assertDecodeFails([132, 1]) // Lone stop marker should fail
        assertDecodeFails([133, 1]) // Bad wire type
        assertDecodeFails([133, 1, 0]) // Bad wire type
        assertDecodeFails([134, 1]) // Bad wire type
        assertDecodeFails([134, 1, 0]) // Bad wire type
        assertDecodeFails([135, 1]) // Bad wire type
        assertDecodeFails([135, 1, 0]) // Bad wire type

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalGroup.a = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalGroup)
        XCTAssertTrue(d.hasOptionalGroup)
        d.clearOptionalGroup()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalGroup)
        XCTAssertFalse(d.hasOptionalGroup)
    }

    func testEncoding_optionalBytes() {
        assertEncode([122, 0]) {(o: inout MessageTestType) in o.optionalBytes = Data()}
        assertEncode([122, 1, 1]) {(o: inout MessageTestType) in o.optionalBytes = Data([1])}
        assertEncode([122, 2, 1, 2]) {(o: inout MessageTestType) in o.optionalBytes = Data([1, 2])}
        assertDecodeSucceeds([122, 4, 0, 1, 2, 255]) {
            if $0.hasOptionalBytes {
                return $0.optionalBytes == Data([0, 1, 2, 255])
            } else {
                XCTFail("Nonexistent value")
                return false
            }
        }
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_bytes: \"\\001\\002\\003\"\n") {(o: inout MessageTestType) in o.optionalBytes = Data([1, 2, 3])}
        assertDecodeFails([122])
        assertDecodeFails([122, 1])
        assertDecodeFails([122, 2, 0])
        assertDecodeFails([122, 3, 0, 0])
        assertDecodeFails([120])
        assertDecodesAsUnknownFields([120, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([121])
        assertDecodeFails([121, 0])
        assertDecodeFails([123])
        assertDecodeFails([123, 0])
        assertDecodeFails([124])
        assertDecodeFails([124, 0])
        assertDecodeFails([125])
        assertDecodeFails([125, 0])
        assertDecodeFails([126])
        assertDecodeFails([126, 0])
        assertDecodeFails([127])
        assertDecodeFails([127, 0])

        let empty = MessageTestType()
        var a = empty
        a.optionalBytes = Data()
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalBytes = Data([1])
        XCTAssertNotEqual(a, b)
        b.clearOptionalBytes()
        XCTAssertNotEqual(a, b)
        b.optionalBytes = Data()
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalBytes = Data([1])
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalBytes)
        XCTAssertTrue(d.hasOptionalBytes)
        d.clearOptionalBytes()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalBytes)
        XCTAssertFalse(d.hasOptionalBytes)
    }

    func testEncoding_optionalNestedMessage() {
        assertEncode([146, 1, 2, 8, 1]) {(o: inout MessageTestType) in
            var nested = MessageTestType.NestedMessage()
            nested.bb = 1
            o.optionalNestedMessage = nested
        }
        assertDecodeSucceeds([146, 1, 4, 8, 1, 8, 3]) {$0.optionalNestedMessage.bb == 3}
        assertDecodeSucceeds([146, 1, 2, 8, 1, 146, 1, 2, 8, 4]) {$0.optionalNestedMessage.bb == 4}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_nested_message {\n  bb: 1\n}\n") {(o: inout MessageTestType) in
            var nested = MessageTestType.NestedMessage()
            nested.bb = 1
            o.optionalNestedMessage = nested
        }

        assertDecodeFails([146, 1, 2, 8, 128])
        assertDecodeFails([146, 1, 1, 128])

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalNestedMessage.bb = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalNestedMessage)
        XCTAssertTrue(d.hasOptionalNestedMessage)
        d.clearOptionalNestedMessage()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalNestedMessage)
        XCTAssertFalse(d.hasOptionalNestedMessage)
    }

    // Known message field followed by unknown field
    func testEncoding_optionalNestedMessage_unknown1() throws {
        let bytes: [UInt8] = [146, 1, 2, 8, 1, // nested message with bb=1
                              208, 41, 0] // Unknown field 666 with varint 0
        do {
            let m = try MessageTestType(serializedData: Data(bytes))
            XCTAssertEqual(m.optionalNestedMessage, MessageTestType.NestedMessage.with{$0.bb = 1})
            do {
                let recoded = try m.serializedData()
                XCTAssertEqual(recoded, Data(bytes))
            } catch let e {
                XCTFail("Failed to recode: \(e)")
            }
        } catch let e {
            XCTFail("Failed to decode: \(e)")
        }
    }

    // Unknown field followed by known message field
    func testEncoding_optionalNestedMessage_unknown2() throws {
        let bytes: [UInt8] = [208, 41, 0, // Unknown 666 with varint 0
                              146, 1, 2, 8, 1] // Nested msg with bb=1
        do {
            let m = try MessageTestType(serializedData: Data(bytes))
            XCTAssertEqual(m.optionalNestedMessage, MessageTestType.NestedMessage.with{$0.bb = 1})
            do {
                let recoded = try m.serializedData()
                // Unknown field gets reserialized at end
                let expectedBytes: [UInt8] = [146, 1, 2, 8, 1, 208, 41, 0]
                XCTAssertEqual(recoded, Data(expectedBytes))
            } catch let e {
                XCTFail("Failed to recode: \(e)")
            }
        } catch let e {
            XCTFail("Failed to decode: \(e)")
        }
    }

    // Known message field with unknown field followed by unknown field
    func testEncoding_optionalNestedMessage_unknown3() throws {
        // Inner field has bb=1 (8, 1) and unknown 666 with varint 99
        // Outer message has unknown 666 with varint 0
        let bytes: [UInt8] = [146, 1, 5, 8, 1, 208, 41, 99,
                              208, 41, 0]
        do {
            let m = try MessageTestType(serializedData: Data(bytes))
            XCTAssertNotEqual(m.optionalNestedMessage, MessageTestType.NestedMessage.with{$0.bb = 1})
            XCTAssertEqual(m.optionalNestedMessage.bb, 1)
            do {
                let recoded = try m.serializedData()
                XCTAssertEqual(recoded, Data(bytes))
            } catch let e {
                XCTFail("Failed to recode: \(e)")
            }
        } catch let e {
            XCTFail("Failed to decode: \(e)")
        }
    }

    // Unknown field, then known message field containing unknown field
    func testEncoding_optionalNestedMessage_unknown4() throws {
        // Same as unknown3 test above, but unknown fields come
        // first in outer and inner message
        let bytes: [UInt8] = [208, 41, 0, 146, 1, 5, 208, 41, 99, 8, 1]
        do {
            let m = try MessageTestType(serializedData: Data(bytes))
            XCTAssertNotEqual(m.optionalNestedMessage, MessageTestType.NestedMessage.with{$0.bb = 1})
            XCTAssertEqual(m.optionalNestedMessage.bb, 1)
            do {
                let recoded = try m.serializedData()
                // Reserializing moves unknown fields to end
                let expectedBytes: [UInt8] = [146, 1, 5, 8, 1, 208, 41, 99, 208, 41, 0]
                XCTAssertEqual(recoded, Data(expectedBytes))
            } catch let e {
                XCTFail("Failed to recode: \(e)")
            }
        } catch let e {
            XCTFail("Failed to decode: \(e)")
        }
    }

    func testEncoding_optionalForeignMessage() {
        assertEncode([154, 1, 2, 8, 1]) {(o: inout MessageTestType) in
            var foreign = ProtobufUnittest_ForeignMessage()
            foreign.c = 1
            o.optionalForeignMessage = foreign
        }
        assertDecodeSucceeds([154, 1, 4, 8, 1, 8, 3]) {$0.optionalForeignMessage.c == 3}
        assertDecodeSucceeds([154, 1, 2, 8, 1, 154, 1, 2, 8, 4]) {$0.optionalForeignMessage.c == 4}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_foreign_message {\n  c: 1\n}\n") {(o: inout MessageTestType) in
            var foreign = ProtobufUnittest_ForeignMessage()
            foreign.c = 1
            o.optionalForeignMessage = foreign
        }

        assertDecodesAsUnknownFields([152, 1, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([153, 1]) // Wire type 1
        assertDecodeFails([153, 1, 0])
        assertDecodesAsUnknownFields([153, 1, 0, 0, 0, 0, 0, 0, 0, 0])  // Wrong wire type (fixed64), valid as an unknown field
        assertDecodeFails([155, 1]) // Wire type 3
        assertDecodeFails([155, 1, 0])
        assertDecodesAsUnknownFields([155, 1, 156, 1]) // Wrong wire type (start group, end group), valid as an unknown field
        assertDecodeFails([156, 1]) // Wire type 4
        assertDecodeFails([156, 1, 0])
        assertDecodeFails([157, 1]) // Wire type 5
        assertDecodeFails([157, 1, 0])
        assertDecodesAsUnknownFields([157, 1, 0, 0, 0, 0])  // Wrong wire type (fixed32), valid as an unknown field
        assertDecodeFails([158, 1]) // Wire type 6
        assertDecodeFails([158, 1, 0])
        assertDecodeFails([159, 1]) // Wire type 7
        assertDecodeFails([159, 1, 0])
        assertDecodeFails([154, 1, 4, 8, 1]) // Truncated

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalForeignMessage.c = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalForeignMessage)
        XCTAssertTrue(d.hasOptionalForeignMessage)
        d.clearOptionalForeignMessage()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalForeignMessage)
        XCTAssertFalse(d.hasOptionalForeignMessage)
    }

    func testEncoding_optionalImportMessage() {
        assertEncode([162, 1, 2, 8, 1]) {(o: inout MessageTestType) in
            var imp = ProtobufUnittestImport_ImportMessage()
            imp.d = 1
            o.optionalImportMessage = imp
        }
        assertDecodeSucceeds([162, 1, 4, 8, 1, 8, 3]) {$0.optionalImportMessage.d == 3}
        assertDecodeSucceeds([162, 1, 2, 8, 1, 162, 1, 2, 8, 4]) {$0.optionalImportMessage.d == 4}

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalImportMessage.d = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalImportMessage)
        XCTAssertTrue(d.hasOptionalImportMessage)
        d.clearOptionalImportMessage()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalImportMessage)
        XCTAssertFalse(d.hasOptionalImportMessage)
    }

    func testEncoding_optionalNestedEnum() throws {
        assertEncode([168, 1, 2]) {(o: inout MessageTestType) in
            o.optionalNestedEnum = .bar
        }
        assertDecodeSucceeds([168, 1, 2]) {
            if $0.hasOptionalNestedEnum {
                return $0.optionalNestedEnum == .bar
            } else {
                XCTFail("Nonexistent value")
                return false
            }
        }
        assertDecodeFails([168, 1])
        assertDecodeSucceeds([168, 1, 128, 1]) { !$0.hasOptionalNestedEnum }
        assertDecodeSucceeds([168, 1, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1]) {$0.optionalNestedEnum == .neg}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_nested_enum: BAR\n") {(o: inout MessageTestType) in
            o.optionalNestedEnum = .bar
        }

        // The out-of-range enum value should be preserved as an unknown field
        let decoded = try ProtobufUnittest_TestAllTypes(serializedData: Data([168, 1, 128, 1]))
        XCTAssertFalse(decoded.hasOptionalNestedEnum)
        let recoded = try decoded.serializedBytes()
        XCTAssertEqual(recoded, [168, 1, 128, 1])

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalNestedEnum = .bar
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalNestedEnum)
        XCTAssertTrue(d.hasOptionalNestedEnum)
        d.clearOptionalNestedEnum()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalNestedEnum)
        XCTAssertFalse(d.hasOptionalNestedEnum)
    }

    func testEncoding_optionalForeignEnum() {
        assertEncode([176, 1, 5]) {(o: inout MessageTestType) in
            o.optionalForeignEnum = .foreignBar
        }
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_foreign_enum: FOREIGN_BAR\n") {(o: inout MessageTestType) in
            o.optionalForeignEnum = .foreignBar
        }

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalForeignEnum = .foreignBar
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalForeignEnum)
        XCTAssertTrue(d.hasOptionalForeignEnum)
        d.clearOptionalForeignEnum()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalForeignEnum)
        XCTAssertFalse(d.hasOptionalForeignEnum)
    }

    func testEncoding_optionalImportEnum() {
        assertEncode([184, 1, 8]) {(o: inout MessageTestType) in
            o.optionalImportEnum = .importBar
        }
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_import_enum: IMPORT_BAR\n") {(o: inout MessageTestType) in
            o.optionalImportEnum = .importBar
        }

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalImportEnum = .importBar
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalImportEnum)
        XCTAssertTrue(d.hasOptionalImportEnum)
        d.clearOptionalImportEnum()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalImportEnum)
        XCTAssertFalse(d.hasOptionalImportEnum)
    }

    func testEncoding_optionalStringPiece() {
        assertEncode([194, 1, 6, 97, 98, 99, 100, 101, 102]) {(o: inout MessageTestType) in
            o.optionalStringPiece = "abcdef"
        }

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalStringPiece = "mumble"
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalStringPiece)
        XCTAssertTrue(d.hasOptionalStringPiece)
        d.clearOptionalStringPiece()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalStringPiece)
        XCTAssertFalse(d.hasOptionalStringPiece)
    }

    func testEncoding_optionalCord() {
        assertEncode([202, 1, 6, 102, 101, 100, 99, 98, 97]) {(o: inout MessageTestType) in
            o.optionalCord = "fedcba"
        }

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalCord = "mumble"
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalCord)
        XCTAssertTrue(d.hasOptionalCord)
        d.clearOptionalCord()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalCord)
        XCTAssertFalse(d.hasOptionalCord)
    }

    func testEncoding_optionalPublicImportMessage() {
        assertEncode([210, 1, 2, 8, 12]) {(o: inout MessageTestType) in
            var sub = ProtobufUnittestImport_PublicImportMessage()
            sub.e = 12
            o.optionalPublicImportMessage = sub
        }
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_public_import_message {\n  e: 9999\n}\n") {(o: inout MessageTestType) in
            var sub = ProtobufUnittestImport_PublicImportMessage()
            sub.e = 9999
            o.optionalPublicImportMessage = sub
        }
    }

    func testEncoding_optionalLazyMessage() {
        assertEncode([218, 1, 2, 8, 7]) {(o: inout MessageTestType) in
            var m = MessageTestType.NestedMessage()
            m.bb = 7
            o.optionalLazyMessage = m
        }
    }

    //
    // Repeated types
    //
    func testEncoding_repeatedInt32() {
        assertEncode([248, 1, 255, 255, 255, 255, 7, 248, 1, 128, 128, 128, 128, 248, 255, 255, 255, 255, 1]) {(o: inout MessageTestType) in o.repeatedInt32 = [Int32.max, Int32.min]}
        assertDecodeSucceeds([248, 1, 8, 248, 1, 247, 255, 255, 255, 15]) {$0.repeatedInt32 == [8, -9]}
        assertDecodeFails([248, 1, 8, 248, 1, 247, 255, 255, 255, 255, 255, 255, 255, 255])
        assertDecodeFails([248, 1, 8, 248, 1])
        assertDecodeFails([248, 1])
        assertDecodeFails([249, 1, 73])
        // 250, 1 should actually work because that's packed
        assertDecodeSucceeds([250, 1, 4, 8, 9, 10, 11]) {$0.repeatedInt32 == [8, 9, 10, 11]}
        assertDecodeFails([251, 1, 75])
        assertDecodeFails([252, 1, 76])
        assertDecodeFails([253, 1, 77])
        assertDecodeFails([254, 1, 78])
        assertDecodeFails([255, 1, 79])
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\nrepeated_int32: 1\n") {(o: inout MessageTestType) in
            o.repeatedInt32 = [1]
        }
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\n") {(o: inout MessageTestType) in
            o.repeatedInt32 = []
        }
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\nrepeated_int32: 1\nrepeated_int32: 2\n") {(o: inout MessageTestType) in
            o.repeatedInt32 = [1, 2]
        }
    }


    func testEncoding_repeatedInt64() {
        assertEncode([128, 2, 255, 255, 255, 255, 255, 255, 255, 255, 127, 128, 2, 128, 128, 128, 128, 128, 128, 128, 128, 128, 1]) {(o: inout MessageTestType) in o.repeatedInt64 = [Int64.max, Int64.min]}
        assertDecodeSucceeds([128, 2, 255, 255, 153, 166, 234, 175, 227, 1, 128, 2, 185, 156, 196, 237, 158, 222, 230, 255, 255, 1]) {$0.repeatedInt64 == [999999999999999, -111111111111111]}
        assertDecodeSucceeds([130, 2, 1, 1]) {$0.repeatedInt64 == [1]} // Accepts packed coding
        assertDecodeFails([128, 2, 255, 255, 153, 166, 234, 175, 227, 1, 128, 2, 185, 156, 196, 237, 158, 222, 230, 255, 255])
        assertDecodeFails([128, 2, 1, 128, 2])
        assertDecodeFails([128, 2, 128])
        assertDecodeFails([128, 2])
        assertDecodeFails([129, 2, 97])
        assertDecodeFails([131, 2, 99])
        assertDecodeFails([132, 2, 100])
        assertDecodeFails([133, 2, 101])
        assertDecodeFails([134, 2, 102])
        assertDecodeFails([135, 2, 103])
    }

    func testEncoding_repeatedUint32() {
        assertEncode([136, 2, 255, 255, 255, 255, 15, 136, 2, 0]) {(o: inout MessageTestType) in o.repeatedUint32 = [UInt32.max, UInt32.min]}
        assertDecodeSucceeds([136, 2, 210, 9, 136, 2, 213, 27]) {(o:MessageTestType) in
            o.repeatedUint32 == [1234, 3541]}
        assertDecodeSucceeds([136, 2, 255, 255, 255, 255, 15, 136, 2, 213, 27]) {(o:MessageTestType) in
            o.repeatedUint32 == [4294967295, 3541]}
        assertDecodeSucceeds([138, 2, 2, 1, 2]) {(o:MessageTestType) in
            o.repeatedUint32 == [1, 2]}

        // Truncate on 32-bit overflow
        assertDecodeSucceeds([136, 2, 255, 255, 255, 255, 31]) {(o:MessageTestType) in
            o.repeatedUint32 == [4294967295]}
        assertDecodeSucceeds([136, 2, 255, 255, 255, 255, 255, 255, 255, 1]) {(o:MessageTestType) in
            o.repeatedUint32 == [4294967295]}

        assertDecodeFails([136, 2])
        assertDecodeFails([136, 2, 210])
        assertDecodeFails([136, 2, 210, 9, 120, 213])
        assertDecodeFails([137, 2, 121])
        assertDecodeFails([139, 2, 123])
        assertDecodeFails([140, 2, 124])
        assertDecodeFails([141, 2, 125])
        assertDecodeFails([142, 2, 126])
        assertDecodeFails([143, 2, 127])
    }

    func testEncoding_repeatedUint64() {
        assertEncode([144, 2, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1, 144, 2, 0]) {(o: inout MessageTestType) in o.repeatedUint64 = [UInt64.max, UInt64.min]}
        assertDecodeSucceeds([144, 2, 149, 8]) {$0.repeatedUint64 == [1045 ]}
        assertDecodeSucceeds([146, 2, 2, 0, 1]) {$0.repeatedUint64 == [0, 1]}
        assertDecodeFails([144])
        assertDecodeFails([144, 2])
        assertDecodeFails([144, 2, 149])
        assertDecodeFails([144, 2, 149, 154, 239, 255, 255, 255, 255, 255, 255, 255])
        assertDecodeFails([145, 2])
        assertDecodeFails([145, 2, 0])
        assertDecodeFails([147, 2])
        assertDecodeFails([147, 2, 0])
        assertDecodeFails([148, 2])
        assertDecodeFails([148, 2, 0])
        assertDecodeFails([149, 2])
        assertDecodeFails([149, 2, 0])
        assertDecodeFails([150, 2])
        assertDecodeFails([150, 2, 0])
        assertDecodeFails([151, 2])
        assertDecodeFails([151, 2, 0])
    }

    func testEncoding_repeatedSint32() {
        assertEncode([152, 2, 254, 255, 255, 255, 15, 152, 2, 255, 255, 255, 255, 15]) {(o: inout MessageTestType) in o.repeatedSint32 = [Int32.max, Int32.min]}
        assertDecodeSucceeds([152, 2, 170, 180, 222, 117, 152, 2, 225, 162, 243, 173, 1]) {$0.repeatedSint32 == [123456789, -182347953]}
        assertDecodeSucceeds([154, 2, 1, 0]) {$0.repeatedSint32 == [0]}
        assertDecodeSucceeds([154, 2, 1, 1, 152, 2, 2]) {$0.repeatedSint32 == [-1, 1]}
        // 32-bit overflow truncates
        assertDecodeSucceeds([152, 2, 170, 180, 222, 117, 152, 2, 225, 162, 243, 173, 255, 255, 1]) {$0.repeatedSint32 == [123456789, -2061396145]}


        assertDecodeFails([152, 2, 170, 180, 222, 117, 152])
        assertDecodeFails([152, 2, 170, 180, 222, 117, 152, 2])
        assertDecodeFails([152, 2, 170, 180, 222, 117, 152, 2, 225])
        assertDecodeFails([152, 2, 170, 180, 222, 117, 152, 2, 225, 162, 243, 173, 255, 255, 255, 255, 255, 255, 1])
        assertDecodeFails([153, 2])
        assertDecodeFails([153, 2, 0])
        assertDecodeFails([155, 2])
        assertDecodeFails([155, 2, 0])
        assertDecodeFails([156, 2])
        assertDecodeFails([156, 2, 0])
        assertDecodeFails([157, 2])
        assertDecodeFails([157, 2, 0])
        assertDecodeFails([158, 2])
        assertDecodeFails([158, 2, 0])
        assertDecodeFails([159, 2])
        assertDecodeFails([159, 2, 0])
    }

    func testEncoding_repeatedSint64() {
        assertEncode([160, 2, 254, 255, 255, 255, 255, 255, 255, 255, 255, 1, 160, 2, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1]) {(o: inout MessageTestType) in o.repeatedSint64 = [Int64.max, Int64.min]}
        assertDecodeSucceeds([160, 2, 170, 180, 222, 117, 160, 2, 225, 162, 243, 173, 255, 89]) {$0.repeatedSint64 == [123456789,-1546102139057]}
        assertDecodeSucceeds([162, 2, 1, 1]) {$0.repeatedSint64 == [-1]}
        assertDecodeFails([160, 2, 170, 180, 222, 117, 160])
        assertDecodeFails([160, 2, 170, 180, 222, 117, 160, 2])
        assertDecodeFails([160, 2, 170, 180, 222, 117, 160, 2, 225])
        assertDecodeFails([160, 2, 170, 180, 222, 117, 160, 2, 225, 162, 243, 173, 255, 255, 255, 255, 255, 255, 1])
        assertDecodeFails([161, 2])
        assertDecodeFails([161, 2, 0])
        assertDecodeFails([163, 2])
        assertDecodeFails([163, 2, 0])
        assertDecodeFails([164, 2])
        assertDecodeFails([164, 2, 0])
        assertDecodeFails([165, 2])
        assertDecodeFails([165, 2, 0])
        assertDecodeFails([166, 2])
        assertDecodeFails([166, 2, 0])
        assertDecodeFails([167, 2])
        assertDecodeFails([167, 2, 0])
    }

    func testEncoding_repeatedFixed32() {
        assertEncode([173, 2, 255, 255, 255, 255, 173, 2, 0, 0, 0, 0]) {(o: inout MessageTestType) in o.repeatedFixed32 = [UInt32.max, UInt32.min]}
        assertDecodeSucceeds([173, 2, 255, 255, 255, 127, 173, 2, 127, 127, 127, 127]) {$0.repeatedFixed32 == [2147483647, 2139062143]}
        assertDecodeSucceeds([170, 2, 4, 1, 0, 0, 0, 173, 2, 255, 255, 255, 127]) {$0.repeatedFixed32 == [1, 2147483647]}
        assertDecodeFails([173])
        assertDecodeFails([173, 2])
        assertDecodeFails([173, 2, 255])
        assertDecodeFails([173, 2, 255, 255])
        assertDecodeFails([173, 2, 255, 255, 255])
        assertDecodeFails([173, 2, 255, 255, 255, 127, 221])
        assertDecodeFails([173, 2, 255, 255, 255, 127, 173, 2])
        assertDecodeFails([173, 2, 255, 255, 255, 127, 173, 2, 255])
        assertDecodeFails([173, 2, 255, 255, 255, 127, 173, 2, 255, 255])
        assertDecodeFails([173, 2, 255, 255, 255, 127, 173, 2, 255, 255, 255])
        assertDecodeFails([168, 2])
        assertDecodesAsUnknownFields([168, 2, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([168, 2, 0, 0, 0, 0])
        assertDecodeFails([169, 2])
        assertDecodeFails([169, 2, 0])
        assertDecodeFails([169, 2, 0, 0, 0, 0])
        assertDecodeFails([171, 2])
        assertDecodeFails([171, 2, 0])
        assertDecodeFails([171, 2, 0, 0, 0, 0])
        assertDecodeFails([172, 2])
        assertDecodeFails([172, 2, 0])
        assertDecodeFails([172, 2, 0, 0, 0, 0])
        assertDecodeFails([174, 2])
        assertDecodeFails([174, 2, 0])
        assertDecodeFails([174, 2, 0, 0, 0, 0])
        assertDecodeFails([175, 2])
        assertDecodeFails([175, 2, 0])
        assertDecodeFails([175, 2, 0, 0, 0, 0])
    }

    func testEncoding_repeatedFixed64() {
        assertEncode([177, 2, 255, 255, 255, 255, 255, 255, 255, 255, 177, 2, 0, 0, 0, 0, 0, 0, 0, 0]) {(o: inout MessageTestType) in o.repeatedFixed64 = [UInt64.max, UInt64.min]}
        assertDecodeSucceeds([177, 2, 255, 255, 255, 127, 0, 0, 0, 0, 177, 2, 255, 255, 255, 255, 0, 0, 0, 0, 177, 2, 255, 255, 255, 255, 255, 255, 255, 255]) {$0.repeatedFixed64 == [2147483647, 4294967295, 18446744073709551615]}
        assertDecodeSucceeds([178, 2, 8, 1, 0, 0, 0, 0, 0, 0, 0]) {$0.repeatedFixed64 == [1]}
        assertDecodeSucceeds([177, 2, 2, 0, 0, 0, 0, 0, 0, 0, 178, 2, 8, 1, 0, 0, 0, 0, 0, 0, 0]) {$0.repeatedFixed64 == [2, 1]}
        assertDecodeFails([177])
        assertDecodeFails([177, 2])
        assertDecodeFails([177, 2, 255])
        assertDecodeFails([177, 2, 255, 255])
        assertDecodeFails([177, 2, 255, 255, 255])
        assertDecodeFails([177, 2, 255, 255, 255, 127])
        assertDecodeFails([177, 2, 255, 255, 255, 127, 0, 0, 0])
        assertDecodeFails([176, 2])
        assertDecodesAsUnknownFields([176, 2, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([176, 2, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([179, 2])
        assertDecodeFails([179, 2, 0])
        assertDecodeFails([179, 2, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([180, 2])
        assertDecodeFails([180, 2, 0])
        assertDecodeFails([180, 2, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([181, 2])
        assertDecodeFails([181, 2, 0])
        assertDecodeFails([181, 2, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([182, 2])
        assertDecodeFails([182, 2, 0])
        assertDecodeFails([182, 2, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([183, 2])
        assertDecodeFails([183, 2, 0])
        assertDecodeFails([183, 2, 0, 0, 0, 0, 0, 0, 0, 0])
    }

    func testEncoding_repeatedSfixed32() {
        assertEncode([189, 2, 255, 255, 255, 127, 189, 2, 0, 0, 0, 128]) {(o: inout MessageTestType) in o.repeatedSfixed32 = [Int32.max, Int32.min]}
        assertDecodeSucceeds([189, 2, 0, 0, 0, 0]) {$0.repeatedSfixed32 == [0]}
        assertDecodeSucceeds([186, 2, 4, 1, 0, 0, 0, 189, 2, 3, 0, 0, 0]) {$0.repeatedSfixed32 == [1, 3]}
        assertDecodeFails([189])
        assertDecodeFails([189, 2])
        assertDecodeFails([189, 2, 0])
        assertDecodeFails([189, 2, 0, 0])
        assertDecodeFails([189, 2, 0, 0, 0])
        assertDecodeFails([184, 2])
        assertDecodesAsUnknownFields([184, 2, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([184, 2, 0, 0, 0, 0])
        assertDecodeFails([185, 2])
        assertDecodeFails([185, 2, 0])
        assertDecodeFails([185, 2, 0, 0, 0, 0])
        assertDecodeFails([187, 2])
        assertDecodeFails([187, 2, 0])
        assertDecodeFails([187, 2, 0, 0, 0, 0])
        assertDecodeFails([188, 2])
        assertDecodeFails([188, 2, 0])
        assertDecodeFails([188, 2, 0, 0, 0, 0])
        assertDecodeFails([190, 2])
        assertDecodeFails([190, 2, 0])
        assertDecodeFails([190, 2, 0, 0, 0, 0])
        assertDecodeFails([191, 2])
        assertDecodeFails([191, 2, 0])
        assertDecodeFails([191, 2, 0, 0, 0, 0])
    }

    func testEncoding_repeatedSfixed64() {
        assertEncode([193, 2, 255, 255, 255, 255, 255, 255, 255, 127, 193, 2, 0, 0, 0, 0, 0, 0, 0, 128]) {(o: inout MessageTestType) in o.repeatedSfixed64 = [Int64.max, Int64.min]}
        assertDecodeSucceeds([193, 2, 0, 0, 0, 0, 0, 0, 0, 128, 193, 2, 255, 255, 255, 255, 255, 255, 255, 255, 193, 2, 1, 0, 0, 0, 0, 0, 0, 0, 193, 2, 255, 255, 255, 255, 255, 255, 255, 127]) {$0.repeatedSfixed64 == [-9223372036854775808, -1, 1, 9223372036854775807]}
        assertDecodeSucceeds([194, 2, 8, 0, 0, 0, 0, 0, 0, 0, 0, 193, 2, 1, 0, 0, 0, 0, 0, 0, 0]) {$0.repeatedSfixed64 == [0, 1]}
        assertDecodeFails([193])
        assertDecodeFails([193, 2])
        assertDecodeFails([193, 2, 0])
        assertDecodeFails([193, 2, 0, 0])
        assertDecodeFails([193, 2, 0, 0, 0])
        assertDecodeFails([193, 2, 0, 0, 0, 0])
        assertDecodeFails([193, 2, 0, 0, 0, 0, 0])
        assertDecodeFails([193, 2, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([193, 2, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([192, 2])
        assertDecodesAsUnknownFields([192, 2, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([192, 2, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([195, 2])
        assertDecodeFails([195, 2, 0])
        assertDecodeFails([195, 2, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([196, 2])
        assertDecodeFails([196, 2, 0])
        assertDecodeFails([196, 2, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([197, 2])
        assertDecodeFails([197, 2, 0])
        assertDecodeFails([197, 2, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([198, 2])
        assertDecodeFails([198, 2, 0])
        assertDecodeFails([198, 2, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([199, 2])
        assertDecodeFails([199, 2, 0])
        assertDecodeFails([199, 2, 0, 0, 0, 0, 0, 0, 0, 0])
    }

    func testEncoding_repeatedFloat() {
        assertEncode([205, 2, 0, 0, 0, 63, 205, 2, 0, 0, 0, 0]) {(o: inout MessageTestType) in o.repeatedFloat = [0.5, 0.0]}
        assertDecodeSucceeds([205, 2, 0, 0, 0, 63, 205, 2, 0, 0, 0, 63]) {$0.repeatedFloat == [0.5, 0.5]}
        assertDecodeSucceeds([202, 2, 8, 0, 0, 0, 63, 0, 0, 0, 63]) {$0.repeatedFloat == [0.5, 0.5]}
        assertDecodeFails([205, 2, 0, 0, 0, 63, 205, 2, 0, 0, 128])
        assertDecodeFails([205, 2, 0, 0, 0, 63, 205, 2])
        assertDecodeFails([200, 2]) // Bad byte sequence
        assertDecodeFails([200, 2, 0, 0, 0, 0]) // Bad byte sequence
        assertDecodeFails([201, 2]) // Bad byte sequence
        assertDecodeFails([201, 2, 0, 0, 0, 0]) // Bad byte sequence
        assertDecodeFails([203, 2]) // Bad byte sequence
        assertDecodeFails([203, 2, 0, 0, 0, 0]) // Bad byte sequence
        assertDecodeFails([204, 2]) // Bad byte sequence
        assertDecodeFails([204, 2, 0, 0, 0, 0]) // Bad byte sequence
        assertDecodeFails([206, 2]) // Bad byte sequence
        assertDecodeFails([206, 2, 0, 0, 0, 0]) // Bad byte sequence
        assertDecodeFails([207, 2]) // Bad byte sequence
        assertDecodeFails([207, 2, 0, 0, 0, 0]) // Bad byte sequence
    }

    func testEncoding_repeatedDouble() {
        assertEncode([209, 2, 0, 0, 0, 0, 0, 0, 224, 63, 209, 2, 0, 0, 0, 0, 0, 0, 0, 0]) {(o: inout MessageTestType) in o.repeatedDouble = [0.5, 0.0]}
        assertDecodeSucceeds([209, 2, 0, 0, 0, 0, 0, 0, 224, 63, 209, 2, 0, 0, 0, 0, 0, 0, 208, 63]) {$0.repeatedDouble == [0.5, 0.25]}
        assertDecodeSucceeds([210, 2, 16, 0, 0, 0, 0, 0, 0, 224, 63, 0, 0, 0, 0, 0, 0, 208, 63]) {$0.repeatedDouble == [0.5, 0.25]}
        assertDecodeFails([209, 2])
        assertDecodeFails([209, 2, 0])
        assertDecodeFails([209, 2, 0, 0])
        assertDecodeFails([209, 2, 0, 0, 0, 0])
        assertDecodeFails([209, 2, 0, 0, 0, 0, 0, 0, 224, 63, 209, 2])
        assertDecodeFails([208, 2])
        assertDecodesAsUnknownFields([208, 2, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([208, 2, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([211, 2])
        assertDecodeFails([211, 2, 0])
        assertDecodeFails([211, 2, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([212, 2])
        assertDecodeFails([212, 2, 0])
        assertDecodeFails([212, 2, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([213, 2])
        assertDecodeFails([213, 2, 0])
        assertDecodeFails([213, 2, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([214, 2])
        assertDecodeFails([214, 2, 0])
        assertDecodeFails([214, 2, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([215, 2])
        assertDecodeFails([215, 2, 0])
        assertDecodeFails([215, 2, 0, 0, 0, 0, 0, 0, 0, 0])
    }

    func testEncoding_repeatedBool() {
        assertEncode([216, 2, 1, 216, 2, 0, 216, 2, 1]) {(o: inout MessageTestType) in o.repeatedBool = [true, false, true]}
        assertDecodeSucceeds([216, 2, 1, 216, 2, 0, 216, 2, 0, 216, 2, 1]) {$0.repeatedBool == [true, false, false, true]}
        assertDecodeSucceeds([218, 2, 3, 1, 0, 1, 216, 2, 0]) {$0.repeatedBool == [true, false, true, false]}
        assertDecodeFails([216])
        assertDecodeFails([216, 2])
        assertDecodeFails([216, 2, 255])
        assertDecodeFails([216, 2, 1, 216, 2, 255])
        assertDecodeFails([217, 2])
        assertDecodeFails([217, 2, 0])
        assertDecodeFails([219, 2])
        assertDecodeFails([219, 2, 0])
        assertDecodeFails([220, 2])
        assertDecodeFails([220, 2, 0])
        assertDecodeFails([221, 2])
        assertDecodeFails([221, 2, 0])
        assertDecodeFails([222, 2])
        assertDecodeFails([222, 2, 0])
        assertDecodeFails([223, 2])
        assertDecodeFails([223, 2, 0])
    }

    func testEncoding_repeatedString() {
        assertEncode([226, 2, 1, 65, 226, 2, 1, 66]) {(o: inout MessageTestType) in o.repeatedString = ["A", "B"]}
        assertDecodeSucceeds([226, 2, 5, 72, 101, 108, 108, 111, 226, 2, 5, 119, 111, 114, 108, 100, 226, 2, 0]) {$0.repeatedString == ["Hello", "world", ""]}
        assertDecodeFails([226])
        assertDecodeFails([226, 2])
        assertDecodeFails([226, 2, 1])
        assertDecodeFails([226, 2, 2, 65])
        assertDecodeFails([226, 2, 1, 193]) // Invalid UTF-8
        assertDecodeFails([224, 2])
        assertDecodesAsUnknownFields([224, 2, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([225, 2])
        assertDecodeFails([225, 2, 0])
        assertDecodeFails([227, 2])
        assertDecodeFails([227, 2, 0])
        assertDecodeFails([228, 2])
        assertDecodeFails([228, 2, 0])
        assertDecodeFails([229, 2])
        assertDecodeFails([229, 2, 0])
        assertDecodeFails([230, 2])
        assertDecodeFails([230, 2, 0])
        assertDecodeFails([231, 2])
        assertDecodeFails([231, 2, 0])
    }

    func testEncoding_repeatedBytes() {
        assertEncode([234, 2, 1, 1, 234, 2, 0, 234, 2, 1, 2]) {(o: inout MessageTestType) in o.repeatedBytes = [Data([1]), Data(), Data([2])]}
        assertDecodeSucceeds([234, 2, 4, 0, 1, 2, 255, 234, 2, 0]) {
            let ref = [Data([0, 1, 2, 255]), Data()]
            for (a,b) in zip($0.repeatedBytes, ref) {
                if a != b { return false }
            }
            return true
        }
        assertDecodeFails([234, 2])
        assertDecodeFails([234, 2, 1])
        assertDecodeFails([232, 2])
        assertDecodesAsUnknownFields([232, 2, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([233, 2])
        assertDecodeFails([233, 2, 0])
        assertDecodeFails([235, 2])
        assertDecodeFails([235, 2, 0])
        assertDecodeFails([236, 2])
        assertDecodeFails([236, 2, 0])
        assertDecodeFails([237, 2])
        assertDecodeFails([237, 2, 0])
        assertDecodeFails([238, 2])
        assertDecodeFails([238, 2, 0])
        assertDecodeFails([239, 2])
        assertDecodeFails([239, 2, 0])
    }

    func testEncoding_repeatedGroup() {
        assertEncode([243, 2, 248, 2, 1, 244, 2, 243, 2, 244, 2]) {(o: inout MessageTestType) in
            var g1 = MessageTestType.RepeatedGroup()
            g1.a = 1
            let g2 = MessageTestType.RepeatedGroup()
            // g2 has nothing set.
            o.repeatedGroup = [g1, g2]
        }
        assertDecodeFails([243, 2, 248, 2, 1]) // End group missing.
        assertDecodeFails([243, 2, 248, 2, 1, 244, 3]) // Wrong end group.
        assertDecodeFails([240, 2]) // Wire type 0
        assertDecodesAsUnknownFields([240, 2, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodesAsUnknownFields([240, 2, 244, 2])  // Wrong wire type (varint), valid as an unknown field
        /*
        assertJSONEncode("{\"repeatedGroup\":[{\"a\":1},{\"a\":2}]}") {(o: inout MessageTestType) in
            var g1 = MessageTestType.RepeatedGroup()
            g1.a = 1
            var g2 = MessageTestType.RepeatedGroup()
            g2.a = 2
            o.repeatedGroup = [g1, g2]
        }
         */
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\nRepeatedGroup {\n  a: 1\n}\nRepeatedGroup {\n  a: 2\n}\n") {(o: inout MessageTestType) in
            var g1 = MessageTestType.RepeatedGroup()
            g1.a = 1
            var g2 = MessageTestType.RepeatedGroup()
            g2.a = 2
            o.repeatedGroup = [g1, g2]
        }
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\nrepeated_int32: 1\nrepeated_int32: 2\nrepeated_int32: 3\nRepeatedGroup {\n  a: 1\n}\nRepeatedGroup {\n  a: 2\n}\n") {(o: inout MessageTestType) in
            o.repeatedInt32 = [1, 2, 3]
            var g1 = MessageTestType.RepeatedGroup()
            g1.a = 1
            var g2 = MessageTestType.RepeatedGroup()
            g2.a = 2
            o.repeatedGroup = [g1, g2]
        }
    }

    func testEncoding_repeatedNestedMessage() {
        assertEncode([130, 3, 2, 8, 1, 130, 3, 2, 8, 2]) {(o: inout MessageTestType) in
            var m1 = MessageTestType.NestedMessage()
            m1.bb = 1
            var m2 = MessageTestType.NestedMessage()
            m2.bb = 2
            o.repeatedNestedMessage = [m1, m2]
        }
        assertDecodeFails([128, 3])
        assertDecodesAsUnknownFields([128, 3, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\nrepeated_nested_message {\n  bb: 1\n}\nrepeated_nested_message {\n  bb: 2\n}\n") {(o: inout MessageTestType) in
            var m1 = MessageTestType.NestedMessage()
            m1.bb = 1
            var m2 = MessageTestType.NestedMessage()
            m2.bb = 2
            o.repeatedNestedMessage = [m1, m2]
        }
    }

    func testEncoding_repeatedNestedMessage_unknown() {
        let bytes: [UInt8] = [
            208, 41, 0, // Unknown 666 with varint 0
            130, 3, 8,  // Inner message with 8 bytes
                208, 41, 8, // Unknown 666 with varint 8
                8, 1, // bb = 1
                208, 41, 9, // Unknown 666 with varint 9
            208, 41, 1, // Unknown 666 with varint 1
            130, 3, 8, // inner message with 8 bytes
                208, 41, 10, // Unknown 666 with varint 10
                8, 2, // bb = 2
                208, 41, 11, // Unknown 666 with varint 11
            208, 41, 2 // Unknown 666 with varint 2
        ]

        do {
            let m = try MessageTestType(serializedData: Data(bytes))
            XCTAssertEqual(m.repeatedNestedMessage.count, 2)
            XCTAssertNotEqual(m.repeatedNestedMessage[0], MessageTestType.NestedMessage.with{$0.bb = 1})
            XCTAssertEqual(m.repeatedNestedMessage[0].bb, 1)
            XCTAssertNotEqual(m.repeatedNestedMessage[1], MessageTestType.NestedMessage.with{$0.bb = 2})
            XCTAssertEqual(m.repeatedNestedMessage[1].bb, 2)
            do {
                // Same contents, but reordered
                let expectedBytes: [UInt8] = [
                    130, 3, 8, 8, 1, 208, 41, 8, 208, 41, 9,
                    130, 3, 8, 8, 2, 208, 41, 10, 208, 41, 11,
                    208, 41, 0,
                    208, 41, 1,
                    208, 41, 2
                ]
                let recoded = try m.serializedData()
                XCTAssertEqual(recoded, Data(expectedBytes))
            } catch let e {
                XCTFail("Failed to recode: \(e)")
            }
        } catch let e {
            XCTFail("Failed to decode: \(e)")
        }
    }

    func testEncoding_repeatedNestedEnum() throws {
        assertEncode([152, 3, 2, 152, 3, 3]) {(o: inout MessageTestType) in
            o.repeatedNestedEnum = [.bar, .baz]
        }
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\nrepeated_nested_enum: BAR\nrepeated_nested_enum: BAZ\n") {(o: inout MessageTestType) in
            o.repeatedNestedEnum = [.bar, .baz]
        }
        assertDecodeSucceeds([152, 3, 2, 152, 3, 128, 1]) {
            $0.repeatedNestedEnum == [.bar]
        }

        // The out-of-range enum value should be preserved as an unknown field
        do {
            let decoded1 = try ProtobufUnittest_TestAllTypes(serializedData: Data([152, 3, 1, 152, 3, 128, 1]))
            XCTAssertEqual(decoded1.repeatedNestedEnum, [.foo])
            let recoded1 = try decoded1.serializedBytes()
            XCTAssertEqual(recoded1, [152, 3, 1, 152, 3, 128, 1])
        } catch let e {
            XCTFail("Decode failed: \(e)")
        }

        // Unknown fields always get reserialized last, which trashes order here:
        do {
            let decoded2 = try ProtobufUnittest_TestAllTypes(serializedData: Data([152, 3, 128, 1, 152, 3, 2]))
            XCTAssertEqual(decoded2.repeatedNestedEnum, [.bar])
            let recoded2 = try decoded2.serializedBytes()
            XCTAssertEqual(recoded2, [152, 3, 2, 152, 3, 128, 1])
        } catch let e {
            XCTFail("Decode failed: \(e)")
        }

        // Unknown enums within packed behave as if it were plain repeated
        do {
            let decoded3 = try ProtobufUnittest_TestAllTypes(serializedData: Data([154, 3, 3, 128, 1, 2]))
            XCTAssertEqual(decoded3.repeatedNestedEnum, [.bar])
            let recoded3 = try decoded3.serializedBytes()
            XCTAssertEqual(recoded3, [152, 3, 2, 154, 3, 2, 128, 1])
        } catch let e {
            XCTFail("Decode failed: \(e)")
        }
    }

    //
    // Singular with Defaults
    //
    func testEncoding_defaultInt32() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultInt32, 41)
        // Setting explicitly does serialize (even if default)
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\ndefault_int32: 41\n") {(o: inout MessageTestType) in
            o.defaultInt32 = 41
        }

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultInt32 = 41
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([232, 3, 41], try a.serializedBytes())
        XCTAssertEqual("{\"defaultInt32\":41}", try a.jsonString())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        // Calling clear* restores the default
        var t = MessageTestType()
        t.defaultInt32 = 4
        t.clearDefaultInt32()
        XCTAssertEqual(t.defaultInt32, 41)
        XCTAssertEqual(t.debugDescription, "SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\n")

        // The default is still not serialized
        let s = try t.serializedBytes()
        XCTAssertEqual([], s)

        assertDecodeSucceeds([]) {$0.defaultInt32 == 41}
        assertDecodeSucceeds([232, 3, 4]) {$0.defaultInt32 == 4}
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\ndefault_int32: 4\n") {(o: inout MessageTestType) in
            o.defaultInt32 = 4
        }
    }

    func testEncoding_defaultInt64() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultInt64, 42)
        XCTAssertEqual(try empty.serializedBytes(), [])
        XCTAssertEqual(try empty.jsonString(), "{}")
        var m = MessageTestType()
        m.defaultInt64 = 1
        XCTAssertEqual(m.defaultInt64, 1)
        XCTAssertEqual(try m.serializedBytes(), [240, 3, 1])

        // Writing a value equal to the default compares as not equal to an unset field
        // But it gets serialized since it was explicitly set
        var a = MessageTestType()
        a.defaultInt64 = 42
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([240, 3, 42], try a.serializedBytes())
        XCTAssertEqual("{\"defaultInt64\":\"42\"}", try a.jsonString())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) {$0.defaultInt64 == 42}
        assertDecodeSucceeds([240, 3, 42]) {$0.defaultInt64 == 42}
        assertDecodeSucceeds([240, 3, 8]) {$0.defaultInt64 == 8}
    }

    func testEncoding_defaultUint32() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultUint32, 43)
        XCTAssertEqual(try empty.serializedData(), Data())

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultUint32 = 43
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([248, 3, 43], try a.serializedBytes())
        XCTAssertEqual("{\"defaultUint32\":43}", try a.jsonString())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) {$0.defaultUint32 == 43}
        assertDecodeSucceeds([248, 3, 43]) {$0.defaultUint32 == 43}
        assertDecodeSucceeds([248, 3, 9]) {$0.defaultUint32 == 9}
    }

    func testEncoding_defaultUint64() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultUint64, 44)
        XCTAssertEqual(try empty.serializedBytes(), [])

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultUint64 = 44
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([128, 4, 44], try a.serializedBytes())
        XCTAssertEqual("{\"defaultUint64\":\"44\"}", try a.jsonString())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) {$0.defaultUint64 == 44}
        assertDecodeSucceeds([128, 4, 44]) {$0.defaultUint64 == 44}
        assertDecodeSucceeds([128, 4, 9]) {$0.defaultUint64 == 9}
    }

    func testEncoding_defaultSint32() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultSint32, -45)
        XCTAssertEqual(try empty.serializedBytes(), [])

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultSint32 = -45
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([136, 4, 89], try a.serializedBytes())
        XCTAssertEqual("{\"defaultSint32\":-45}", try a.jsonString())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) {$0.defaultSint32 == -45}
        assertDecodeSucceeds([136, 4, 89]) {$0.defaultSint32 == -45}
        assertDecodeSucceeds([136, 4, 0]) {$0.defaultSint32 == 0}
        assertDecodeFails([136, 4])
    }

    func testEncoding_defaultSint64() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultSint64, 46)
        XCTAssertEqual(try empty.serializedBytes(), [])

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultSint64 = 46
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([144, 4, 92], try a.serializedBytes())
        XCTAssertEqual("{\"defaultSint64\":\"46\"}", try a.jsonString())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) {$0.defaultSint64 == 46}
        assertDecodeSucceeds([144, 4, 92]) {$0.defaultSint64 == 46}
        assertDecodeSucceeds([144, 4, 0]) {$0.defaultSint64 == 0}
    }

    func testEncoding_defaultFixed32() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultFixed32, 47)
        XCTAssertEqual(try empty.serializedBytes(), [])

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultFixed32 = 47
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([157, 4, 47, 0, 0, 0], try a.serializedBytes())
        XCTAssertEqual("{\"defaultFixed32\":47}", try a.jsonString())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) {$0.defaultFixed32 == 47}
        assertDecodeSucceeds([157, 4, 47, 0, 0, 0]) {$0.defaultFixed32 == 47}
        assertDecodeSucceeds([157, 4, 0, 0, 0, 0]) {$0.defaultFixed32 == 0}
    }

    func testEncoding_defaultFixed64() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultFixed64, 48)
        XCTAssertEqual(try empty.serializedBytes(), [])

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultFixed64 = 48
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([161, 4, 48, 0, 0, 0, 0, 0, 0, 0], try a.serializedBytes())
        XCTAssertEqual("{\"defaultFixed64\":\"48\"}", try a.jsonString())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) {$0.defaultFixed64 == 48}
        assertDecodeSucceeds([161, 4, 48, 0, 0, 0, 0, 0, 0, 0]) {$0.defaultFixed64 == 48}
        assertDecodeSucceeds([161, 4, 0, 0, 0, 0, 0, 0, 0, 0]) {$0.defaultFixed64 == 0}
    }

    func testEncoding_defaultSfixed32() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultSfixed32, 49)
        XCTAssertEqual(try empty.serializedBytes(), [])

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultSfixed32 = 49
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual(Data([173, 4, 49, 0, 0, 0]), try a.serializedData())
        XCTAssertEqual("{\"defaultSfixed32\":49}", try a.jsonString())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) {$0.defaultSfixed32 == 49}
        assertDecodeSucceeds([173, 4, 49, 0, 0, 0]) {$0.defaultSfixed32 == 49}
        assertDecodeSucceeds([173, 4, 0, 0, 0, 0]) {$0.defaultSfixed32 == 0}
    }

    func testEncoding_defaultSfixed64() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultSfixed64, -50)
        XCTAssertEqual(try empty.serializedBytes(), [])

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultSfixed64 = -50
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([177, 4, 206, 255, 255, 255, 255, 255, 255, 255], try a.serializedBytes())
        XCTAssertEqual("{\"defaultSfixed64\":\"-50\"}", try a.jsonString())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) {$0.defaultSfixed64 == -50}
        assertDecodeSucceeds([177, 4, 206, 255, 255, 255, 255, 255, 255, 255]) {$0.defaultSfixed64 == -50}
        assertDecodeSucceeds([177, 4, 0, 0, 0, 0, 0, 0, 0, 0]) {$0.defaultSfixed64 == 0}
    }

    func testEncoding_defaultFloat() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultFloat, 51.5)
        XCTAssertEqual(try empty.serializedBytes(), [])

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultFloat = 51.5
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([189, 4, 0, 0, 78, 66], try a.serializedBytes())
        XCTAssertEqual("{\"defaultFloat\":51.5}", try a.jsonString())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) {$0.defaultFloat == 51.5}
        assertDecodeSucceeds([189, 4, 0, 0, 0, 0]) {$0.defaultFloat == 0}
        assertDecodeSucceeds([189, 4, 0, 0, 78, 66]) {$0.defaultFloat == 51.5}
    }

    func testEncoding_defaultDouble() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultDouble, 52e3)

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultDouble = 52e3
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([193, 4, 0, 0, 0, 0, 0, 100, 233, 64], try a.serializedBytes())
        XCTAssertEqual("{\"defaultDouble\":52000.0}", try a.jsonString())

        var b = MessageTestType()
        b.optionalInt32 = 1
        a.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) {$0.defaultDouble == 52e3}
        assertDecodeSucceeds([193, 4, 0, 0, 0, 0, 0, 0, 0, 0]) {$0.defaultDouble == 0}
        assertDecodeSucceeds([193, 4, 0, 0, 0, 0, 0, 100, 233, 64]) {$0.defaultDouble == 52e3}
    }

    func testEncoding_defaultBool() throws {
        let empty = MessageTestType()
        //XCTAssertEqual(empty.defaultBool!, true)

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultBool = true
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual(try a.serializedBytes(), [200, 4, 1])
        XCTAssertEqual(try a.jsonString(), "{\"defaultBool\":true}")

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertEncode([200, 4, 0]) {(o: inout MessageTestType) in o.defaultBool = false}
        assertJSONEncode("{\"defaultBool\":false}") {(o: inout MessageTestType) in o.defaultBool = false}

        assertDecodeSucceeds([]) {$0.defaultBool == true}
        assertDecodeSucceeds([200, 4, 0]) {$0.defaultBool == false}
        assertDecodeSucceeds([200, 4, 1]) {$0.defaultBool == true}

    }

    func testEncoding_defaultString() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultString, "hello")

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultString = "hello"
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([210, 4, 5, 104, 101, 108, 108, 111], try a.serializedBytes())
        XCTAssertEqual("{\"defaultString\":\"hello\"}", try a.jsonString())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) {$0.defaultString == "hello"}
        assertDecodeSucceeds([210, 4, 1, 97]) {$0.defaultString == "a"}
    }

    func testEncoding_defaultBytes() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultBytes, Data([119, 111, 114, 108, 100]))

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultBytes = Data([119, 111, 114, 108, 100])
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([218, 4, 5, 119, 111, 114, 108, 100], try a.serializedBytes())
        XCTAssertEqual("{\"defaultBytes\":\"d29ybGQ=\"}", try a.jsonString())

        var b = MessageTestType()
        b.optionalInt32 = 1
        a.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) {$0.defaultBytes == Data([119, 111, 114, 108, 100])}
        assertDecodeSucceeds([218, 4, 1, 1]) {$0.defaultBytes == Data([1])}
    }

    func testEncoding_defaultNestedEnum() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultNestedEnum, MessageTestType.NestedEnum.bar)

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultNestedEnum = .bar
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([136, 5, 2], try a.serializedBytes())
        XCTAssertEqual("{\"defaultNestedEnum\":\"BAR\"}", try a.jsonString())

        var b = MessageTestType()
        b.optionalInt32 = 1
        a.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) {$0.defaultNestedEnum == .bar}
        assertDecodeSucceeds([136, 5, 3]) {$0.defaultNestedEnum == .baz}
    }

    func testEncoding_defaultForeignEnum() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultForeignEnum, ProtobufUnittest_ForeignEnum.foreignBar)

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultForeignEnum = .foreignBar
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([144, 5, 5], try a.serializedBytes())
        XCTAssertEqual("{\"defaultForeignEnum\":\"FOREIGN_BAR\"}", try a.jsonString())

        var b = MessageTestType()
        b.optionalInt32 = 1
        a.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) {$0.defaultForeignEnum == .foreignBar}
        assertDecodeSucceeds([144, 5, 6]) {$0.defaultForeignEnum == ProtobufUnittest_ForeignEnum.foreignBaz}
    }

    func testEncoding_defaultImportEnum() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultImportEnum, ProtobufUnittestImport_ImportEnum.importBar)
        assertEncode([152, 5, 9]) {(o: inout MessageTestType) in o.defaultImportEnum = .importBaz}
        assertDecodeSucceeds([]) {$0.defaultImportEnum == .importBar}
        assertDecodeSucceeds([152, 5, 9]) {$0.defaultImportEnum == .importBaz}
    }

    func testEncoding_defaultStringPiece() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultStringPiece, "abc")
        XCTAssertEqual(try empty.serializedBytes(), [])

        var a = empty
        a.defaultStringPiece = "abc"
        XCTAssertEqual([162, 5, 3, 97, 98, 99], try a.serializedBytes())
    }

    func testEncoding_defaultCord() {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultCord, "123")
        XCTAssertEqual(try empty.serializedBytes(), [])

        var a = empty
        a.defaultCord = "123"
        XCTAssertEqual([170, 5, 3, 49, 50, 51], try a.serializedBytes())
    }

    func testEncoding_oneofUint32() throws {
        assertEncode([248, 6, 0]) {(o: inout MessageTestType) in o.oneofUint32 = 0}
        assertDecodeSucceeds([248, 6, 255, 255, 255, 255, 15]) {$0.oneofUint32 == UInt32.max}
        assertDecodeSucceeds([138, 7, 1, 97, 248, 6, 1]) {(o: MessageTestType) in
            if case .oneofUint32? = o.oneofField, o.oneofUint32 == UInt32(1) {
                return true
            }
            return false
        }

        assertDecodeFails([248, 6, 128]) // Bad varint
        // Bad wire types:
        assertDecodeFails([249, 6])
        assertDecodeFails([249, 6, 0])
        assertDecodeFails([250, 6])
        assertDecodesAsUnknownFields([250, 6, 0]) {  // Wrong wire type (length delimited), valid as an unknown field
            $0.oneofField == nil  // oneof doesn't get set.
        }
        let initialMsg = MessageTestType.with { $0.oneofString = "initial" }
        assertMergesAsUnknownFields([250, 6, 0], inTo: initialMsg) {
            $0.oneofString == "initial"   // Shouldn't have gotten cleared.
        }
        assertDecodeFails([251, 6])
        assertDecodeFails([251, 6, 0])
        assertDecodeFails([252, 6])
        assertDecodeFails([252, 6, 0])
        assertDecodeFails([253, 6])
        assertDecodeFails([253, 6, 0])
        assertDecodeFails([254, 6])
        assertDecodeFails([254, 6, 0])
        assertDecodeFails([255, 6])
        assertDecodeFails([255, 6, 0])

        var m = MessageTestType()
        m.oneofUint32 = 77
        XCTAssertEqual(m.debugDescription, "SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noneof_uint32: 77\n")
        var m2 = MessageTestType()
        m2.oneofUint32 = 78
        XCTAssertNotEqual(m.hashValue, m2.hashValue)
    }

    func testEncoding_oneofNestedMessage() {
        assertEncode([130, 7, 2, 8, 1]) {(o: inout MessageTestType) in
            var nested = MessageTestType.NestedMessage()
            nested.bb = 1
            o.oneofNestedMessage = nested
        }
        assertDecodeSucceeds([130, 7, 0]) {(o: MessageTestType) in
            if case .oneofNestedMessage(let m)? = o.oneofField {
                return !m.hasBb
            }
            return false
        }
        assertDecodeSucceeds([248, 6, 0, 130, 7, 2, 8, 1]) {(o: MessageTestType) in
            if case .oneofUint32? = o.oneofField {
                return false
            }
            if case .oneofNestedMessage(let m)? = o.oneofField {
                return m.bb == 1
            }
            return false
        }
    }
    func testEncoding_oneofNestedMessage1() {
        assertDecodeSucceeds([130, 7, 2, 8, 1, 248, 6, 0]) {(o: MessageTestType) in
            if case .oneofUint32? = o.oneofField, o.oneofUint32 == 0 {
                return true
            }
            return false
        }
        // Unkonwn field within nested message should not break decoding
        assertDecodeSucceeds([130, 7, 5, 128, 127, 0, 8, 1, 248, 6, 0]) {(o: MessageTestType) in
            if case .oneofUint32? = o.oneofField, o.oneofUint32 == 0 {
                return true
            }
            return false
        }
    }

    func testEncoding_oneofNestedMessage2() {
        var nested1 = MessageTestType.NestedMessage()
        nested1.bb = 1
        var m = MessageTestType()
        m.oneofNestedMessage = nested1
        XCTAssertEqual(m.debugDescription, "SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noneof_nested_message {\n  bb: 1\n}\n")
        var nested2 = MessageTestType.NestedMessage()
        nested2.bb = 2
        var m2 = MessageTestType()
        m2.oneofNestedMessage = nested2
        XCTAssertNotEqual(m.hashValue, m2.hashValue)
    }

    func testEncoding_oneofNestedMessage9() {
        assertDecodeFails([128, 7])
        assertDecodesAsUnknownFields([128, 7, 0]) {  // Wrong wire type (varint), valid as an unknown field
            $0.oneofField == nil  // oneof doesn't get set.
        }
        let initialMsg = MessageTestType.with { $0.oneofString = "initial" }
        assertMergesAsUnknownFields([128, 7, 0], inTo: initialMsg) {
            $0.oneofString == "initial"   // Shouldn't have gotten cleared.
        }
        assertDecodeFails([129, 7])
        assertDecodeFails([129, 7, 0])
        assertDecodeFails([131, 7])
        assertDecodeFails([131, 7, 0])
        assertDecodeFails([132, 7])
        assertDecodeFails([132, 7, 0])
        assertDecodeFails([133, 7])
        assertDecodeFails([133, 7, 0])
        assertDecodeFails([134, 7])
        assertDecodeFails([134, 7, 0])
        assertDecodeFails([135, 7])
        assertDecodeFails([135, 7, 0])
    }

    func testEncoding_oneofString() {
        assertEncode([138, 7, 1, 97]) {(o: inout MessageTestType) in o.oneofString = "a"}
        assertDecodeSucceeds([138, 7, 1, 97]) {$0.oneofString == "a"}
        assertDecodeSucceeds([138, 7, 0]) {$0.oneofString == ""}
        assertDecodeSucceeds([146, 7, 0, 138, 7, 1, 97]) {(o:MessageTestType) in
            if case .oneofString? = o.oneofField, o.oneofString == "a" {
                return true
            }
            return false
        }
        assertDecodeFails([138, 7, 1]) // Truncated body
        assertDecodeFails([138, 7, 1, 192]) // Malformed UTF-8
        // Bad wire types:
        assertDecodesAsUnknownFields([136, 7, 0]) {  // Wrong wire type (varint), valid as an unknown field
            $0.oneofField == nil  // oneof doesn't get set.
        }
        let initialMsg = MessageTestType.with { $0.oneofUint32 = 123 }
        assertMergesAsUnknownFields([136, 7, 0], inTo: initialMsg) {
            $0.oneofUint32 == 123   // Shouldn't have gotten cleared.
        }
        assertDecodesAsUnknownFields([136, 7, 1]) {  // Wrong wire type (varint), valid as an unknown field
            $0.oneofField == nil  // oneof doesn't get set.
        }
        assertMergesAsUnknownFields([136, 7, 1], inTo: initialMsg) {
            $0.oneofUint32 == 123   // Shouldn't have gotten cleared.
        }
        assertDecodesAsUnknownFields([137, 7, 1, 1, 1, 1, 1, 1, 1, 1]) {  // Wrong wire type (fixed64), valid as an unknown field
            $0.oneofField == nil  // oneof doesn't get set.
        }
        assertMergesAsUnknownFields([137, 7, 1, 1, 1, 1, 1, 1, 1, 1], inTo: initialMsg) {
            $0.oneofUint32 == 123   // Shouldn't have gotten cleared.
        }
        assertDecodeFails([139, 7]) // Wire type 3
        assertDecodeFails([140, 7]) // Wire type 4
        assertDecodeFails([141, 7, 0])  // Wire type 5
        assertDecodesAsUnknownFields([141, 7, 0, 0, 0, 0]) {  // Wrong wire type (fixed32), valid as an unknown field
            $0.oneofField == nil  // oneof doesn't get set.
        }
        assertMergesAsUnknownFields([141, 7, 0, 0, 0, 0], inTo: initialMsg) {
            $0.oneofUint32 == 123   // Shouldn't have gotten cleared.
        }
        assertDecodeFails([142, 7]) // Wire type 6
        assertDecodeFails([142, 7, 0]) // Wire type 6
        assertDecodeFails([143, 7]) // Wire type 7
        assertDecodeFails([143, 7, 0]) // Wire type 7

        var m = MessageTestType()
        m.oneofString = "abc"
        XCTAssertEqual(m.debugDescription, "SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noneof_string: \"abc\"\n")
        var m2 = MessageTestType()
        m2.oneofString = "def"
        XCTAssertNotEqual(m.hashValue, m2.hashValue)
    }

    func testEncoding_oneofBytes() {
        assertEncode([146, 7, 1, 1]) {(o: inout MessageTestType) in o.oneofBytes = Data([1])}
    }
    func testEncoding_oneofBytes2() {
        assertDecodeSucceeds([146, 7, 1, 1]) {(o: MessageTestType) in
            let expectedB = Data([1])
            if case .oneofBytes(let b)? = o.oneofField {
                let s = o.oneofString
                return b == expectedB && s == ""
            }
            return false
        }
    }
    func testEncoding_oneofBytes3() {
        assertDecodeSucceeds([146, 7, 0]) {(o: MessageTestType) in
            let expectedB = Data()
            if case .oneofBytes(let b)? = o.oneofField {
                let s = o.oneofString
                return b == expectedB && s == ""
            }
            return false
        }
    }
    func testEncoding_oneofBytes4() {
        assertDecodeSucceeds([138, 7, 1, 97, 146, 7, 0]) {(o: MessageTestType) in
            let expectedB = Data()
            if case .oneofBytes(let b)? = o.oneofField {
                let s = o.oneofString
                return b == expectedB && s == ""
            }
            return false
        }
    }

    func testEncoding_oneofBytes5() {
        // Setting string and then bytes ends up with bytes but no string
        assertDecodeFails([146, 7])
    }

    func testEncoding_oneofBytes_failures() {
        assertDecodeFails([146, 7, 1])
        // Bad wire types:
        assertDecodeFails([144, 7])
        assertDecodesAsUnknownFields([144, 7, 0]) {  // Wrong wire type (varint), valid as an unknown field
            $0.oneofField == nil  // oneof doesn't get set.
        }
        let initialMsg = MessageTestType.with { $0.oneofString = "initial" }
        assertMergesAsUnknownFields([144, 7, 0], inTo: initialMsg) {
            $0.oneofString == "initial"   // Shouldn't have gotten cleared.
        }
        assertDecodeFails([145, 7])
        assertDecodeFails([145, 7, 0])
        assertDecodeFails([147, 7])
        assertDecodeFails([147, 7, 0])
        assertDecodeFails([148, 7])
        assertDecodeFails([148, 7, 0])
        assertDecodeFails([149, 7])
        assertDecodeFails([149, 7, 0])
        assertDecodeFails([150, 7])
        assertDecodeFails([150, 7, 0])
        assertDecodeFails([151, 7])
        assertDecodeFails([151, 7, 0])
    }

    func testEncoding_oneofBytes_debugDescription() {
        var m = MessageTestType()
        m.oneofBytes = Data([1, 2, 3])

        XCTAssertEqual(m.debugDescription, "SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noneof_bytes: \"\\001\\002\\003\"\n")
        var m2 = MessageTestType()
        m2.oneofBytes = Data([4, 5, 6])
        XCTAssertNotEqual(m.hashValue, m2.hashValue)
    }

    func testDebugDescription() {
        var m = MessageTestType()
        let d = m.debugDescription
        XCTAssertEqual("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\n", d)
        m.optionalInt32 = 7
        XCTAssertEqual("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_int32: 7\n", m.debugDescription)
        m.repeatedString = ["a", "b"]
        XCTAssertEqual("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_int32: 7\nrepeated_string: \"a\"\nrepeated_string: \"b\"\n", m.debugDescription)
    }

    func testDebugDescription2() {
        // Message with only one field
        var m = ProtobufUnittest_ForeignMessage()
        XCTAssertEqual("SwiftProtobufTests.ProtobufUnittest_ForeignMessage:\n", m.debugDescription)
        m.c = 3
        XCTAssertEqual("SwiftProtobufTests.ProtobufUnittest_ForeignMessage:\nc: 3\n", m.debugDescription)
    }

    func testDebugDescription3() {
        // Message with only a single oneof
        var m = ProtobufUnittest_TestOneof()
        XCTAssertEqual("SwiftProtobufTests.ProtobufUnittest_TestOneof:\n", m.debugDescription)
        m.fooInt = 1
        XCTAssertEqual("SwiftProtobufTests.ProtobufUnittest_TestOneof:\nfoo_int: 1\n", m.debugDescription)
        m.fooString = "a"
        XCTAssertEqual("SwiftProtobufTests.ProtobufUnittest_TestOneof:\nfoo_string: \"a\"\n", m.debugDescription)
        var g = ProtobufUnittest_TestOneof.FooGroup()
        g.a = 7
        g.b = "b"
        m.fooGroup = g
        XCTAssertEqual("SwiftProtobufTests.ProtobufUnittest_TestOneof:\nFooGroup {\n  a: 7\n  b: \"b\"\n}\n", m.debugDescription)
    }

    func testDebugDescription4() {
        assertDebugDescription("SwiftProtobufTests.ProtobufUnittest_TestAllTypes:\noptional_int32: 88\nrepeated_int32: 1\nrepeated_int32: 2\nrepeated_int32: 3\nRepeatedGroup {\n  a: 1\n}\nRepeatedGroup {\n  a: 2\n}\n") {(o: inout MessageTestType) in
            o.optionalInt32 = 88
            o.repeatedInt32 = [1, 2, 3]
            var g1 = MessageTestType.RepeatedGroup()
            g1.a = 1
            var g2 = MessageTestType.RepeatedGroup()
            g2.a = 2
            o.repeatedGroup = [g1, g2]
        }
    }

    func testWithFactoryHelper() {
        let m = ProtobufUnittest_ForeignMessage.with { $0.c = 5 }
        XCTAssertEqual(5, m.c)
    }

    func testWithFactoryHelperRethrows() {
        class TestWithFactoryHelperRethrows_Error : Error {}

        let pNoThrow: (inout ProtobufUnittest_ForeignMessage) -> () = { $0.c = 1 }
        let m1 = ProtobufUnittest_ForeignMessage.with(pNoThrow)
        XCTAssertEqual(1, m1.c)

        var populatorRan = false
        let pThrow: (inout ProtobufUnittest_ForeignMessage) throws -> () = {
            $0.c = 2
            populatorRan = true
            throw TestWithFactoryHelperRethrows_Error()
        }

        let m2 = try? ProtobufUnittest_ForeignMessage.with(pThrow)
        XCTAssertNil(m2)
        XCTAssert(populatorRan)
    }

    func testUnknownFields_Success() throws {
        let testInputs: [([UInt8], String)] = [
          ([192, 12, 1], "200: 1"), //  varint of 1.
          ([193, 12, 20, 0, 0, 0, 0, 0, 0, 0], "200: 0x0000000000000014"), // fixed64 of 20
          ([194, 12, 3, 65, 66, 67], "200: \"ABC\""),  // length delimited.
          ([195, 12, 8, 1, 196, 12], "200 {\n  1: 1\n}"), // StartGroup, Field 1: varint of 1, EndGroup.
          ([197, 12, 30, 0, 0, 0], "200: 0x0000001E"),  // fixed32.

          ([192, 12, 129, 1], "200: 129"), //  varint of 129 (two bytes on wire).
          ([195, 12, 11, 8, 1, 12, 196, 12], "200 {\n  1 {\n    1: 1\n  }\n}"), // StartGroup, Field 1: StartGroup, Field 1: varint of 1, EndGroup, EndGroup.
        ]

        // Fields at the top level of the message.
        for (bytes, expectedTextFormat) in testInputs {
            do {
                let msg = try ProtobufUnittest_TestAllTypes(serializedBytes: bytes)
                XCTAssertEqual(msg.unknownFields.data, Data(bytes), "Decoding \(bytes)")
                XCTAssertEqual(msg.textFormatString(), expectedTextFormat + "\n", "Decoding \(bytes)")
                XCTAssertEqual(try msg.serializedData(), Data(bytes), "Decoding \(bytes)")
            } catch let e {
                XCTFail("Decoding \(bytes) failed with error: \(e)")
            }
        }

        // Fields appearing within a message field.
        for (bytes, expectedTextFormat) in testInputs {
            // Hang it in the 'payload' field of NestedTestAllTypes
            let fullBytes = [18, UInt8(bytes.count)] + bytes
            var fullExpectedTextFormat = "payload {\n"
            for line in expectedTextFormat.components(separatedBy: "\n") {
                fullExpectedTextFormat.append("  \(line)\n")
            }
            fullExpectedTextFormat.append("}\n")

            do {
                let msg = try ProtobufUnittest_NestedTestAllTypes(serializedBytes: fullBytes)
                XCTAssertTrue(msg.unknownFields.data.isEmpty)
                XCTAssertEqual(msg.payload.unknownFields.data, Data(bytes), "Decoding \(bytes)")
                XCTAssertEqual(msg.textFormatString(), fullExpectedTextFormat, "Decoding \(bytes)")
                XCTAssertEqual(try msg.serializedData(), Data(fullBytes), "Decoding \(bytes)")
            } catch let e {
                XCTFail("Decoding \(bytes) failed with error: \(e)")
            }
        }

        // Fields appearing within a group field.
        for (bytes, expectedTextFormat) in testInputs {
            // Hang it in the 'OptionalGroup' field of TestAllTypes
            let fullBytes = [131, 1] + bytes + [132, 1]
            var fullExpectedTextFormat = "OptionalGroup {\n"
            for line in expectedTextFormat.components(separatedBy: "\n") {
                fullExpectedTextFormat.append("  \(line)\n")
            }
            fullExpectedTextFormat.append("}\n")
            do {
                let msg = try ProtobufUnittest_TestAllTypes(serializedBytes: fullBytes)
                XCTAssertTrue(msg.unknownFields.data.isEmpty)
                XCTAssertEqual(msg.optionalGroup.unknownFields.data, Data(bytes), "Decoding \(bytes)")
                XCTAssertEqual(msg.textFormatString(), fullExpectedTextFormat, "Decoding \(bytes)")
                XCTAssertEqual(try msg.serializedData(), Data(fullBytes), "Decoding \(bytes)")
            } catch let e {
                XCTFail("Decoding \(bytes) failed with error: \(e)")
            }
        }
    }

    func testUnknownFields_Failures() throws {
        let testInputs: [[UInt8]] = [
          [192, 12], //  varint
          [192, 12, 129], //  varint (should be two bytes)
          [193, 12], // fixed64
          [193, 12, 20, 0, 0, 0, 0, 0, 0], // fixed64
          [194, 12],  // length delimited.
          [194, 12, 3, 65, 66],  // length delimited.
          [195, 12], // StartGroup.
          [195, 12, 8, 1], // StartGroup, Field 1: varint of 1.
          [197, 12],  // fixed32.
          [197, 12, 30, 0, 0],  // fixed32.

          [195, 12, 11], // StartGroup, Field 1: StartGroup.
          [195, 12, 11, 8, 1, 12], // StartGroup, Field 1: StartGroup, Field 1: varint of 1, EndGroup.
          [195, 12, 11, 8, 1, 196, 12], // StartGroup, Field 1: StartGroup, Field 1: varint of 1, EndGroup (but wrong group).
        ]

        // Fields at the top level of the message.
        for bytes in testInputs {
            do {
                _ = try ProtobufUnittest_TestAllTypes(serializedBytes: bytes)
                XCTFail("Decode of \(bytes) should have failed.")
            } catch {
                // Nothing should error!
            }
        }

        // Fields appearing within a message field.
        for bytes in testInputs {
            // Hang it in the 'payload' field of NestedTestAllTypes
            let fullBytes = [18, UInt8(bytes.count)] + bytes
            do {
                _ = try ProtobufUnittest_NestedTestAllTypes(serializedBytes: fullBytes)
                XCTFail("Decode of \(bytes) should have failed.")
            } catch {
                // Nothing should error!
            }
        }

        // Fields appearing within a group field.
        for bytes in testInputs {
            // Hang it after the start of the 'OptionalGroup' field of TestAllTypes
            let fullBytes = [131, 1] + bytes
            do {
                _ = try ProtobufUnittest_TestAllTypes(serializedBytes: fullBytes)
                XCTFail("Decode of \(bytes) should have failed.")
            } catch {
                // Nothing should error!
            }
       }
    }
}
