// Test/Sources/TestSuite/Test_BasicFields_Access_Proto3.swift
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Exercises the apis for optional & repeated fields.
///
// -----------------------------------------------------------------------------

import XCTest
import Foundation

// NOTE: The generator changes what is generated based on the number/types
// of fields (using a nested storage class or not), to be completel, all
// these tests should be done once with a message that gets that storage
// class and a second time with messages that avoid that.

class Test_BasicFields_Access_Proto3: XCTestCase {

  // Optional

  func testOptionalInt32() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalInt32, 0)
    msg.optionalInt32 = 1
    XCTAssertEqual(msg.optionalInt32, 1)
  }

  func testOptionalInt64() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalInt64, 0)
    msg.optionalInt64 = 2
    XCTAssertEqual(msg.optionalInt64, 2)
  }

  func testOptionalUint32() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalUint32, 0)
    msg.optionalUint32 = 3
    XCTAssertEqual(msg.optionalUint32, 3)
  }

  func testOptionalUint64() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalUint64, 0)
    msg.optionalUint64 = 4
    XCTAssertEqual(msg.optionalUint64, 4)
  }

  func testOptionalSint32() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalSint32, 0)
    msg.optionalSint32 = 5
    XCTAssertEqual(msg.optionalSint32, 5)
  }

  func testOptionalSint64() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalSint64, 0)
    msg.optionalSint64 = 6
    XCTAssertEqual(msg.optionalSint64, 6)
  }

  func testOptionalFixed32() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalFixed32, 0)
    msg.optionalFixed32 = 7
    XCTAssertEqual(msg.optionalFixed32, 7)
  }

  func testOptionalFixed64() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalFixed64, 0)
    msg.optionalFixed64 = 8
    XCTAssertEqual(msg.optionalFixed64, 8)
  }

  func testOptionalSfixed32() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalSfixed32, 0)
    msg.optionalSfixed32 = 9
    XCTAssertEqual(msg.optionalSfixed32, 9)
  }

  func testOptionalSfixed64() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalSfixed64, 0)
    msg.optionalSfixed64 = 10
    XCTAssertEqual(msg.optionalSfixed64, 10)
  }

  func testOptionalFloat() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalFloat, 0.0)
    msg.optionalFloat = 11.0
    XCTAssertEqual(msg.optionalFloat, 11.0)
  }

  func testOptionalDouble() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalDouble, 0.0)
    msg.optionalDouble = 12.0
    XCTAssertEqual(msg.optionalDouble, 12.0)
  }

  func testOptionalBool() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalBool, false)
    msg.optionalBool = true
    XCTAssertEqual(msg.optionalBool, true)
  }

  func testOptionalString() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalString, "")
    msg.optionalString = "14"
    XCTAssertEqual(msg.optionalString, "14")
  }

  func testOptionalBytes() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalBytes, Data())
    msg.optionalBytes = Data([15])
    XCTAssertEqual(msg.optionalBytes, Data([15]))
  }

  func testOptionalNestedMessage() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalNestedMessage.bb, 0)
    var nestedMsg = Proto3Unittest_TestAllTypes.NestedMessage()
    nestedMsg.bb = 18
    msg.optionalNestedMessage = nestedMsg
    XCTAssertEqual(msg.optionalNestedMessage.bb, 18)
    XCTAssertEqual(msg.optionalNestedMessage, nestedMsg)
  }

  func testOptionalForeignMessage() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalForeignMessage.c, 0)
    var foreignMsg = Proto3Unittest_ForeignMessage()
    foreignMsg.c = 19
    msg.optionalForeignMessage = foreignMsg
    XCTAssertEqual(msg.optionalForeignMessage.c, 19)
    XCTAssertEqual(msg.optionalForeignMessage, foreignMsg)
  }

  func testOptionalImportMessage() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalImportMessage.d, 0)
    var importedMsg = ProtobufUnittestImport_ImportMessage()
    importedMsg.d = 20
    msg.optionalImportMessage = importedMsg
    XCTAssertEqual(msg.optionalImportMessage.d, 20)
    XCTAssertEqual(msg.optionalImportMessage, importedMsg)
  }

  func testOptionalNestedEnum() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalNestedEnum, .zero)
    msg.optionalNestedEnum = .bar
    XCTAssertEqual(msg.optionalNestedEnum, .bar)
  }

  func testOptionalForeignEnum() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalForeignEnum, .foreignZero)
    msg.optionalForeignEnum = .foreignBar
    XCTAssertEqual(msg.optionalForeignEnum, .foreignBar)
  }

  func testOptionalPublicImportMessage() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.optionalPublicImportMessage.e, 0)
    var pubImportedMsg = ProtobufUnittestImport_PublicImportMessage()
    pubImportedMsg.e = 26
    msg.optionalPublicImportMessage = pubImportedMsg
    XCTAssertEqual(msg.optionalPublicImportMessage.e, 26)
    XCTAssertEqual(msg.optionalPublicImportMessage, pubImportedMsg)
  }

  // Repeated

  func testRepeatedInt32() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedInt32, [])
    msg.repeatedInt32 = [31]
    XCTAssertEqual(msg.repeatedInt32, [31])
    msg.repeatedInt32.append(131)
    XCTAssertEqual(msg.repeatedInt32, [31, 131])
  }

  func testRepeatedInt64() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedInt64, [])
    msg.repeatedInt64 = [32]
    XCTAssertEqual(msg.repeatedInt64, [32])
    msg.repeatedInt64.append(132)
    XCTAssertEqual(msg.repeatedInt64, [32, 132])
  }

  func testRepeatedUint32() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedUint32, [])
    msg.repeatedUint32 = [33]
    XCTAssertEqual(msg.repeatedUint32, [33])
    msg.repeatedUint32.append(133)
    XCTAssertEqual(msg.repeatedUint32, [33, 133])
  }

  func testRepeatedUint64() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedUint64, [])
    msg.repeatedUint64 = [34]
    XCTAssertEqual(msg.repeatedUint64, [34])
    msg.repeatedUint64.append(134)
    XCTAssertEqual(msg.repeatedUint64, [34, 134])
  }

  func testRepeatedSint32() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedSint32, [])
    msg.repeatedSint32 = [35]
    XCTAssertEqual(msg.repeatedSint32, [35])
    msg.repeatedSint32.append(135)
    XCTAssertEqual(msg.repeatedSint32, [35, 135])
  }

  func testRepeatedSint64() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedSint64, [])
    msg.repeatedSint64 = [36]
    XCTAssertEqual(msg.repeatedSint64, [36])
    msg.repeatedSint64.append(136)
    XCTAssertEqual(msg.repeatedSint64, [36, 136])
  }

  func testRepeatedFixed32() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedFixed32, [])
    msg.repeatedFixed32 = [37]
    XCTAssertEqual(msg.repeatedFixed32, [37])
    msg.repeatedFixed32.append(137)
    XCTAssertEqual(msg.repeatedFixed32, [37, 137])
  }

  func testRepeatedFixed64() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedFixed64, [])
    msg.repeatedFixed64 = [38]
    XCTAssertEqual(msg.repeatedFixed64, [38])
    msg.repeatedFixed64.append(138)
    XCTAssertEqual(msg.repeatedFixed64, [38, 138])
  }

  func testRepeatedSfixed32() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedSfixed32, [])
    msg.repeatedSfixed32 = [39]
    XCTAssertEqual(msg.repeatedSfixed32, [39])
    msg.repeatedSfixed32.append(139)
    XCTAssertEqual(msg.repeatedSfixed32, [39, 139])
  }

  func testRepeatedSfixed64() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedSfixed64, [])
    msg.repeatedSfixed64 = [40]
    XCTAssertEqual(msg.repeatedSfixed64, [40])
    msg.repeatedSfixed64.append(140)
    XCTAssertEqual(msg.repeatedSfixed64, [40, 140])
  }

  func testRepeatedFloat() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedFloat, [])
    msg.repeatedFloat = [41.0]
    XCTAssertEqual(msg.repeatedFloat, [41.0])
    msg.repeatedFloat.append(141.0)
    XCTAssertEqual(msg.repeatedFloat, [41.0, 141.0])
  }

  func testRepeatedDouble() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedDouble, [])
    msg.repeatedDouble = [42.0]
    XCTAssertEqual(msg.repeatedDouble, [42.0])
    msg.repeatedDouble.append(142.0)
    XCTAssertEqual(msg.repeatedDouble, [42.0, 142.0])
  }

  func testRepeatedBool() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedBool, [])
    msg.repeatedBool = [true]
    XCTAssertEqual(msg.repeatedBool, [true])
    msg.repeatedBool.append(false)
    XCTAssertEqual(msg.repeatedBool, [true, false])
  }

  func testRepeatedString() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedString, [])
    msg.repeatedString = ["44"]
    XCTAssertEqual(msg.repeatedString, ["44"])
    msg.repeatedString.append("144")
    XCTAssertEqual(msg.repeatedString, ["44", "144"])
  }

  func testRepeatedBytes() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedBytes, [])
    msg.repeatedBytes = [Data([45])]
    XCTAssertEqual(msg.repeatedBytes, [Data([45])])
    msg.repeatedBytes.append(Data([145]))
    XCTAssertEqual(msg.repeatedBytes, [Data([45]), Data([145])])
  }

  func testRepeatedNestedMessage() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedNestedMessage, [])
    var nestedMsg = Proto3Unittest_TestAllTypes.NestedMessage()
    nestedMsg.bb = 48
    msg.repeatedNestedMessage = [nestedMsg]
    XCTAssertEqual(msg.repeatedNestedMessage.count, 1)
    XCTAssertEqual(msg.repeatedNestedMessage[0].bb, 48)
    XCTAssertEqual(msg.repeatedNestedMessage, [nestedMsg])
    var nestedMsg2 = Proto3Unittest_TestAllTypes.NestedMessage()
    nestedMsg2.bb = 148
    msg.repeatedNestedMessage.append(nestedMsg2)
    XCTAssertEqual(msg.repeatedNestedMessage.count, 2)
    XCTAssertEqual(msg.repeatedNestedMessage[0].bb, 48)
    XCTAssertEqual(msg.repeatedNestedMessage[1].bb, 148)
    XCTAssertEqual(msg.repeatedNestedMessage, [nestedMsg, nestedMsg2])
  }

  func testRepeatedForeignMessage() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedForeignMessage, [])
    var foreignMsg = Proto3Unittest_ForeignMessage()
    foreignMsg.c = 49
    msg.repeatedForeignMessage = [foreignMsg]
    XCTAssertEqual(msg.repeatedForeignMessage.count, 1)
    XCTAssertEqual(msg.repeatedForeignMessage[0].c, 49)
    XCTAssertEqual(msg.repeatedForeignMessage, [foreignMsg])
    var foreignMsg2 = Proto3Unittest_ForeignMessage()
    foreignMsg2.c = 149
    msg.repeatedForeignMessage.append(foreignMsg2)
    XCTAssertEqual(msg.repeatedForeignMessage.count, 2)
    XCTAssertEqual(msg.repeatedForeignMessage[0].c, 49)
    XCTAssertEqual(msg.repeatedForeignMessage[1].c, 149)
    XCTAssertEqual(msg.repeatedForeignMessage, [foreignMsg, foreignMsg2])
  }

  func testRepeatedImportMessage() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedImportMessage, [])
    var importedMsg = ProtobufUnittestImport_ImportMessage()
    importedMsg.d = 50
    msg.repeatedImportMessage = [importedMsg]
    XCTAssertEqual(msg.repeatedImportMessage.count, 1)
    XCTAssertEqual(msg.repeatedImportMessage[0].d, 50)
    XCTAssertEqual(msg.repeatedImportMessage, [importedMsg])
    var importedMsg2 = ProtobufUnittestImport_ImportMessage()
    importedMsg2.d = 150
    msg.repeatedImportMessage.append(importedMsg2)
    XCTAssertEqual(msg.repeatedImportMessage.count, 2)
    XCTAssertEqual(msg.repeatedImportMessage[0].d, 50)
    XCTAssertEqual(msg.repeatedImportMessage[1].d, 150)
    XCTAssertEqual(msg.repeatedImportMessage, [importedMsg, importedMsg2])
  }

  func testRepeatedNestedEnum() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedNestedEnum, [])
    msg.repeatedNestedEnum = [.bar]
    XCTAssertEqual(msg.repeatedNestedEnum, [.bar])
    msg.repeatedNestedEnum.append(.baz)
    XCTAssertEqual(msg.repeatedNestedEnum, [.bar, .baz])
  }

  func testRepeatedForeignEnum() {
    var msg = Proto3Unittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedForeignEnum, [])
    msg.repeatedForeignEnum = [.foreignBar]
    XCTAssertEqual(msg.repeatedForeignEnum, [.foreignBar])
    msg.repeatedForeignEnum.append(.foreignBaz)
    XCTAssertEqual(msg.repeatedForeignEnum, [.foreignBar, .foreignBaz])
  }

}
