// Tests/SwiftProtobufTests/Test_MessageSet.swift - Test MessageSet behaviors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test all behaviors around the message option message_set_wire_format.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
@testable import SwiftProtobuf

extension ProtobufUnittest_RawMessageSet.Item {
  fileprivate init(typeID: Int, message: Data) {
    self.init()
    self.typeID = Int32(typeID)
    self.message = message
  }
}

class Test_MessageSet: XCTestCase {

  // wireformat_unittest.cc: TEST(WireFormatTest, SerializeMessageSet)
  func testSerialize() throws {
    let msg = Proto2WireformatUnittest_TestMessageSet.with {
      $0.ProtobufUnittest_TestMessageSetExtension1_messageSetExtension.i = 123
      $0.ProtobufUnittest_TestMessageSetExtension2_messageSetExtension.str = "foo"
    }

    let serialized: Data
    do {
      serialized = try msg.serializedData()
    } catch let e {
      XCTFail("Failed to serialize: \(e)")
      return
    }

    // Read it back in with the RawMessageSet to validate it.

    let raw: ProtobufUnittest_RawMessageSet
    do {
      raw = try ProtobufUnittest_RawMessageSet(serializedData: serialized)
    } catch let e {
      XCTFail("Failed to parse: \(e)")
      return
    }

    XCTAssertTrue(raw.unknownFields.data.isEmpty)

    XCTAssertEqual(raw.item.count, 2)

    XCTAssertEqual(Int(raw.item[0].typeID),
                   ProtobufUnittest_TestMessageSetExtension1.Extensions.message_set_extension.fieldNumber)
    XCTAssertEqual(Int(raw.item[1].typeID),
                   ProtobufUnittest_TestMessageSetExtension2.Extensions.message_set_extension.fieldNumber)

    let extMsg1 = try ProtobufUnittest_TestMessageSetExtension1(serializedData: raw.item[0].message)
    XCTAssertEqual(extMsg1.i, 123)
    XCTAssertTrue(extMsg1.unknownFields.data.isEmpty)
    let extMsg2 = try ProtobufUnittest_TestMessageSetExtension2(serializedData: raw.item[1].message)
    XCTAssertEqual(extMsg2.str, "foo")
    XCTAssertTrue(extMsg2.unknownFields.data.isEmpty)
  }

  // wireformat_unittest.cc: TEST(WireFormatTest, ParseMessageSet)
  func testParse() throws {
    let msg1 = ProtobufUnittest_TestMessageSetExtension1.with { $0.i = 123 }
    let msg2 = ProtobufUnittest_TestMessageSetExtension2.with { $0.str = "foo" }
    var raw = ProtobufUnittest_RawMessageSet()
    raw.item = [
      // Two known extensions.
      ProtobufUnittest_RawMessageSet.Item(
        typeID: ProtobufUnittest_TestMessageSetExtension1.Extensions.message_set_extension.fieldNumber,
        message: try msg1.serializedData()),
      ProtobufUnittest_RawMessageSet.Item(
        typeID: ProtobufUnittest_TestMessageSetExtension2.Extensions.message_set_extension.fieldNumber,
        message: try msg2.serializedData()),
      // One unknown extension.
      ProtobufUnittest_RawMessageSet.Item(typeID: 7, message: Data([1, 2, 3]))
    ]
    // Add some unknown data into one of the groups to ensure it gets stripped when parsing.
    raw.item[1].unknownFields.append(protobufData: Data([40, 2]))  // Field 5, varint of 2

    let serialized: Data
    do {
      serialized = try raw.serializedData()
    } catch let e {
      XCTFail("Failed to serialize: \(e)")
      return
    }

    let msg: Proto2WireformatUnittest_TestMessageSet
    do {
      msg = try Proto2WireformatUnittest_TestMessageSet(
        serializedData: serialized,
        extensions: ProtobufUnittest_UnittestMset_Extensions)
    } catch let e {
      XCTFail("Failed to parse: \(e)")
      return
    }

    // Ensure the extensions showed up, but with nothing extra.
    XCTAssertEqual(
      msg.ProtobufUnittest_TestMessageSetExtension1_messageSetExtension.i, 123)
    XCTAssertTrue(
      msg.ProtobufUnittest_TestMessageSetExtension1_messageSetExtension.unknownFields.data.isEmpty)
    XCTAssertEqual(
      msg.ProtobufUnittest_TestMessageSetExtension2_messageSetExtension.str, "foo")
    XCTAssertTrue(
      msg.ProtobufUnittest_TestMessageSetExtension2_messageSetExtension.unknownFields.data.isEmpty)

    // Ensure the unknown shows up as a group.
    let expectedUnknowns = Data([
      11,  // Start group
      16, 7, // typeID = 7
      26, 3, 1, 2, 3, // message data = 3 bytes: 1, 2, 3
      12   // End Group
    ])
    XCTAssertEqual(msg.unknownFields.data, expectedUnknowns)

    var validator = ExtensionValidator()
    validator.expectedMessages = [
      (ProtobufUnittest_TestMessageSetExtension1.Extensions.message_set_extension.fieldNumber, false),
      (ProtobufUnittest_TestMessageSetExtension2.Extensions.message_set_extension.fieldNumber, false),
    ]
    validator.expectedUnknowns = [ expectedUnknowns ]
    validator.validate(message: msg)
  }

