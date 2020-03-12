// Tests/SwiftProtobufTests/Test_Map_JSON.swift - Verify JSON coding for maps
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Exercise JSON map handling.  In particular, JSON requires
/// that dictionary keys are quoted, so maps keyed by numeric
/// types need some attention.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest


// TODO: Testing encoding needs some help, since the order of
// entries isn't well-defined.

class Test_Map_JSON: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestMap

    func testMapInt32Int32() throws {
        assertJSONEncode("{\"mapInt32Int32\":{\"1\":2}}") {(o: inout MessageTestType) in
            o.mapInt32Int32 = [1:2]
        }

        var o = MessageTestType()
        o.mapInt32Int32 = [1:2, 3:4]
        let json = try o.jsonString()
        // Must be in one of these two orders
        if (json != "{\"mapInt32Int32\":{\"1\":2,\"3\":4}}"
            && json != "{\"mapInt32Int32\":{\"3\":4,\"1\":2}}") {
            XCTFail("Got:  \(json)")
        }

        // Decode should work same regardless of order
        assertJSONDecodeSucceeds("{\"mapInt32Int32\":{\"1\":2, \"3\":4}}") {$0.mapInt32Int32 == [1:2, 3:4]}
        assertJSONDecodeSucceeds("{\"mapInt32Int32\":{\"3\":4,\"1\":2}}") {$0.mapInt32Int32 == [1:2, 3:4]}
        // In range values succeed
        assertJSONDecodeSucceeds("{\"mapInt32Int32\":{\"2147483647\":2147483647}}") {
            $0.mapInt32Int32 == [2147483647:2147483647]
        }
        assertJSONDecodeSucceeds("{\"mapInt32Int32\":{\"-2147483648\":-2147483648}}") {
            $0.mapInt32Int32 == [-2147483648:-2147483648]
        }
        // Out of range values fail
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"2147483647\":2147483648}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"2147483648\":2147483647}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"-2147483649\":2147483647}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"2147483647\":-2147483649}}")
        // JSON RFC does not allow trailing comma
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"3\":4,\"1\":2,}}")
        // Int values should support being quoted or unquoted
        assertJSONDecodeSucceeds("{\"mapInt32Int32\":{\"1\":\"2\", \"3\":4}}") {$0.mapInt32Int32 == [1:2, 3:4]}
        // Space should not affect result
        assertJSONDecodeSucceeds(" { \"mapInt32Int32\" : { \"1\" : \"2\" , \"3\" : 4 } } ") {$0.mapInt32Int32 == [1:2, 3:4]}
        // Keys must be quoted, else decode fails
        assertJSONDecodeFails("{\"mapInt32Int32\":{1:2, 3:4}}")
        // Fail on other syntax errors:
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"1\":2,, \"3\":4}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"1\",\"4\"}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"1\":, \"3\":4}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"1\":2,,}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"1\":2}} X")
    }

    func testMapInt64Int64() throws {
        assertJSONEncode("{\"mapInt64Int64\":{\"1\":\"2\"}}") {(o: inout MessageTestType) in
            o.mapInt64Int64 = [1:2]
        }
        assertJSONEncode("{\"mapInt64Int64\":{\"9223372036854775807\":\"-9223372036854775808\"}}") {(o: inout MessageTestType) in
            o.mapInt64Int64 = [9223372036854775807: -9223372036854775808]
        }
        assertJSONDecodeSucceeds("{\"mapInt64Int64\":{\"9223372036854775807\":-9223372036854775808}}") {
            $0.mapInt64Int64 == [9223372036854775807: -9223372036854775808]
        }
        assertJSONDecodeFails("{\"mapInt64Int64\":{\"9223372036854775807\":9223372036854775808}}")
    }

    func testMapUInt32UInt32() throws {
        assertJSONEncode("{\"mapUint32Uint32\":{\"1\":2}}") {(o: inout MessageTestType) in
            o.mapUint32Uint32 = [1:2]
        }
        assertJSONDecodeFails("{\"mapUint32Uint32\":{\"1\":-2}}")
        assertJSONDecodeFails("{\"mapUint32Uint32\":{\"-1\":2}}")
        assertJSONDecodeFails("{\"mapUint32Uint32\":{1:2}}")
        assertJSONDecodeSucceeds("{\"mapUint32Uint32\":{\"1\":\"2\"}}") {
            $0.mapUint32Uint32 == [1:2]
        }
    }

    func testMapUInt64UInt64() throws {
        assertJSONEncode("{\"mapUint64Uint64\":{\"1\":\"2\"}}") {(o: inout MessageTestType) in
            o.mapUint64Uint64 = [1:2]
        }
        assertJSONEncode("{\"mapUint64Uint64\":{\"1\":\"18446744073709551615\"}}") {(o: inout MessageTestType) in
            o.mapUint64Uint64 = [1:18446744073709551615 as UInt64]
        }
        assertJSONDecodeSucceeds("{\"mapUint64Uint64\":{\"1\":18446744073709551615}}") {
            $0.mapUint64Uint64 == [1:18446744073709551615 as UInt64]
        }
        assertJSONDecodeFails("{\"mapUint64Uint64\":{\"1\":\"18446744073709551616\"}}")
        assertJSONDecodeFails("{\"mapUint64Uint64\":{1:\"18446744073709551615\"}}")
    }

    func testMapSInt32SInt32() throws {
        assertJSONEncode("{\"mapSint32Sint32\":{\"1\":2}}") {(o: inout MessageTestType) in
            o.mapSint32Sint32 = [1:2]
        }
        assertJSONDecodeSucceeds("{\"mapSint32Sint32\":{\"1\":\"-2\"}}") {
            $0.mapSint32Sint32 == [1:-2]
        }
        assertJSONDecodeFails("{\"mapSint32Sint32\":{1:-2}}")
        // In range values succeed
        assertJSONDecodeSucceeds("{\"mapSint32Sint32\":{\"2147483647\":2147483647}}") {
            $0.mapSint32Sint32 == [2147483647:2147483647]
        }
        assertJSONDecodeSucceeds("{\"mapSint32Sint32\":{\"-2147483648\":-2147483648}}") {
            $0.mapSint32Sint32 == [-2147483648:-2147483648]
        }
        // Out of range values fail
        assertJSONDecodeFails("{\"mapSint32Sint32\":{\"2147483647\":2147483648}}")
        assertJSONDecodeFails("{\"mapSint32Sint32\":{\"2147483648\":2147483647}}")
        assertJSONDecodeFails("{\"mapSint32Sint32\":{\"-2147483649\":2147483647}}")
        assertJSONDecodeFails("{\"mapSint32Sint32\":{\"2147483647\":-2147483649}}")
    }

    func testMapSInt64SInt64() throws {
        assertJSONEncode("{\"mapSint64Sint64\":{\"1\":\"2\"}}") {(o: inout MessageTestType) in
            o.mapSint64Sint64 = [1:2]
        }
        assertJSONEncode("{\"mapSint64Sint64\":{\"9223372036854775807\":\"-9223372036854775808\"}}") {(o: inout MessageTestType) in
            o.mapSint64Sint64 = [9223372036854775807: -9223372036854775808]
        }
        assertJSONDecodeSucceeds("{\"mapSint64Sint64\":{\"9223372036854775807\":-9223372036854775808}}") {
            $0.mapSint64Sint64 == [9223372036854775807: -9223372036854775808]
        }
        assertJSONDecodeFails("{\"mapSint64Sint64\":{\"9223372036854775807\":9223372036854775808}}")
    }

    func testFixed32Fixed32() throws {
        assertJSONEncode("{\"mapFixed32Fixed32\":{\"1\":2}}") {(o: inout MessageTestType) in
            o.mapFixed32Fixed32 = [1:2]
        }
        assertJSONEncode("{\"mapFixed32Fixed32\":{\"0\":0}}") {(o: inout MessageTestType) in
            o.mapFixed32Fixed32 = [0:0]
        }
        // In range values succeed
        assertJSONDecodeSucceeds("{\"mapFixed32Fixed32\":{\"4294967295\":4294967295}}") {
            $0.mapFixed32Fixed32 == [4294967295:4294967295]
        }
        // Out of range values fail
        assertJSONDecodeFails("{\"mapFixed32Fixed32\":{\"4294967295\":4294967296}}")
        assertJSONDecodeFails("{\"mapFixed32Fixed32\":{\"4294967296\":4294967295}}")
        assertJSONDecodeFails("{\"mapFixed32Fixed32\":{\"-1\":4294967295}}")
        assertJSONDecodeFails("{\"mapFixed32Fixed32\":{\"4294967295\":-1}}")
    }

    func testFixed64Fixed64() throws {
        assertJSONEncode("{\"mapFixed64Fixed64\":{\"1\":\"2\"}}") {(o: inout MessageTestType) in
            o.mapFixed64Fixed64 = [1:2]
        }
        assertJSONEncode("{\"mapFixed64Fixed64\":{\"1\":\"18446744073709551615\"}}") {(o: inout MessageTestType) in
            o.mapFixed64Fixed64 = [1:18446744073709551615 as UInt64]
        }
        assertJSONDecodeSucceeds("{\"mapFixed64Fixed64\":{\"1\":18446744073709551615}}") {
            $0.mapFixed64Fixed64 == [1:18446744073709551615 as UInt64]
        }
        assertJSONDecodeFails("{\"mapFixed64Fixed64\":{\"1\":\"18446744073709551616\"}}")
        assertJSONDecodeFails("{\"mapFixed64Fixed64\":{1:\"18446744073709551615\"}}")
    }

    func testSFixed32SFixed32() throws {
        assertJSONEncode("{\"mapSfixed32Sfixed32\":{\"1\":2}}") {(o: inout MessageTestType) in
            o.mapSfixed32Sfixed32 = [1:2]
        }
        // In range values succeed
        assertJSONDecodeSucceeds("{\"mapSfixed32Sfixed32\":{\"2147483647\":2147483647}}") {
            $0.mapSfixed32Sfixed32 == [2147483647:2147483647]
        }
        assertJSONDecodeSucceeds("{\"mapSfixed32Sfixed32\":{\"-2147483648\":-2147483648}}") {
            $0.mapSfixed32Sfixed32 == [-2147483648:-2147483648]
        }
        // Out of range values fail
        assertJSONDecodeFails("{\"mapSfixed32Sfixed32\":{\"2147483647\":2147483648}}")
        assertJSONDecodeFails("{\"mapSfixed32Sfixed32\":{\"2147483648\":2147483647}}")
        assertJSONDecodeFails("{\"mapSfixed32Sfixed32\":{\"-2147483649\":2147483647}}")
        assertJSONDecodeFails("{\"mapSfixed32Sfixed32\":{\"2147483647\":-2147483649}}")
    }

    func testSFixed64SFixed64() throws {
        assertJSONEncode("{\"mapSfixed64Sfixed64\":{\"1\":\"2\"}}") {(o: inout MessageTestType) in
            o.mapSfixed64Sfixed64 = [1:2]
        }
        assertJSONEncode("{\"mapSfixed64Sfixed64\":{\"9223372036854775807\":\"-9223372036854775808\"}}") {(o: inout MessageTestType) in
            o.mapSfixed64Sfixed64 = [9223372036854775807: -9223372036854775808]
        }
        assertJSONDecodeSucceeds("{\"mapSfixed64Sfixed64\":{\"9223372036854775807\":-9223372036854775808}}") {
            $0.mapSfixed64Sfixed64 == [9223372036854775807: -9223372036854775808]
        }
        assertJSONDecodeFails("{\"mapSfixed64Sfixed64\":{\"9223372036854775807\":9223372036854775808}}")
    }

    func test_mapInt32Float() {
        assertJSONDecodeSucceeds("{\"mapInt32Float\":{\"1\":1}}") {
            $0.mapInt32Float == [1: Float(1.0)]
        }

        assertJSONEncode("{\"mapInt32Float\":{\"1\":1.0}}") {
            $0.mapInt32Float[1] = Float(1.0)
        }

        assertJSONDecodeSucceeds("{\"mapInt32Float\":{\"1\":3.141592}}") {
            $0.mapInt32Float[1] == 3.141592 as Float
        }
    }

    func test_mapInt32Double() {
        assertJSONDecodeSucceeds("{\"mapInt32Double\":{\"1\":1}}") {
            $0.mapInt32Double == [1: Double(1.0)]
        }

        assertJSONEncode("{\"mapInt32Double\":{\"1\":1.0}}") {
            $0.mapInt32Double[1] = Double(1.0)
        }

        assertJSONDecodeSucceeds("{\"mapInt32Double\":{\"1\":3.141592}}") {
            $0.mapInt32Double[1] == 3.141592
        }
    }

    func test_mapBoolBool() {
        assertDecodeSucceeds([106, 4, 8, 0, 16, 0]) {
            $0.mapBoolBool == [false: false]
        }
        assertJSONDecodeSucceeds("{\"mapBoolBool\": {\"true\": true, \"false\": false}}") {
            $0.mapBoolBool == [true: true, false: false]
        }
        assertJSONDecodeFails("{\"mapBoolBool\": {true: true}}")
        assertJSONDecodeFails("{\"mapBoolBool\": {false: false}}")
    }

    func testMapStringString() throws {
        assertJSONEncode("{\"mapStringString\":{\"3\":\"4\"}}") {(o: inout MessageTestType) in
            o.mapStringString = ["3":"4"]
        }

        var o = MessageTestType()
        o.mapStringString = ["foo":"bar", "baz":"quux"]
        let json = try o.jsonString()
        // Must be in one of these two orders
        if (json != "{\"mapStringString\":{\"foo\":\"bar\",\"baz\":\"quux\"}}"
            && json != "{\"mapStringString\":{\"baz\":\"quux\",\"foo\":\"bar\"}}") {
            XCTFail("Got:  \(json)")
        }
    }

    func testMapInt32Bytes() {
        assertJSONEncode("{\"mapInt32Bytes\":{\"1\":\"\"}}") {(o: inout MessageTestType) in
            o.mapInt32Bytes = [1:Data()]
        }
        assertJSONDecodeSucceeds("{\"mapInt32Bytes\":{\"1\":\"\", \"2\":\"QUI=\", \"3\": \"AAA=\"}}") {$0.mapInt32Bytes == [1:Data(), 2: Data([65, 66]), 3: Data([0,0])]}
    }

    func testMapInt32Enum() throws {
        assertJSONEncode("{\"mapInt32Enum\":{\"3\":\"MAP_ENUM_FOO\"}}") {(o: inout MessageTestType) in
            o.mapInt32Enum = [3: .foo]
        }

        var o = MessageTestType()
        o.mapInt32Enum = [1:.foo, 3:.baz]
        let json = try o.jsonString()
        // Must be in one of these two orders
        if (json != "{\"mapInt32Enum\":{\"1\":\"MAP_ENUM_FOO\",\"3\":\"MAP_ENUM_BAZ\"}}"
            && json != "{\"mapInt32Enum\":{\"3\":\"MAP_ENUM_BAZ\",\"1\":\"MAP_ENUM_FOO\"}}") {
            XCTFail("Got:  \(json)")
        }

        let decoded = try MessageTestType(jsonString: json)
        XCTAssertEqual(decoded.mapInt32Enum, [1: .foo, 3: .baz])
    }

    func testMapInt32Message() {
        assertJSONEncode("{\"mapInt32ForeignMessage\":{\"7\":{\"c\":999}}}") {(o: inout MessageTestType) in
            var m = ProtobufUnittest_ForeignMessage()
            m.c = 999
            o.mapInt32ForeignMessage[7] = m
        }
        assertJSONDecodeSucceeds("{\"mapInt32ForeignMessage\":{\"7\":{\"c\":7},\"8\":{\"c\":8}}}") {
            var sub7 = ProtobufUnittest_ForeignMessage()
            sub7.c = 7
            var sub8 = ProtobufUnittest_ForeignMessage()
            sub8.c = 8
            return $0.mapInt32ForeignMessage == [7:sub7, 8:sub8]
        }
    }
}
