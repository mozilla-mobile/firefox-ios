// Tests/SwiftProtobufTests/Test_JSON_Group.swift - Exercise JSON coding for groups
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Google has not specified a JSON coding for groups. The C++ implementation
/// fails when decoding a JSON string that contains a group, so we verify that
/// we do the same for consistency.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

class Test_JSON_Group: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestAllTypes

    func testOptionalGroup() {
        assertJSONDecodeFails("{\"optionalgroup\":{\"a\":3}}")
    }

    func testRepeatedGroup() {
        assertJSONDecodeFails("{\"repeatedgroup\":[{\"a\":1},{\"a\":2}]}")
    }
}