  static let canonicalTextFormat: String = (
    "message_set {\n" +
      "  [protobuf_unittest.TestMessageSetExtension1] {\n" +
      "    i: 23\n" +
      "  }\n" +
      "  [protobuf_unittest.TestMessageSetExtension2] {\n" +
      "    str: \"foo\"\n" +
      "  }\n" +
    "}\n"
  )

  // text_format_unittest.cc: TEST_F(TextFormatMessageSetTest, Serialize)
  func testTextFormat_Serialize() {
    let msg = ProtobufUnittest_TestMessageSetContainer.with {
      $0.messageSet.ProtobufUnittest_TestMessageSetExtension1_messageSetExtension.i = 23
      $0.messageSet.ProtobufUnittest_TestMessageSetExtension2_messageSetExtension.str = "foo"
    }

    XCTAssertEqual(msg.textFormatString(), Test_MessageSet.canonicalTextFormat)
  }

  // text_format_unittest.cc: TEST_F(TextFormatMessageSetTest, Deserialize)
  func testTextFormat_Parse() {
    let msg: ProtobufUnittest_TestMessageSetContainer
    do {
      msg = try ProtobufUnittest_TestMessageSetContainer(
        textFormatString: Test_MessageSet.canonicalTextFormat,
        extensions: ProtobufUnittest_UnittestMset_Extensions)
    } catch let e {
      XCTFail("Shouldn't have failed: \(e)")
      return
    }

    XCTAssertEqual(
      msg.messageSet.ProtobufUnittest_TestMessageSetExtension1_messageSetExtension.i, 23)
    XCTAssertEqual(
      msg.messageSet.ProtobufUnittest_TestMessageSetExtension2_messageSetExtension.str, "foo")

    // Ensure nothing else showed up.
    XCTAssertTrue(msg.unknownFields.data.isEmpty)
    XCTAssertTrue(msg.messageSet.unknownFields.data.isEmpty)

    var validator = ExtensionValidator()
    validator.expectedMessages = [
      (1, true), // protobuf_unittest.TestMessageSetContainer.message_set (where the extensions are)
      (ProtobufUnittest_TestMessageSetExtension1.Extensions.message_set_extension.fieldNumber, false),
      (ProtobufUnittest_TestMessageSetExtension2.Extensions.message_set_extension.fieldNumber, false),
    ]
    validator.validate(message: msg)
  }

  fileprivate struct ExtensionValidator: PBTestVisitor {
    // Values are field number and if we should recurse.
    var expectedMessages = [(Int, Bool)]()
    var expectedUnknowns = [Data]()

    mutating func validate<M: Message>(message: M) {
      do {
        try message.traverse(visitor: &self)
      } catch let e {
        XCTFail("Error while traversing: \(e)")
      }
      XCTAssertTrue(expectedMessages.isEmpty,
                    "Expected more messages: \(expectedMessages)")
      XCTAssertTrue(expectedUnknowns.isEmpty,
                    "Expected more unknowns: \(expectedUnknowns)")
    }

    mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
      guard !expectedMessages.isEmpty else {
        XCTFail("Unexpected Message: \(fieldNumber) = \(value)")
        return
      }
      let (expected, shouldRecurse) = expectedMessages.removeFirst()
      XCTAssertEqual(fieldNumber, expected)
      if shouldRecurse && expected == fieldNumber {
        try value.traverse(visitor: &self)
      }
    }

    mutating func visitUnknown(bytes: Data) throws {
      guard !expectedUnknowns.isEmpty else {
        XCTFail("Unexpected Unknown: \(bytes)")
        return
      }
      let expected = expectedUnknowns.removeFirst()
      XCTAssertEqual(bytes, expected)
    }
  }
}
