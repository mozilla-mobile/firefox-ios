// Tests/SwiftProtobufTests/Test_Type.swift - Exercise well-known "Type" message
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// The well-known Type message is a simplified description of a proto schema.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

// Since Type is purely compiled (there is no hand-coding
// in it) this is a fairly thin test just to ensure that the proto
// does get into the runtime:

class Test_Type: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Google_Protobuf_Type

    func testExists() {
        assertEncode([18,13,8,1,16,3,24,1,34,3,102,111,111,64,1,
            18,9,8,8,24,2,34,3,98,97,114]) { (o: inout MessageTestType) in
            var field1 = Google_Protobuf_Field()
            field1.kind = .typeDouble
            field1.cardinality = .repeated
            field1.number = 1
            field1.name = "foo"
            field1.packed = true

            var field2 = Google_Protobuf_Field()
            field2.kind = .typeBool
            field2.number = 2
            field2.name = "bar"

            o.fields = [field1, field2]
        }
    }

}
