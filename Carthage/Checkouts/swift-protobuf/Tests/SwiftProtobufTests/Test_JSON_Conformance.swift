// Tests/SwiftProtobufTests/Test_JSON_Conformance.swift - Various JSON tests
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A very few of the conformance tests have been transcribed here to
/// ease debugging of these cases.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_JSON_Conformance: XCTestCase {
    func assertEmptyDecode(_ json: String, file: XCTestFileArgType = #file, line: UInt = #line) -> () {
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: json)
            XCTAssertEqual(decoded, ProtobufTestMessages_Proto3_TestAllTypesProto3(), "Decoded object should be equal to empty object: \(decoded)", file: file, line: line)
            let recoded = try decoded.jsonString()
            XCTAssertEqual(recoded, "{}", file: file, line: line)
            let protobuf = try decoded.serializedBytes()
            XCTAssertEqual(protobuf, [], file: file, line: line)
        } catch let e {
            XCTFail("Decode failed with error \(e)", file: file, line: line)
        }
    }

    func testNullSupport_regularTypes() throws {
        // All types should permit explicit 'null'
        // 'null' for (almost) any field behaves as though the field had been omitted
        // (But see 'Value' below)
        assertEmptyDecode("{\"optionalInt32\": null}")
        assertEmptyDecode("{\"optionalInt64\": null}")
        assertEmptyDecode("{\"optionalUint32\": null}")
        assertEmptyDecode("{\"optionalUint64\": null}")
        assertEmptyDecode("{\"optionalBool\": null}")
        assertEmptyDecode("{\"optionalString\": null}")
        assertEmptyDecode("{\"optionalBytes\": null}")
        assertEmptyDecode("{\"optionalNestedEnum\": null}")
        assertEmptyDecode("{\"optionalNestedMessage\": null}")
        assertEmptyDecode("{\"repeatedInt32\": null}")
        assertEmptyDecode("{\"repeatedInt64\": null}")
        assertEmptyDecode("{\"repeatedUint32\": null}")
        assertEmptyDecode("{\"repeatedUint64\": null}")
        assertEmptyDecode("{\"repeatedBool\": null}")
        assertEmptyDecode("{\"repeatedString\": null}")
        assertEmptyDecode("{\"repeatedBytes\": null}")
        assertEmptyDecode("{\"repeatedNestedEnum\": null}")
        assertEmptyDecode("{\"repeatedNestedMessage\": null}")
        assertEmptyDecode("{\"mapInt32Int32\": null}")
        assertEmptyDecode("{\"mapBoolBool\": null}")
        assertEmptyDecode("{\"mapStringNestedMessage\": null}")
    }

    func testNullSupport_wellKnownTypes() throws {
        // Including well-known types
        // (But see 'Value' below)
        assertEmptyDecode("{\"optionalFieldMask\": null}")
        assertEmptyDecode("{\"optionalTimestamp\": null}")
        assertEmptyDecode("{\"optionalDuration\": null}")
        assertEmptyDecode("{\"optionalBoolWrapper\": null}")
        assertEmptyDecode("{\"optionalInt32Wrapper\": null}")
        assertEmptyDecode("{\"optionalUint32Wrapper\": null}")
        assertEmptyDecode("{\"optionalInt64Wrapper\": null}")
        assertEmptyDecode("{\"optionalUint64Wrapper\": null}")
        assertEmptyDecode("{\"optionalFloatWrapper\": null}")
        assertEmptyDecode("{\"optionalDoubleWrapper\": null}")
        assertEmptyDecode("{\"optionalStringWrapper\": null}")
        assertEmptyDecode("{\"optionalBytesWrapper\": null}")
        assertEmptyDecode("{\"repeatedBoolWrapper\": null}")
        assertEmptyDecode("{\"repeatedInt32Wrapper\": null}")
        assertEmptyDecode("{\"repeatedUint32Wrapper\": null}")
        assertEmptyDecode("{\"repeatedInt64Wrapper\": null}")
        assertEmptyDecode("{\"repeatedUint64Wrapper\": null}")
        assertEmptyDecode("{\"repeatedFloatWrapper\": null}")
        assertEmptyDecode("{\"repeatedDoubleWrapper\": null}")
        assertEmptyDecode("{\"repeatedStringWrapper\": null}")
        assertEmptyDecode("{\"repeatedBytesWrapper\": null}")
    }

    func testNullSupport_Value() throws {
        // BUT: Value fields treat null as a regular value
        let valueNull = "{\"optionalValue\": null}"
        let decoded: ProtobufTestMessages_Proto3_TestAllTypesProto3
        do {
            decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: valueNull)
            XCTAssertNotEqual(decoded, ProtobufTestMessages_Proto3_TestAllTypesProto3())
        } catch let e {
            XCTFail("Decode failed with error \(e): \(valueNull)")
            return
        }

        do {
            let recoded = try decoded.jsonString()
            XCTAssertEqual(recoded, "{\"optionalValue\":null}")
        } catch let e {
            XCTFail("JSON encode failed with error: \(e)")
        }

        do {
            let protobuf = try decoded.serializedBytes()
            XCTAssertEqual(protobuf, [146, 19, 2, 8, 0])
        } catch let e {
            XCTFail("Protobuf encode failed with error: \(e)")
        }
    }

    func testNullSupport_Repeated() throws {
        // Nulls within repeated lists are errors
        let json1 = "{\"repeatedBoolWrapper\":[true, null, false]}"
        XCTAssertThrowsError(try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: json1))
        let json2 = "{\"repeatedNestedMessage\":[{}, null]}"
        XCTAssertThrowsError(try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: json2))
        // Make sure the above is failing for the right reason:
        let json3 = "{\"repeatedNestedMessage\":[{}]}"
        let _ = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: json3)
        let json4 = "{\"repeatedNestedMessage\":[null]}"
        XCTAssertThrowsError(try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: json4))
    }

    func testNullSupport_RepeatedValue() throws {
        // BUT: null is valid within repeated Value fields
        let repeatedValueWithNull = "{\"repeatedValue\": [1, null]}"
        let decoded: ProtobufTestMessages_Proto3_TestAllTypesProto3
        do {
            decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: repeatedValueWithNull)
            XCTAssertNotEqual(decoded, ProtobufTestMessages_Proto3_TestAllTypesProto3())
            XCTAssertEqual(decoded.repeatedValue, [Google_Protobuf_Value(numberValue:1), nil as Google_Protobuf_Value])
        } catch {
            XCTFail("Decode failed with error \(error): \(repeatedValueWithNull)")
            return
        }
        do {
            let recoded = try decoded.jsonString()
            XCTAssertEqual(recoded, "{\"repeatedValue\":[1.0,null]}")
        } catch {
            XCTFail("Re-encode failed with error: \(repeatedValueWithNull)")
        }
        do {
            let protobuf = try decoded.serializedBytes()
            XCTAssertEqual(protobuf, [226, 19, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63, 226, 19, 2, 8, 0])
        } catch {
            XCTFail("Protobuf encoding failed with error: \(repeatedValueWithNull)")
        }
    }

    func testNullConformance() {
        let start = "{\n        \"optionalBoolWrapper\": null,\n        \"optionalInt32Wrapper\": null,\n        \"optionalUint32Wrapper\": null,\n        \"optionalInt64Wrapper\": null,\n        \"optionalUint64Wrapper\": null,\n        \"optionalFloatWrapper\": null,\n        \"optionalDoubleWrapper\": null,\n        \"optionalStringWrapper\": null,\n        \"optionalBytesWrapper\": null,\n        \"repeatedBoolWrapper\": null,\n        \"repeatedInt32Wrapper\": null,\n        \"repeatedUint32Wrapper\": null,\n        \"repeatedInt64Wrapper\": null,\n        \"repeatedUint64Wrapper\": null,\n        \"repeatedFloatWrapper\": null,\n        \"repeatedDoubleWrapper\": null,\n        \"repeatedStringWrapper\": null,\n        \"repeatedBytesWrapper\": null\n      }"
        do {
            let t = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
            XCTAssertEqual(try t.jsonString(), "{}")
        } catch {
            XCTFail()
        }
    }

    func testValueList() {
        let start = "{\"optionalValue\":[0.0,\"hello\"]}"
        let t: ProtobufTestMessages_Proto3_TestAllTypesProto3
        do {
            t = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
        } catch {
            XCTFail("Failed to decode: \(start)")
            return
        }
        XCTAssertEqual(try t.jsonString(), start)
    }


    func testNestedAny() {
        let start = ("{\n"
                     + "        \"optionalAny\": {\n"
                     + "          \"@type\": \"type.googleapis.com/google.protobuf.Any\",\n"
                     + "          \"value\": {\n"
                     + "            \"@type\": \"type.googleapis.com/protobuf_test_messages.proto3.TestAllTypes\",\n"
                     + "            \"optionalInt32\": 12345\n"
                     + "          }\n"
                     + "        }\n"
                     + "      }")
        do {
            _ = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
        } catch {
            XCTFail("Failed to decode: \(start)")
            return
        }
    }
}
