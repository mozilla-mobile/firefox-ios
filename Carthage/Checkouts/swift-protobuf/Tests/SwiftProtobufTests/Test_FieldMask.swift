// Tests/SwiftProtobufTests/Test_FieldMask.swift - Exercise well-known FieldMask type
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// The FieldMask type is a new standard message type in proto3.  It has a
/// specialized JSON coding.
///
// -----------------------------------------------------------------------------

// TODO: We should have utility functions for applying a mask to an arbitrary
// message, intersecting two masks, etc.

import Foundation
import XCTest
import SwiftProtobuf

class Test_FieldMask: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Google_Protobuf_FieldMask

    func testJSON() {
        assertJSONEncode("\"foo\"") { (o: inout MessageTestType) in
            o.paths = ["foo"]
        }
        assertJSONEncode("\"foo,fooBar\"") { (o: inout MessageTestType) in
            o.paths = ["foo", "foo_bar"]
        }
        // assertJSONEncode doesn't want an empty object, hand roll it.
        let msg = MessageTestType.with { (o: inout MessageTestType) in
          o.paths = []
        }
        XCTAssertEqual(try msg.jsonString(), "\"\"")
        assertJSONDecodeSucceeds("\"foo\"") { $0.paths == ["foo"] }
        assertJSONDecodeSucceeds("\"\"") { $0.paths == [] }
        assertJSONDecodeFails("foo")
        assertJSONDecodeFails("\"foo,\"")
        assertJSONDecodeFails("\"foo\",\"bar\"")
        assertJSONDecodeFails("\",foo\"")
        assertJSONDecodeFails("\"foo,,bar\"")
        assertJSONDecodeFails("\"foo,bar")
        assertJSONDecodeFails("foo,bar\"")
    }

    func testProtobuf() {
        assertEncode([10, 3, 102, 111, 111]) { (o: inout MessageTestType) in
            o.paths = ["foo"]
        }
    }

    func testDebugDescription() {
        var m = Google_Protobuf_FieldMask()
        m.paths = ["foo", "bar"]
        XCTAssertEqual(m.debugDescription, "SwiftProtobuf.Google_Protobuf_FieldMask:\npaths: \"foo\"\npaths: \"bar\"\n")
    }

    func testConvenienceInits() {
        var m = Google_Protobuf_FieldMask()
        m.paths = ["foo", "bar"]

        let m1 = Google_Protobuf_FieldMask(protoPaths: "foo", "bar")
        let m2 = Google_Protobuf_FieldMask(protoPaths: ["foo", "bar"])

        var other = Google_Protobuf_FieldMask()
        other.paths = ["foo", "bar", "baz"]

        XCTAssertEqual(m, m1)
        XCTAssertEqual(m, m2)
        XCTAssertEqual(m1, m2)

        XCTAssertNotEqual(m, other)
        XCTAssertNotEqual(m1, other)
        XCTAssertNotEqual(m2, other)
    }

    // Make sure field mask works correctly when stored in a field
    func testJSON_field() throws {
        do {
            let valid = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: "{\"optionalFieldMask\": \"foo,barBaz\"}")
            XCTAssertEqual(valid.optionalFieldMask, Google_Protobuf_FieldMask(protoPaths: "foo", "bar_baz"))
        } catch {
            XCTFail("Should have decoded correctly")
        }

        // https://github.com/protocolbuffers/protobuf/issues/4734 resulted in a new conformance
        // test to confirm an empty string works.
        do {
            let valid = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: "{\"optionalFieldMask\": \"\"}")
            XCTAssertEqual(valid.optionalFieldMask, Google_Protobuf_FieldMask())
        } catch {
            XCTFail("Should have decoded correctly")
        }

        XCTAssertThrowsError(try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: "{\"optionalFieldMask\": \"foo,bar_bar\"}"))
    }

    func testSerializationFailure() {
        // If the proto fieldname can't be converted to a JSON field name,
        // then JSON serialization should fail:
        let m1 = Google_Protobuf_FieldMask(protoPaths: "foo_3_bar")
        XCTAssertThrowsError(try m1.jsonString())
        let m2 = Google_Protobuf_FieldMask(protoPaths: "foo__bar")
        XCTAssertThrowsError(try m2.jsonString())
        let m3 = Google_Protobuf_FieldMask(protoPaths: "fooBar")
        XCTAssertThrowsError(try m3.jsonString())
    }
}
