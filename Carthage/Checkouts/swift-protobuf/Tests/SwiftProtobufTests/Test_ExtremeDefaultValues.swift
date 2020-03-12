// Tests/SwiftProtobufTests/Test_ExtremeDefaultValues.swift - Test default values
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Check that the code generator correctly inserts extreme default values
/// into the generated code.  For example, float infinity needs to be
/// correctly rendered into the target language.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

//
// Verify that the Swift backend correctly encodes various
// extreme values when generating code that applies defaults.
//
class Test_ExtremeDefaultValues: XCTestCase {

    func test_escapedBytes() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.escapedBytes, Data([0, 1, 7, 8, 12, 10, 13, 9, 11, 92, 39, 34, 254]))
    }

    func test_largeUint32() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.largeUint32, 0xFFFFFFFF)
    }

    func test_largeUint64() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.largeUint64, 0xFFFFFFFFFFFFFFFF)
    }

    func test_smallInt32() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.smallInt32, -0x7fffffff)
    }

    func test_smallInt64() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.smallInt64, -0x7fffffffffffffff)
    }

    func test_reallySmallInt32() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.reallySmallInt32, -0x80000000)
    }

    func test_reallySmallInt64() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.reallySmallInt64, -0x8000000000000000)
    }

    func test_utf8String() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.utf8String, "ሴ") // Unicode u1234
        XCTAssertEqual(m.utf8String, "\u{1234}")
    }

    func test_zeroFloat() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.zeroFloat, 0.0)
    }

    func test_oneFloat() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.oneFloat, 1.0)
    }

    func test_smallFloat() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.smallFloat, 1.5)
    }

    func test_negativeOneFloat() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.negativeOneFloat, -1)
    }

    func test_negativeFloat() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.negativeFloat, -1.5)
    }

    func test_largeFloat() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.largeFloat, 2E8)
    }

    func test_smallNegativeFloat() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.smallNegativeFloat, -8e-28)
    }

    func test_infDouble() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.infDouble, Double.infinity)
    }

    func test_negInfDouble() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.negInfDouble, -Double.infinity)
    }

    func test_nanDouble() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssert(m.nanDouble.isNaN)
    }

    func test_infFloat() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.infFloat, Float.infinity)
        XCTAssert(m.infFloat.isInfinite)
        XCTAssertEqual(m.infFloat.sign, FloatingPointSign.plus)
    }

    func test_negInfFloat() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.negInfFloat, -Float.infinity)
        XCTAssert(m.negInfFloat.isInfinite)
        XCTAssertEqual(m.negInfFloat.sign, FloatingPointSign.minus)
    }

    func test_nanFloat() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssert(m.nanFloat.isNaN)
    }

    func test_cppTrigraph() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.cppTrigraph, "? ? ?? ?? ??? ??/ ??-")
    }

    func test_stringWithZero() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.stringWithZero, "hel\0lo")
    }

    func test_bytesWithZero() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.bytesWithZero, Data([119, 111, 114, 0, 108, 100]))
    }

    func test_stringPieceWithZero() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.stringPieceWithZero, "ab\0c")
    }

    func test_cordWithZero() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.cordWithZero, "12\03")
    }

    func test_replacementString() {
        let m = ProtobufUnittest_TestExtremeDefaultValues()
        XCTAssertEqual(m.replacementString, "${unknown}")
    }
}
