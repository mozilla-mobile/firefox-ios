// Tests/SwiftProtobufTests/Test_ReallyLargeTagNumber.swift - Exercise extreme tag values
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Check that a message with the largest possible tag number encodes correctly.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

class Test_ReallyLargeTagNumber: XCTestCase {

    func test_ReallyLargeTagNumber() {
        var m = ProtobufUnittest_TestReallyLargeTagNumber()
        m.a = 1
        m.bb = 2

        do {
            let encoded = try m.serializedData()
            XCTAssertEqual(encoded, Data([8, 1, 248, 255, 255, 255, 7, 2]))

            do {
                let decoded = try ProtobufUnittest_TestReallyLargeTagNumber(serializedData: encoded)
                XCTAssertEqual(2, decoded.bb)
                XCTAssertEqual(1, decoded.a)
                XCTAssertEqual(m, decoded)
            } catch {
                XCTFail("Decode should not fail")
            }
        } catch let e {
            XCTFail("Could not encode \(m): Got error \(e)")
        }
    }
}
