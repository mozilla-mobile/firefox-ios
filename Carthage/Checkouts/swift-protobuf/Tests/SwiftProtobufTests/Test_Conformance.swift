// Tests/SwiftProtobufTests/Test_Conformance.swift - Various conformance issues
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A very few tests from the conformance suite are transcribed here to simplify
/// debugging.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_Conformance: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufTestMessages_Proto3_TestAllTypesProto3

    func testFieldNaming() throws {
        let json = "{\n  \"fieldname1\": 1,\n  \"fieldName2\": 2,\n   \"FieldName3\": 3\n  }"
        assertJSONDecodeSucceeds(json) { (m: MessageTestType) -> Bool in
            return (m.fieldname1 == 1) && (m.fieldName2 == 2) && (m.fieldName3 == 3)
        }
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: json)
            let recoded = try decoded.jsonString()
            XCTAssertEqual(recoded, "{\"fieldname1\":1,\"fieldName2\":2,\"FieldName3\":3}")
        } catch let e {
            XCTFail("Could not decode? Error: \(e)")
        }
    }

    func testFieldNaming_protoNames() throws {
        // Also accept the names in the .proto when decoding
        let json = "{\n  \"fieldname1\": 1,\n  \"field_name2\": 2,\n   \"_field_name3\": 3\n  }"
        assertJSONDecodeSucceeds(json) { (m: MessageTestType) -> Bool in
            return (m.fieldname1 == 1) && (m.fieldName2 == 2) && (m.fieldName3 == 3)
        }
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: json)
            let recoded = try decoded.jsonString()
            XCTAssertEqual(recoded, "{\"fieldname1\":1,\"fieldName2\":2,\"FieldName3\":3}")
        } catch let e {
            XCTFail("Could not decode? Error: \(e)")
        }
    }

    func testFieldNaming_escapeInName() throws {
        assertJSONDecodeSucceeds("{\"fieldn\\u0061me1\": 1}") {
            return $0.fieldname1 == 1
        }
    }

    func testInt32_min_roundtrip() throws {
        let json = "{\"optionalInt32\": -2147483648}"
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: json)
            let recoded = try decoded.jsonString()
            XCTAssertEqual(recoded, "{\"optionalInt32\":-2147483648}")
        } catch {
            XCTFail("Could not decode")
        }
    }

    func testInt32_toosmall() {
        assertJSONDecodeFails("{\"optionalInt32\": -2147483649}")
    }

    func testRepeatedBoolWrapper() {
        assertJSONDecodeSucceeds("{\"repeatedBoolWrapper\": [true, false]}") {
            (o: ProtobufTestMessages_Proto3_TestAllTypesProto3) -> Bool in
            return o.repeatedBoolWrapper == [Google_Protobuf_BoolValue(true), Google_Protobuf_BoolValue(false)]
        }
    }

    func testString_badUnicodeEscape() {
        assertJSONDecodeFails("{\"optionalString\": \"\\u")
        assertJSONDecodeFails("{\"optionalString\": \"\\uDC\"}")
        assertJSONDecodeFails("{\"optionalString\": \"\\uDCXY\"}")
    }

    func testString_surrogates() {
        // Unpaired low surrogate
        assertJSONDecodeFails("{\"optionalString\": \"\\uDC00\"}")
        assertJSONDecodeFails("{\"optionalString\": \"\\uDC00x\"}")
        assertJSONDecodeFails("{\"optionalString\": \"\\uDC00\\b\"}")
        // Unpaired high surrogate
        assertJSONDecodeFails("{\"optionalString\": \"\\uD800\"}")
        assertJSONDecodeFails("{\"optionalString\": \"\\uD800\\u0061\"}")
        assertJSONDecodeFails("{\"optionalString\": \"\\uD800abcdefghijkl\"}")
        // Mis-ordered surrogate
        assertJSONDecodeFails("{\"optionalString\": \"\\uDE01\\uD83D\"}")
        // Correct surrogate
        assertJSONDecodeSucceeds("{\"optionalString\": \"\\uD83D\\uDE01\"}") {
            return $0.optionalString == "\u{1F601}"
        }
    }
}
