// Tests/SwiftProtobufTests/Test_Packed.swift - Verify coding/decoding of packed fields
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Proto binary encoding has a special "packed" form that can be used
/// for various numeric fields.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

class Test_Packed: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestPackedTypes

    func testEncoding_packedInt32() {
        assertEncode([210, 5, 16, 255, 255, 255, 255, 7, 0, 128, 128, 128, 128, 248, 255, 255, 255, 255, 1]) {(o: inout MessageTestType) in o.packedInt32 = [Int32.max, 0, Int32.min]}
        assertDecodeSucceeds([210, 5, 6, 8, 247, 255, 255, 255, 15]) {$0.packedInt32 == [8, -9]}
        assertDecodeSucceeds([210, 5, 0]) {$0.packedInt32 == []}
        assertDecodeSucceeds([208, 5, 0, 208, 5, 1]) {$0.packedInt32 == [0, 1]} // Also accept non-packed

        // Truncate 32-bit values that overflow
        assertDecodeSucceeds([210, 5, 11, 8, 247, 255, 255, 255, 255, 255, 255, 255, 255, 1]) {$0.packedInt32 == [8, -9]}

        assertDecodeFails([210, 5, 12, 8, 247, 255, 255, 255, 255, 255, 255, 255, 255, 1])
        assertDecodeFails([210, 5, 10, 8, 247, 255, 255, 255, 255, 255, 255, 255, 255])
        assertDecodeFails([209, 5, 0])
        assertDecodeFails([211, 5, 0])
        assertDecodeFails([212, 5, 0])
        assertDecodeFails([213, 5, 0])
        assertDecodeFails([214, 5, 0])
        assertDecodeFails([215, 5, 0])
    }

    func testEncoding_packedInt64() {
        assertEncode([218, 5, 20, 255, 255, 255, 255, 255, 255, 255, 255, 127, 0, 128, 128, 128, 128, 128, 128, 128, 128, 128, 1]) {(o: inout MessageTestType) in o.packedInt64 = [Int64.max, 0, Int64.min]}
        assertDecodeSucceeds([218, 5, 18, 255, 255, 153, 166, 234, 175, 227, 1, 185, 156, 196, 237, 158, 222, 230, 255, 255, 1]) {$0.packedInt64 == [999999999999999, -111111111111111]}
        assertDecodeSucceeds([218, 5, 18, 255, 255, 153, 166, 234, 175, 227, 1, 185, 156, 196, 237, 158, 222, 230, 255, 255, 1, 218, 5, 18, 255, 255, 153, 166, 234, 175, 227, 1, 185, 156, 196, 237, 158, 222, 230, 255, 255, 1]) {$0.packedInt64 == [999999999999999, -111111111111111, 999999999999999, -111111111111111]}
        assertDecodeSucceeds([218, 5, 0]) {$0.packedInt64 == []}
        assertDecodeFails([218, 5, 19, 255, 255, 153, 166, 234, 175, 227, 1, 185, 156, 196, 237, 158, 222, 230, 255, 255, 1])
        assertDecodeFails([218, 5, 17, 255, 255, 153, 166, 234, 175, 227, 1, 185, 156, 196, 237, 158, 222, 230, 255, 255])
        assertDecodeSucceeds([216, 5, 0]) {$0.packedInt64 == [0]} // Accept non-packed encoding
        assertDecodeFails([217, 5])
        assertDecodeFails([217, 5, 0])
        assertDecodeFails([217, 5, 217, 5])
        assertDecodeFails([219, 5])
        assertDecodeFails([219, 5, 0])
        assertDecodeFails([219, 5, 219, 5])
        assertDecodeFails([220, 5])
        assertDecodeFails([220, 5, 0])
        assertDecodeFails([220, 5, 220, 5])
        assertDecodeFails([221, 5])
        assertDecodeFails([221, 5, 0])
        assertDecodeFails([221, 5, 221, 5])
        assertDecodeFails([222, 5])
        assertDecodeFails([222, 5, 0])
        assertDecodeFails([222, 5, 222, 5])
        assertDecodeFails([223, 5])
        assertDecodeFails([223, 5, 0])
        assertDecodeFails([223, 5, 223, 5])
    }

    func testEncoding_packedUint32() {
        assertEncode([226, 5, 6, 255, 255, 255, 255, 15, 0]) {(o: inout MessageTestType) in o.packedUint32 = [UInt32.max,  UInt32.min]}
        assertDecodeSucceeds([226, 5, 5, 210, 9, 213, 187, 3]) {$0.packedUint32 == [1234, 56789]}
        assertDecodeSucceeds([226, 5, 12, 255, 255, 255, 255, 15, 255, 255, 255, 255, 7, 1, 0]) {$0.packedUint32 == [4294967295, 2147483647, 1, 0]}
        assertDecodeSucceeds([224, 5, 1, 224, 5, 2]) {$0.packedUint32 == [1, 2]}
        // Truncate on 32-bit overflow
        assertDecodeSucceeds([226, 5, 12, 255, 255, 255, 255, 31, 255, 255, 255, 255, 7, 1, 0])  {$0.packedUint32 == [4294967295, 2147483647, 1, 0]}

        assertDecodeFails([226, 5, 4, 255, 255, 255, 255])
        assertDecodeFails([225, 5, 0])
        assertDecodeFails([225, 5, 209, 4])
        assertDecodeFails([227, 5, 0])
        assertDecodeFails([227, 5, 227, 5])
        assertDecodeFails([228, 5, 0])
        assertDecodeFails([228, 5, 228, 5])
        assertDecodeFails([229, 5, 0])
        assertDecodeFails([229, 5, 229, 5])
        assertDecodeFails([230, 5, 0])
        assertDecodeFails([230, 5, 230, 5])
        assertDecodeFails([231, 5, 0])
        assertDecodeFails([231, 5, 231, 5])
    }

    func testEncoding_packedUint64() {
        assertEncode([234, 5, 11, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1, 0]) {(o: inout MessageTestType) in o.packedUint64 = [UInt64.max,  UInt64.min]}
        assertDecodeSucceeds([234, 5, 9, 149, 154, 239, 58, 177, 209, 249, 214, 3]) {$0.packedUint64 == [123456789, 987654321]}
        assertDecodeSucceeds([234, 5, 0]) {$0.packedUint64 == []}
        assertDecodeSucceeds([234, 5, 1, 1, 232, 5, 2]) {$0.packedUint64 == [1, 2]}
        assertDecodeFails([234, 5, 9, 149, 154, 239, 58, 177, 209, 249, 4]) // Truncated body
        assertDecodeFails([234, 5, 8, 149, 154, 239, 58, 177, 209, 249, 214]) // Malformed varint
        assertDecodeFails([233, 5])
        assertDecodeFails([233, 5, 0])
        assertDecodeFails([235, 5])
        assertDecodeFails([235, 5, 0])
        assertDecodeFails([236, 5])
        assertDecodeFails([236, 5, 0])
        assertDecodeFails([237, 5])
        assertDecodeFails([237, 5, 0])
        assertDecodeFails([238, 5])
        assertDecodeFails([238, 5, 0])
        assertDecodeFails([239, 5])
        assertDecodeFails([239, 5, 0])
    }

    func testEncoding_packedSint32() {
        assertEncode([242, 5, 10, 254, 255, 255, 255, 15, 255, 255, 255, 255, 15]) {(o: inout MessageTestType) in o.packedSint32 = [Int32.max,  Int32.min]}
        assertDecodeSucceeds([242, 5, 13, 255, 255, 255, 255, 15, 1, 0, 2, 254, 255, 255, 255, 15]) {$0.packedSint32 == [-2147483648, -1, 0, 1, 2147483647]}
        assertDecodeSucceeds([242, 5, 5, 255, 255, 255, 255, 15, 242, 5, 3, 1, 0, 2, 242, 5, 0, 242, 5, 5, 254, 255, 255, 255, 15]) {$0.packedSint32 == [-2147483648, -1, 0, 1, 2147483647]}
        assertDecodeSucceeds([242, 5, 0]) {$0.packedSint32 == []}
        assertDecodeSucceeds([240, 5, 0]) {$0.packedSint32 == [0]}
        assertDecodeSucceeds([242, 5, 0, 240, 5, 0]) {$0.packedSint32 == [0]}
        // 32-bit overflow truncates
        assertDecodeSucceeds([242, 5, 5, 255, 255, 255, 255, 127]) {$0.packedSint32 == [-2147483648]}

        assertDecodeFails([242, 5, 5, 255, 255, 255, 255]) // truncated body
        assertDecodeFails([242, 5, 4, 255, 255, 255, 255]) // malformed varint
        assertDecodeFails([241, 5])
        assertDecodeFails([241, 5, 0])
        assertDecodeFails([243, 5])
        assertDecodeFails([243, 5, 0])
        assertDecodeFails([244, 5])
        assertDecodeFails([244, 5, 0])
        assertDecodeFails([245, 5])
        assertDecodeFails([245, 5, 0])
        assertDecodeFails([246, 5])
        assertDecodeFails([246, 5, 0])
        assertDecodeFails([247, 5])
        assertDecodeFails([247, 5, 0])
    }

    func testEncoding_packedSint64() {
        assertEncode([250, 5, 20, 254, 255, 255, 255, 255, 255, 255, 255, 255, 1, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1]) {(o: inout MessageTestType) in o.packedSint64 = [Int64.max,  Int64.min]}
        assertDecodeSucceeds([250, 5, 9, 170, 180, 222, 117, 225, 162, 243, 173, 7]) {$0.packedSint64 == [123456789, -987654321]}
        assertDecodeSucceeds([250, 5, 4, 170, 180, 222, 117, 250, 5, 5, 225, 162, 243, 173, 7]) {$0.packedSint64 == [123456789, -987654321]}
        assertDecodeSucceeds([248, 5, 0, 250, 5, 2, 1, 2]) {$0.packedSint64 == [0, -1, 1]}
        assertDecodeSucceeds([250, 5, 0]) {$0.packedSint64 == []}
        assertDecodeFails([250, 5, 9, 170, 180, 222, 117, 225, 162, 243, 7])
        assertDecodeFails([250, 5, 8, 170, 180, 222, 117, 225, 162, 243, 173])
        assertDecodeFails([249, 5])
        assertDecodeFails([249, 5, 0])
        assertDecodeFails([251, 5])
        assertDecodeFails([251, 5, 0])
        assertDecodeFails([252, 5])
        assertDecodeFails([252, 5, 0])
        assertDecodeFails([253, 5])
        assertDecodeFails([253, 5, 0])
        assertDecodeFails([254, 5])
        assertDecodeFails([254, 5, 0])
        assertDecodeFails([255, 5])
        assertDecodeFails([255, 5, 0])
    }

    func testEncoding_packedFixed32() {
        assertEncode([130, 6, 8, 255, 255, 255, 255, 0, 0, 0, 0]) {(o: inout MessageTestType) in o.packedFixed32 = [UInt32.max, UInt32.min]}
        assertDecodeSucceeds([130, 6, 8, 255, 255, 255, 127, 255, 255, 255, 255]) {$0.packedFixed32 == [2147483647, 4294967295]}
        assertDecodeSucceeds([130, 6, 4, 255, 255, 255, 127, 130, 6, 4, 255, 255, 255, 255]) {$0.packedFixed32 == [2147483647, 4294967295]}
        assertDecodeSucceeds([130, 6, 0]) {$0.packedFixed32 == []}
        assertDecodeSucceeds([133, 6, 0, 0, 0, 0]) {$0.packedFixed32 == [0]}
        assertDecodeFails([130, 6, 4, 8, 255, 255, 255, 127, 255, 255, 255])
        assertDecodeFails([130, 6, 7, 255, 255, 255, 127, 255, 255, 255])
        assertDecodeFails([128, 6])
        assertDecodesAsUnknownFields([128, 6, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([128, 6, 0, 0, 0, 0])
        assertDecodeFails([129, 6])
        assertDecodeFails([129, 6, 0])
        assertDecodeFails([129, 6, 0, 0, 0, 0])
        assertDecodeFails([131, 6])
        assertDecodeFails([131, 6, 0])
        assertDecodeFails([131, 6, 0, 0, 0, 0])
        assertDecodeFails([132, 6])
        assertDecodeFails([132, 6, 0])
        assertDecodeFails([132, 6, 0, 0, 0, 0])
        assertDecodeFails([134, 6])
        assertDecodeFails([134, 6, 0])
        assertDecodeFails([134, 6, 0, 0, 0, 0])
        assertDecodeFails([135, 6])
        assertDecodeFails([135, 6, 0])
        assertDecodeFails([135, 6, 0, 0, 0, 0])
    }

    func testEncoding_packedFixed64() {
        assertEncode([138, 6, 16, 255, 255, 255, 255, 255, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0]) {(o: inout MessageTestType) in o.packedFixed64 = [UInt64.max, UInt64.min]}
        assertDecodeSucceeds([138, 6, 24, 255, 255, 255, 127, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255]) {$0.packedFixed64 == [2147483647, 4294967295, 18446744073709551615]}
        assertDecodeSucceeds([138, 6, 8, 255, 255, 255, 127, 0, 0, 0, 0, 138, 6, 16, 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255]) {$0.packedFixed64 == [2147483647, 4294967295, 18446744073709551615]}
        assertDecodeSucceeds([138, 6, 0]) {$0.packedFixed64 == []}
        assertDecodeSucceeds([137, 6, 0, 0, 0, 0, 0, 0, 0, 0]) {$0.packedFixed64 == [0]}
        assertDecodeFails([138, 6, 24, 255, 255, 255, 127, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255])
        assertDecodeFails([138, 6, 23, 255, 255, 255, 127, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255])
        assertDecodeFails([136, 6])
        assertDecodesAsUnknownFields([136, 6, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([136, 6, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([139, 6])
        assertDecodeFails([139, 6, 0])
        assertDecodeFails([139, 6, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([140, 6])
        assertDecodeFails([140, 6, 0])
        assertDecodeFails([140, 6, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([141, 6])
        assertDecodeFails([141, 6, 0])
        assertDecodeFails([141, 6, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([142, 6])
        assertDecodeFails([142, 6, 0])
        assertDecodeFails([142, 6, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([143, 6])
        assertDecodeFails([143, 6, 0])
        assertDecodeFails([143, 6, 0, 0, 0, 0, 0, 0, 0, 0])
    }

    func testEncoding_packedSfixed32() {
        assertEncode([146, 6, 8, 255, 255, 255, 127, 0, 0, 0, 128]) {(o: inout MessageTestType) in o.packedSfixed32 = [Int32.max, Int32.min]}
        assertDecodeSucceeds([146, 6, 12, 0, 0, 0, 128, 1, 0, 0, 0, 255, 255, 255, 127]) {$0.packedSfixed32 == [-2147483648, 1, 2147483647]}
        assertDecodeSucceeds([146, 6, 4, 0, 0, 0, 128, 146, 6, 8, 1, 0, 0, 0, 255, 255, 255, 127]) {$0.packedSfixed32 == [-2147483648, 1, 2147483647]}
        assertDecodeSucceeds([146, 6, 4, 0, 0, 0, 128, 146, 6, 0, 146, 6, 8, 1, 0, 0, 0, 255, 255, 255, 127]) {$0.packedSfixed32 == [-2147483648, 1, 2147483647]}
        assertDecodeSucceeds([149, 6, 1, 0, 0, 0, 146, 6, 4, 7, 0, 0, 0]) {$0.packedSfixed32 == [1, 7]}
        assertDecodeSucceeds([146, 6, 0]) {$0.packedSfixed32 == []}
        assertDecodeFails([146, 6, 12, 0, 0, 0, 128, 1, 0, 0, 0, 255, 255, 255])
        assertDecodeFails([146, 6, 11, 0, 0, 0, 128, 1, 0, 0, 0, 255, 255, 255])
        assertDecodesAsUnknownFields([144, 6, 5])  // Wrong wire type (varint), valid as an unknown field
        assertDecodesAsUnknownFields([144, 6, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([144, 6, 0, 0, 0, 0])
        assertDecodeFails([145, 6])
        assertDecodeFails([145, 6, 0])
        assertDecodeFails([145, 6, 0, 0, 0, 0])
        assertDecodeFails([147, 6])
        assertDecodeFails([147, 6, 0])
        assertDecodeFails([147, 6, 0, 0, 0, 0])
        assertDecodeFails([148, 6])
        assertDecodeFails([148, 6, 0])
        assertDecodeFails([148, 6, 0, 0, 0, 0])
        assertDecodeFails([150, 6])
        assertDecodeFails([150, 6, 0])
        assertDecodeFails([150, 6, 0, 0, 0, 0])
        assertDecodeFails([151, 6])
        assertDecodeFails([151, 6, 0])
        assertDecodeFails([151, 6, 0, 0, 0, 0])
    }

    func testEncoding_packedSfixed64() {
        assertEncode([154, 6, 16, 255, 255, 255, 255, 255, 255, 255, 127, 0, 0, 0, 0, 0, 0, 0, 128]) {(o: inout MessageTestType) in o.packedSfixed64 = [Int64.max, Int64.min]}
        assertDecodeSucceeds([154, 6, 32,  0, 0, 0, 0, 0, 0, 0, 128, 255, 255, 255, 127, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 127]) {$0.packedSfixed64 == [-9223372036854775808, 2147483647, 4294967295, 9223372036854775807]}
        assertDecodeSucceeds([154, 6, 8,  0, 0, 0, 0, 0, 0, 0, 128, 154, 6, 0, 154, 6, 16, 255, 255, 255, 127, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0, 154, 6, 8, 255, 255, 255, 255, 255, 255, 255, 127]) {$0.packedSfixed64 == [-9223372036854775808, 2147483647, 4294967295, 9223372036854775807]}
        assertDecodeSucceeds([154, 6, 0]) {$0.packedSfixed64 == []}
        assertDecodeSucceeds([153, 6, 3, 0, 0, 0, 0, 0, 0, 0]) {$0.packedSfixed64 == [3]}
        assertDecodeFails([154, 6, 33,  0, 0, 0, 0, 0, 0, 0, 128, 255, 255, 255, 127, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 127])
        assertDecodeFails([154, 6, 32,  0, 0, 0, 0, 0, 0, 0, 128, 255, 255, 255, 127, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255])
        assertDecodeFails([154, 6, 31,  0, 0, 0, 0, 0, 0, 0, 128, 255, 255, 255, 127, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255])
        assertDecodeFails([152, 6])
        assertDecodesAsUnknownFields([152, 6, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([152, 6, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([155, 6])
        assertDecodeFails([155, 6, 0])
        assertDecodeFails([155, 6, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([156, 6])
        assertDecodeFails([156, 6, 0])
        assertDecodeFails([156, 6, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([157, 6])
        assertDecodeFails([157, 6, 0])
        assertDecodeFails([157, 6, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([158, 6])
        assertDecodeFails([158, 6, 0])
        assertDecodeFails([158, 6, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([159, 6])
        assertDecodeFails([159, 6, 0])
        assertDecodeFails([159, 6, 0, 0, 0, 0, 0, 0, 0, 0])
    }

    func testEncoding_packedFloat() {
        assertEncode([162, 6, 8, 0, 0, 0, 63, 0, 0, 128, 62]) {(o: inout MessageTestType) in o.packedFloat = [0.5, 0.25]}
        assertDecodeSucceeds([162, 6, 8, 0, 0, 0, 63, 0, 0, 128, 62]) {$0.packedFloat == [0.5, 0.25]}
        assertDecodeSucceeds([162, 6, 4, 0, 0, 0, 63, 162, 6, 4, 0, 0, 128, 62]) {$0.packedFloat == [0.5, 0.25]}
        assertDecodeSucceeds([165, 6, 0, 0, 0, 63, 162, 6, 4, 0, 0, 128, 62]) {$0.packedFloat == [0.5, 0.25]}
        assertDecodeSucceeds([162, 6, 4, 0, 0, 0, 63, 165, 6, 0, 0, 128, 62]) {$0.packedFloat == [0.5, 0.25]}
        assertDecodeSucceeds([165, 6, 0, 0, 0, 63, 165, 6, 0, 0, 128, 62]) {$0.packedFloat == [0.5, 0.25]}
        assertDecodeSucceeds([162, 6, 0]) {$0.packedFloat == []}
        assertDecodeFails([162, 6, 8, 0, 0, 0, 63, 0, 0, 128])
        assertDecodeFails([162, 6, 7, 0, 0, 0, 63, 0, 0, 128])
        assertDecodeFails([160, 6]) // Cannot use wire type 0
        assertDecodeFails([161, 6]) // Cannot use wire type 1
        assertDecodeFails([163, 6]) // Cannot use wire type 3
        assertDecodeFails([164, 6]) // Cannot use wire type 4
        assertDecodeFails([166, 6]) // Cannot use wire type 6
        assertDecodeFails([167, 6]) // Cannot use wire type 7
    }

    func testEncoding_packedDouble() {
        assertEncode([170, 6, 16, 0, 0, 0, 0, 0, 0, 224, 63, 0, 0, 0, 0, 0, 0, 208, 63]) {(o: inout MessageTestType) in o.packedDouble = [0.5, 0.25]}
        assertDecodeSucceeds([170, 6, 16, 0, 0, 0, 0, 0, 0, 224, 63, 0, 0, 0, 0, 0, 0, 208, 63]) {$0.packedDouble == [0.5, 0.25]}
        assertDecodeSucceeds([170, 6, 0]) {$0.packedDouble == []}
        assertDecodeFails([170, 6, 16, 0, 0, 0, 0, 0, 0, 224, 63, 0, 0, 0, 0, 0, 0, 208])
        assertDecodeFails([170, 6, 15, 0, 0, 0, 0, 0, 0, 224, 63, 0, 0, 0, 0, 0, 0, 208])
        assertDecodeFails([170, 6, 16, 0, 0, 0, 0, 0, 0, 224, 63])
        assertDecodeSucceeds([169, 6, 0, 0, 0, 0, 0, 0, 224, 63, 169, 6, 0, 0, 0, 0, 0, 0, 208, 63]) {$0.packedDouble == [0.5, 0.25]}
        assertDecodeSucceeds([169, 6, 0, 0, 0, 0, 0, 0, 224, 63, 170, 6, 8, 0, 0, 0, 0, 0, 0, 208, 63]) {$0.packedDouble == [0.5, 0.25]}
        assertDecodeSucceeds([170, 6, 8, 0, 0, 0, 0, 0, 0, 224, 63, 169, 6, 0, 0, 0, 0, 0, 0, 208, 63]) {$0.packedDouble == [0.5, 0.25]}
        assertDecodeSucceeds([170, 6, 8, 0, 0, 0, 0, 0, 0, 224, 63, 170, 6, 8, 0, 0, 0, 0, 0, 0, 208, 63]) {$0.packedDouble == [0.5, 0.25]}
        assertDecodeFails([168, 6])
        assertDecodesAsUnknownFields([168, 6, 0])  // Wrong wire type (varint), valid as an unknown field
        assertDecodeFails([168, 6, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([171, 6])
        assertDecodeFails([171, 6, 0])
        assertDecodeFails([171, 6, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([172, 6])
        assertDecodeFails([172, 6, 0])
        assertDecodeFails([172, 6, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([173, 6])
        assertDecodeFails([173, 6, 0])
        assertDecodeFails([173, 6, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([174, 6])
        assertDecodeFails([174, 6, 0])
        assertDecodeFails([174, 6, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([175, 6])
        assertDecodeFails([175, 6, 0])
        assertDecodeFails([175, 6, 0, 0, 0, 0, 0, 0, 0, 0])
    }

    func testEncoding_packedBool() {
        assertEncode([178, 6, 4, 1, 0, 0, 1]) {(o: inout MessageTestType) in o.packedBool = [true, false, false, true]}
        assertDecodeSucceeds([178, 6, 4, 1, 0, 0, 1]) {$0.packedBool == [true, false, false, true]}
        assertDecodeSucceeds([178, 6, 5, 255, 1, 0, 0, 1]) {$0.packedBool == [true, false, false, true]}
        assertDecodeSucceeds([178, 6, 5, 1, 128, 0, 0, 1]) {$0.packedBool == [true, false, false, true]}
        assertDecodeSucceeds([178, 6, 14, 1, 128, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 127]) {$0.packedBool == [true, false, false, true]}
        assertDecodeSucceeds([178, 6, 1, 1, 178, 6, 0, 178, 6, 3, 0, 0, 1]) {$0.packedBool == [true, false, false, true]}
        assertDecodeSucceeds([178, 6, 0]) {$0.packedBool == []}
        assertDecodeSucceeds([176, 6, 0]) {$0.packedBool == [false]}
        assertDecodeSucceeds([178, 6, 2, 0, 1, 176, 6, 0]) {$0.packedBool == [false, true, false]}
        assertDecodeFails([178, 6, 4, 1, 0, 0])

        assertDecodeFails([178, 6, 3, 1, 0, 128])
        assertDecodeFails([178, 6, 13, 1, 0, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 1])
        assertDecodeFails([177, 6])
        assertDecodeFails([177, 6, 0])
        assertDecodeFails([179, 6])
        assertDecodeFails([179, 6, 0])
        assertDecodeFails([180, 6])
        assertDecodeFails([180, 6, 0])
        assertDecodeFails([181, 6])
        assertDecodeFails([181, 6, 0])
        assertDecodeFails([182, 6])
        assertDecodeFails([182, 6, 0])
        assertDecodeFails([183, 6])
        assertDecodeFails([183, 6, 0])
    }

    func testEncoding_packedEnum() throws {
        assertEncode([186, 6, 2, 5, 4]) {(o: inout MessageTestType) in o.packedEnum = [.foreignBar, .foreignFoo]}
        assertDecodeSucceeds([186, 6, 2, 4, 5]) {$0.packedEnum == [.foreignFoo, .foreignBar]}
        assertDecodeSucceeds([186, 6, 0]) {$0.packedEnum == []}
        assertDecodeSucceeds([186, 6, 1, 5, 186, 6, 0, 186, 6, 2, 132, 0]) {$0.packedEnum == [.foreignBar, .foreignFoo]}
        // Packed enums can be stored as plain repeated
        assertDecodeSucceeds([186, 6, 2, 4, 6, 184, 6, 5]) {$0.packedEnum == [.foreignFoo, .foreignBaz, .foreignBar]}
        // Proto2 converts unrecognized enum values into unknowns
        assertDecodeSucceeds([186, 6, 2, 6, 99]) {$0.packedEnum == [.foreignBaz]}
        
        // Unknown enums within packed become separate unknown entries
        do {
            let decoded1 = try ProtobufUnittest_TestPackedTypes(serializedData: Data([186, 6, 3, 4, 99, 6]))
            XCTAssertEqual(decoded1.packedEnum, [.foreignFoo, .foreignBaz])
            let recoded1 = try decoded1.serializedBytes()
            XCTAssertEqual(recoded1, [186, 6, 2, 4, 6, 186, 6, 1, 99])
        } catch let e {
            XCTFail("Decode failed: \(e)")
        }

        assertDecodeFails([186, 6, 3, 0, 1])
        assertDecodeFails([186, 6, 2, 0, 129])
        assertDecodeFails([185, 6])
        assertDecodeFails([185, 6, 0])
        assertDecodeFails([187, 6])
        assertDecodeFails([187, 6, 0])
        assertDecodeFails([188, 6])
        assertDecodeFails([188, 6, 0])
        assertDecodeFails([189, 6])
        assertDecodeFails([189, 6, 0])
        assertDecodeFails([190, 6])
        assertDecodeFails([190, 6, 0])
        assertDecodeFails([191, 6])
        assertDecodeFails([191, 6, 0])
    }
}


