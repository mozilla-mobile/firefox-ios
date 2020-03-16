// Tests/SwiftProtobufTests/Test_Api.swift - Exercise API type
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Since API is purely compiled (there is no hand-coding
/// in it) this is a fairly thin test just to ensure that the proto
/// does get into the runtime.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_Api: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Google_Protobuf_Api

    func testExists() {
        assertEncode([10,7,97,112,105,78,97,109,101,34,1,49]) { (o: inout MessageTestType) in
            o.name = "apiName"
            o.version = "1"
        }
    }

    func testInitializer() throws {
        var m = MessageTestType()
        m.name = "apiName"
        var method = Google_Protobuf_Method()
        method.name = "method1"
        m.methods = [method]
        var option = Google_Protobuf_Option()
        option.name = "option1"
        option.value = try Google_Protobuf_Any(message: Google_Protobuf_StringValue("value1"))
        m.options = [option]
        m.version = "1.0.0"
        m.syntax = .proto3

        XCTAssertEqual(try m.jsonString(), "{\"name\":\"apiName\",\"methods\":[{\"name\":\"method1\"}],\"options\":[{\"name\":\"option1\",\"value\":{\"@type\":\"type.googleapis.com/google.protobuf.StringValue\",\"value\":\"value1\"}}],\"version\":\"1.0.0\",\"syntax\":\"SYNTAX_PROTO3\"}")
    }
}

