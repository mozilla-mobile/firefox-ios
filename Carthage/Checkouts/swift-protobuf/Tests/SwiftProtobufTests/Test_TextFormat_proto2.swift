// Tests/SwiftProtobufTests/Test_TextFormat_proto2.swift - Exercise proto3 text format coding
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

class Test_TextFormat_proto2: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestAllTypes

    func test_group() {
        assertTextFormatEncode("OptionalGroup {\n  a: 17\n}\n") {(o: inout MessageTestType) in
            o.optionalGroup = ProtobufUnittest_TestAllTypes.OptionalGroup.with {$0.a = 17}
        }
    }

    func test_group_numbers() {
        assertTextFormatDecodeSucceeds("16 {\n  17: 17\n}\n") {(o: MessageTestType) in
            o.optionalGroup == ProtobufUnittest_TestAllTypes.OptionalGroup.with {$0.a = 17}
        }
    }

    func test_repeatedGroup() {
        assertTextFormatEncode("RepeatedGroup {\n  a: 17\n}\nRepeatedGroup {\n  a: 18\n}\n") {(o: inout MessageTestType) in
            let group17 = ProtobufUnittest_TestAllTypes.RepeatedGroup.with {$0.a = 17}
            let group18 = ProtobufUnittest_TestAllTypes.RepeatedGroup.with {$0.a = 18}
            o.repeatedGroup = [group17, group18]
        }
    }

    func test_repeatedGroup_numbers() {
        assertTextFormatDecodeSucceeds("46 {\n  47: 17\n}\n46 {\n  47: 18\n}\n") {(o: MessageTestType) in
            let group17 = ProtobufUnittest_TestAllTypes.RepeatedGroup.with {$0.a = 17}
            let group18 = ProtobufUnittest_TestAllTypes.RepeatedGroup.with {$0.a = 18}
            return o.repeatedGroup == [group17, group18]
        }
    }
}
