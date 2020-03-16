// Tests/SwiftProtobufTests/Test_TextFormat_proto2_extensions.swift - Exercise proto3 text format coding
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

class Test_TextFormat_proto2_extensions: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestAllExtensions

    func test_file_level_extension() {
        assertTextFormatEncode("[protobuf_unittest.optional_int32_extension]: 789\n",
                         extensions: ProtobufUnittest_Unittest_Extensions) {
            (o: inout MessageTestType) in
            o.ProtobufUnittest_optionalInt32Extension = 789
        }
        // Fails if we don't provide the extensions to the decoder:
        assertTextFormatDecodeFails("[protobuf_unittest.optional_int32_extension]: 789\n")

        assertTextFormatEncode("[protobuf_unittest.optionalgroup_extension] {\n  a: 789\n}\n",
                         extensions: ProtobufUnittest_Unittest_Extensions) {
            (o: inout MessageTestType) in
            o.ProtobufUnittest_optionalGroupExtension.a = 789
        }
        // Fails if we don't provide the extensions to the decoder:
        assertTextFormatDecodeFails("[protobuf_unittest.optionalgroup_extension] {\n  a: 789\n}\n")
    }

    func test_nested_extension() {
        assertTextFormatEncode("[protobuf_unittest.TestNestedExtension.test]: \"foo\"\n",
                         extensions: ProtobufUnittest_Unittest_Extensions) {
            (o: inout MessageTestType) in
            o.ProtobufUnittest_TestNestedExtension_test = "foo"
        }
        // Fails if we don't provide the extensions to the decoder:
        assertTextFormatDecodeFails("[protobuf_unittest.TestNestedExtension.test]: \"foo\"\n")
    }
}
