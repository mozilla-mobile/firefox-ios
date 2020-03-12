// Tests/SwiftProtobufTests/Test_TextFormat_Unknown.swift - Exercise unknown field text format coding
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
@testable import SwiftProtobuf

class Test_TextFormat_Unknown: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestEmptyMessage

    func test_unknown_varint() throws {
        let bytes = Data([8, 0])
        let msg = try MessageTestType(serializedData: bytes)
        let text = msg.textFormatString()
        XCTAssertEqual(text, "1: 0\n")

        do {
            let _ = try MessageTestType(textFormatString: text)
            XCTFail("Shouldn't get here")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        }

        var options = TextFormatEncodingOptions()
        options.printUnknownFields = false
        let textWithoutUnknowns = msg.textFormatString(options: options)
        XCTAssertEqual(textWithoutUnknowns, "")
    }

    func test_unknown_fixed64() throws {
        let bytes = Data([9, 0, 1, 2, 3, 4, 5, 6, 7])
        let msg = try MessageTestType(serializedData: bytes)
        let text = msg.textFormatString()
        XCTAssertEqual(text, "1: 0x0706050403020100\n")

        do {
            let _ = try MessageTestType(textFormatString: text)
            XCTFail("Shouldn't get here")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        }

        var options = TextFormatEncodingOptions()
        options.printUnknownFields = false
        let textWithoutUnknowns = msg.textFormatString(options: options)
        XCTAssertEqual(textWithoutUnknowns, "")
    }

    func test_unknown_lengthDelimited_string() throws {
        let bytes = Data([10, 3, 97, 98, 99])
        let msg = try MessageTestType(serializedData: bytes)
        let text = msg.textFormatString()
        XCTAssertEqual(text, "1: \"abc\"\n")

        do {
            let _ = try MessageTestType(textFormatString: text)
            XCTFail("Shouldn't get here")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        }

        var options = TextFormatEncodingOptions()
        options.printUnknownFields = false
        let textWithoutUnknowns = msg.textFormatString(options: options)
        XCTAssertEqual(textWithoutUnknowns, "")
    }

    func test_unknown_lengthDelimited_message() throws {
        // If inner data looks like a message, display it as such:
        let bytes = Data([10, 6, 8, 1, 18, 2, 97, 98])
        let msg = try MessageTestType(serializedData: bytes)
        let text = msg.textFormatString()
        XCTAssertEqual(text, "1 {\n  1: 1\n  2: \"ab\"\n}\n")

        do {
            let _ = try MessageTestType(textFormatString: text)
            XCTFail("Shouldn't get here")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        }

        var options = TextFormatEncodingOptions()
        options.printUnknownFields = false
        let textWithoutUnknowns = msg.textFormatString(options: options)
        XCTAssertEqual(textWithoutUnknowns, "")
    }

    func test_unknown_lengthDelimited_notmessage() throws {
        // Inner data is almost a message, but has an error at the end...
        // This should cause it to be displayed as a string.
        let bytes = Data([10, 6, 8, 1, 18, 3, 97, 98])
        let msg = try MessageTestType(serializedData: bytes)
        let text = msg.textFormatString()
        XCTAssertEqual(text, "1: \"\\b\\001\\022\\003ab\"\n")

        do {
            let _ = try MessageTestType(textFormatString: text)
            XCTFail("Shouldn't get here")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        }

        var options = TextFormatEncodingOptions()
        options.printUnknownFields = false
        let textWithoutUnknowns = msg.textFormatString(options: options)
        XCTAssertEqual(textWithoutUnknowns, "")
    }

    func test_unknown_lengthDelimited_nested_message() throws {
        let bytes = Data([8, 1, 18, 6, 8, 2, 18, 2, 8, 3])
        let msg = try MessageTestType(serializedData: bytes)
        let text = msg.textFormatString()
        XCTAssertEqual(text, "1: 1\n2 {\n  1: 2\n  2 {\n    1: 3\n  }\n}\n")

        do {
            let _ = try MessageTestType(textFormatString: text)
            XCTFail("Shouldn't get here")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        }

        var options = TextFormatEncodingOptions()
        options.printUnknownFields = false
        let textWithoutUnknowns = msg.textFormatString(options: options)
        XCTAssertEqual(textWithoutUnknowns, "")
    }

    func test_unknown_lengthDelimited_nested_message_recursion_limits() throws {
        let kNestingDepth = 10000
        let kTag = FieldTag(fieldNumber: 1, wireFormat: .lengthDelimited)
        let kTagSize = Int32(kTag.encodedSize)

        var lengths: [Int32] = []
        lengths.reserveCapacity(kNestingDepth)
        lengths.append(0)
        for _ in 0..<(kNestingDepth - 1) {
            lengths.append(
                kTagSize + Int32(Varint.encodedSize(of: lengths.last!)) + lengths.last!)
        }

        var bytes = Data()
        for len in lengths.lazy.reversed() {
            bytes.appendStartField(tag: kTag)
            bytes.appendVarInt(value: len)
        }

        let msg = try MessageTestType(serializedData: bytes)
        let text = msg.textFormatString()
        // Internally, the limit is 10, so we'll get 10 objects and then a
        // string for the bytes.
        let expectedPrefix = "1 {\n  1 {\n    1 {\n      1 {\n        1 {\n          1 {\n            1 {\n              1 {\n                1 {\n                  1 {\n                    1: \""
        let expectedSuffix = "\"\n                  }\n                }\n              }\n            }\n          }\n        }\n      }\n    }\n  }\n}\n"
        XCTAssertTrue(text.hasPrefix(expectedPrefix))
        XCTAssertTrue(text.hasSuffix(expectedSuffix))

        do {
            let _ = try MessageTestType(textFormatString: text)
            XCTFail("Shouldn't get here")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        }

        var options = TextFormatEncodingOptions()
        options.printUnknownFields = false
        let textWithoutUnknowns = msg.textFormatString(options: options)
        XCTAssertEqual(textWithoutUnknowns, "")
    }

    func test_unknown_group() throws {
        let bytes = Data([8, 1, 19, 26, 2, 8, 1, 20])
        let msg = try MessageTestType(serializedData: bytes)
        let text = msg.textFormatString()
        XCTAssertEqual(text, "1: 1\n2 {\n  3 {\n    1: 1\n  }\n}\n")

        do {
            let _ = try MessageTestType(textFormatString: text)
            XCTFail("Shouldn't get here")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        }

        var options = TextFormatEncodingOptions()
        options.printUnknownFields = false
        let textWithoutUnknowns = msg.textFormatString(options: options)
        XCTAssertEqual(textWithoutUnknowns, "")
    }

    func test_unknown_nested_group() throws {
        let bytes = Data([8, 1, 19, 26, 2, 8, 1, 35, 40, 7, 36, 20])
        let msg = try MessageTestType(serializedData: bytes)
        let text = msg.textFormatString()
        XCTAssertEqual(text, "1: 1\n2 {\n  3 {\n    1: 1\n  }\n  4 {\n    5: 7\n  }\n}\n")

        do {
            let _ = try MessageTestType(textFormatString: text)
            XCTFail("Shouldn't get here")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        }

        var options = TextFormatEncodingOptions()
        options.printUnknownFields = false
        let textWithoutUnknowns = msg.textFormatString(options: options)
        XCTAssertEqual(textWithoutUnknowns, "")
    }

    func test_unknown_nested_group_no_recursion_limits() throws {
        let kNestingDepth = 10000
        let kFieldNum = 1
        let kTagStart = FieldTag(fieldNumber: kFieldNum, wireFormat: .startGroup)
        let kTagEnd = FieldTag(fieldNumber: kFieldNum, wireFormat: .endGroup)

        var bytes = Data(capacity: kNestingDepth *
          (Varint.encodedSize(of: kTagStart.rawValue) + Varint.encodedSize(of: kTagEnd.rawValue)))
        for _ in 0..<kNestingDepth {
            bytes.appendStartField(tag: kTagStart)
        }
        for _ in 0..<kNestingDepth {
            bytes.appendStartField(tag: kTagEnd)
        }

        // If we try to parse `data`, the binary decode recursion budget will
        // come into play, instead directly add the data into the unknown fields
        // (via the @testable interface).
        var msg = MessageTestType()
        msg.unknownFields.append(protobufData: bytes)

        let text = msg.textFormatString()
        // Internally, groups don't use recursion, so this will be fully nested.
        var expected = ""
        var indent = ""
        for _ in 0..<kNestingDepth {
            expected.append(indent)
            expected.append("1 {\n")
            indent.append("  ")
        }
        for _ in 0..<kNestingDepth {
            indent.removeLast(2)
            expected.append(indent)
            expected.append("}\n")
        }
        XCTAssertEqual(text, expected)

        do {
            let _ = try MessageTestType(textFormatString: text)
            XCTFail("Shouldn't get here")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        }

        var options = TextFormatEncodingOptions()
        options.printUnknownFields = false
        let textWithoutUnknowns = msg.textFormatString(options: options)
        XCTAssertEqual(textWithoutUnknowns, "")
    }

    func test_unknown_fixed32() throws {
        let bytes = Data([13, 0, 1, 2, 3])
        let msg = try MessageTestType(serializedData: bytes)
        let text = msg.textFormatString()
        XCTAssertEqual(text, "1: 0x03020100\n")

        do {
            let _ = try MessageTestType(textFormatString: text)
            XCTFail("Shouldn't get here")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        }

        var options = TextFormatEncodingOptions()
        options.printUnknownFields = false
        let textWithoutUnknowns = msg.textFormatString(options: options)
        XCTAssertEqual(textWithoutUnknowns, "")
    }
}
