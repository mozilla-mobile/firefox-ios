// Tests/SwiftProtobufTests/Test_Unknown_proto2.swift - Exercise unknown field handling for proto2 messages
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Proto2 messages preserve unknown fields when decoding and recoding binary
/// messages, but drop unknown fields when decoding and recoding JSON format.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

/*
 * Verify that unknown fields are correctly preserved by
 * proto2 messages.
 */

class Test_Unknown_proto2: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestEmptyMessage

    /// Verify that json decode ignores the provided fields but otherwise succeeds
    func assertJSONIgnores(_ json: String, file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            var options = JSONDecodingOptions()
            options.ignoreUnknownFields = true
            let empty = try ProtobufUnittest_TestEmptyMessage(jsonString: json, options: options)
            do {
                let json = try empty.jsonString()
                XCTAssertEqual("{}", json, file: file, line: line)
            } catch let e {
                XCTFail("Recoding empty threw error \(e)", file: file, line: line)
            }
        } catch {
            XCTFail("Error decoding into an empty message \(json)", file: file, line: line)
        }
    }

    // Binary PB coding preserves unknown fields for proto2
    func testBinaryPB() {
        func assertRecodes(_ protobufBytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
            do {
                let empty = try ProtobufUnittest_TestEmptyMessage(serializedData: Data(protobufBytes))
                do {
                    let pb = try empty.serializedData()
                    XCTAssertEqual(Data(protobufBytes), pb, file: file, line: line)
                } catch {
                    XCTFail("Recoding empty failed", file: file, line: line)
                }
            } catch {
                XCTFail("Decoding threw error \(protobufBytes)", file: file, line: line)
            }
        }
        func assertFails(_ protobufBytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
            XCTAssertThrowsError(try ProtobufUnittest_TestEmptyMessage(serializedData: Data(protobufBytes)), file: file, line: line)
        }
        // Well-formed input should decode/recode as-is; malformed input should fail to decode
        assertFails([0]) // Invalid field number
        assertFails([0, 0])
        assertFails([1]) // Invalid field number
        assertFails([2]) // Invalid field number
        assertFails([3]) // Invalid field number
        assertFails([4]) // Invalid field number
        assertFails([5]) // Invalid field number
        assertFails([6]) // Invalid field number
        assertFails([7]) // Invalid field number
        assertFails([8]) // Varint field #1 but no varint body
        assertRecodes([8, 0])
        assertFails([8, 128]) // Truncated varint
        assertRecodes([9, 0, 0, 0, 0, 0, 0, 0, 0])
        assertFails([9, 0, 0, 0, 0, 0, 0, 0]) // Truncated 64-bit field
        assertFails([9, 0, 0, 0, 0, 0, 0])
        assertFails([9, 0, 0, 0, 0, 0])
        assertFails([9, 0, 0, 0, 0])
        assertFails([9, 0, 0, 0])
        assertFails([9, 0, 0])
        assertFails([9, 0])
        assertFails([9])
        assertFails([10]) // Length-delimited field but no length
        assertRecodes([10, 0]) // Valid 0-length field
        assertFails([10, 1]) // Length 1 but truncated
        assertRecodes([10, 1, 2]) // Length 1 with 1 byte
        assertFails([10, 2, 1]) // Length 2 truncated
        assertFails([11]) // Start group #1 but no end group
        assertRecodes([11, 12]) // Start/end group #1
        assertFails([12]) // Bare end group
        assertRecodes([13, 0, 0, 0, 0])
        assertFails([13, 0, 0, 0])
        assertFails([13, 0, 0])
        assertFails([13, 0])
        assertFails([13])
        assertFails([14])
        assertFails([15])
        assertRecodes([248, 255, 255, 255, 15, 0]) // Maximum field number
        assertFails([128, 128, 128, 128, 16, 0]) // Out-of-range field number
        assertFails([248, 255, 255, 255, 127, 0]) // Out-of-range field number
    }

    // JSON coding drops unknown fields for both proto2 and proto3
    func testJSON() {
        // Unknown fields should be ignored if they are well-formed JSON
        assertJSONIgnores("{\"unknown\":7}")
        assertJSONIgnores("{\"unknown\":null}")
        assertJSONIgnores("{\"unknown\":false}")
        assertJSONIgnores("{\"unknown\":true}")
        assertJSONIgnores("{\"unknown\":  7.0}")
        assertJSONIgnores("{\"unknown\": -3.04}")
        assertJSONIgnores("{\"unknown\":  -7.0e-55}")
        assertJSONIgnores("{\"unknown\":  7.308e+8}")
        assertJSONIgnores("{\"unknown\": \"hi!\"}")
        assertJSONIgnores("{\"unknown\": []}")
        assertJSONIgnores("{\"unknown\": [3, 4, 5]}")
        assertJSONIgnores("{\"unknown\": [[3], [4], [5, [6, [7], 8, null, \"no\"]]]}")
        assertJSONIgnores("{\"unknown\": [3, {}, \"5\"]}")
        assertJSONIgnores("{\"unknown\": {}}")
        assertJSONIgnores("{\"unknown\": {\"foo\": 1}}")
        assertJSONIgnores("{\"unknown\": 7, \"also_unknown\": 8}")
        assertJSONIgnores("{\"unknown\": 7, \"unknown\": 8}") // ???

        // Badly formed JSON should fail to decode, even in unknown sections
        var options = JSONDecodingOptions()
        options.ignoreUnknownFields = true
        assertJSONDecodeFails("{\"unknown\":  1e999}", options: options)
        assertJSONDecodeFails("{\"unknown\": \"hi!\"", options: options)
        assertJSONDecodeFails("{\"unknown\": \"hi!}", options: options)
        assertJSONDecodeFails("{\"unknown\": qqq }", options: options)
        assertJSONDecodeFails("{\"unknown\": { }", options: options)
        assertJSONDecodeFails("{\"unknown\": [ }", options: options)
        assertJSONDecodeFails("{\"unknown\": { ]}", options: options)
        assertJSONDecodeFails("{\"unknown\": ]}", options: options)
        assertJSONDecodeFails("{\"unknown\": null true}", options: options)
        assertJSONDecodeFails("{\"unknown\": nulll }", options: options)
        assertJSONDecodeFails("{\"unknown\": nul }", options: options)
        assertJSONDecodeFails("{\"unknown\": Null }", options: options)
        assertJSONDecodeFails("{\"unknown\": NULL }", options: options)
        assertJSONDecodeFails("{\"unknown\": True }", options: options)
        assertJSONDecodeFails("{\"unknown\": False }", options: options)
        assertJSONDecodeFails("{\"unknown\": nan }", options: options)
        assertJSONDecodeFails("{\"unknown\": NaN }", options: options)
        assertJSONDecodeFails("{\"unknown\": Infinity }", options: options)
        assertJSONDecodeFails("{\"unknown\": infinity }", options: options)
        assertJSONDecodeFails("{\"unknown\": Inf }", options: options)
        assertJSONDecodeFails("{\"unknown\": inf }", options: options)
        assertJSONDecodeFails("{\"unknown\": 1}}", options: options)
        assertJSONDecodeFails("{\"unknown\": {1, 2}}", options: options)
        assertJSONDecodeFails("{\"unknown\": 1.2.3.4.5}", options: options)
        assertJSONDecodeFails("{\"unknown\": -.04}", options: options)
        assertJSONDecodeFails("{\"unknown\": -19.}", options: options)
        assertJSONDecodeFails("{\"unknown\": -9.3e+}", options: options)
        assertJSONDecodeFails("{\"unknown\": 1 2 3}", options: options)
        assertJSONDecodeFails("{\"unknown\": { true false }}", options: options)
        assertJSONDecodeFails("{\"unknown\"}", options: options)
        assertJSONDecodeFails("{\"unknown\": }", options: options)
        assertJSONDecodeFails("{\"unknown\", \"a\": 1}", options: options)
    }


    func assertUnknownFields(_ message: Message, _ bytes: [UInt8], line: UInt = #line) {
        XCTAssertEqual(message.unknownFields.data, Data(bytes), line: line)
    }

    func test_MessageNoStorageClass() throws {
        var msg1 = ProtobufUnittest_Msg2NoStorage()
        assertUnknownFields(msg1, [])

        try msg1.merge(serializedData: Data([24, 1]))  // Field 3, varint
        assertUnknownFields(msg1, [24, 1])

        var msg2 = msg1
        assertUnknownFields(msg2, [24, 1])
        assertUnknownFields(msg1, [24, 1])

        try msg2.merge(serializedData: Data([34, 1, 52]))   // Field 4, length delimted
        assertUnknownFields(msg2, [24, 1, 34, 1, 52])
        assertUnknownFields(msg1, [24, 1])

        try msg1.merge(serializedData: Data([61, 7, 0, 0, 0]))  // Field 7, 32-bit value
        assertUnknownFields(msg2, [24, 1, 34, 1, 52])
        assertUnknownFields(msg1, [24, 1, 61, 7, 0, 0, 0])
    }

    func test_MessageUsingStorageClass() throws {
        var msg1 = ProtobufUnittest_Msg2UsesStorage()
        assertUnknownFields(msg1, [])

        try msg1.merge(serializedData: Data([24, 1]))  // Field 3, varint
        assertUnknownFields(msg1, [24, 1])

        var msg2 = msg1
        assertUnknownFields(msg2, [24, 1])
        assertUnknownFields(msg1, [24, 1])

        try msg2.merge(serializedData: Data([34, 1, 52]))   // Field 4, length delimted
        assertUnknownFields(msg2, [24, 1, 34, 1, 52])
        assertUnknownFields(msg1, [24, 1])

        try msg1.merge(serializedData: Data([61, 7, 0, 0, 0]))  // Field 7, 32-bit value
        assertUnknownFields(msg2, [24, 1, 34, 1, 52])
        assertUnknownFields(msg1, [24, 1, 61, 7, 0, 0, 0])
    }
}
