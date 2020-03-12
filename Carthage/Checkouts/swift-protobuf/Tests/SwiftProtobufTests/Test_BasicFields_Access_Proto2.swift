// Test/Sources/TestSuite/Test_BasicFields_Access_Proto2.swift
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Exercises the apis for optional/optional+default/repeated fields.
///
// -----------------------------------------------------------------------------

import XCTest
import Foundation

// NOTE: The generator changes what is generated based on the number/types
// of fields (using a nested storage class or not), to be completel, all
// these tests should be done once with a message that gets that storage
// class and a second time with messages that avoid that.

class Test_BasicFields_Access_Proto2: XCTestCase {

  // Optional

  func testOptionalInt32() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalInt32, 0)
    XCTAssertFalse(msg.hasOptionalInt32)
    msg.optionalInt32 = 1
    XCTAssertTrue(msg.hasOptionalInt32)
    XCTAssertEqual(msg.optionalInt32, 1)
    msg.clearOptionalInt32()
    XCTAssertEqual(msg.optionalInt32, 0)
    XCTAssertFalse(msg.hasOptionalInt32)
  }

  func testOptionalInt64() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalInt64, 0)
    XCTAssertFalse(msg.hasOptionalInt64)
    msg.optionalInt64 = 2
    XCTAssertTrue(msg.hasOptionalInt64)
    XCTAssertEqual(msg.optionalInt64, 2)
    msg.clearOptionalInt64()
    XCTAssertEqual(msg.optionalInt64, 0)
    XCTAssertFalse(msg.hasOptionalInt64)
  }

  func testOptionalUint32() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalUint32, 0)
    XCTAssertFalse(msg.hasOptionalUint32)
    msg.optionalUint32 = 3
    XCTAssertTrue(msg.hasOptionalUint32)
    XCTAssertEqual(msg.optionalUint32, 3)
    msg.clearOptionalUint32()
    XCTAssertEqual(msg.optionalUint32, 0)
    XCTAssertFalse(msg.hasOptionalUint32)
  }

  func testOptionalUint64() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalUint64, 0)
    XCTAssertFalse(msg.hasOptionalUint64)
    msg.optionalUint64 = 4
    XCTAssertTrue(msg.hasOptionalUint64)
    XCTAssertEqual(msg.optionalUint64, 4)
    msg.clearOptionalUint64()
    XCTAssertEqual(msg.optionalUint64, 0)
    XCTAssertFalse(msg.hasOptionalUint64)
  }

  func testOptionalSint32() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalSint32, 0)
    XCTAssertFalse(msg.hasOptionalSint32)
    msg.optionalSint32 = 5
    XCTAssertTrue(msg.hasOptionalSint32)
    XCTAssertEqual(msg.optionalSint32, 5)
    msg.clearOptionalSint32()
    XCTAssertEqual(msg.optionalSint32, 0)
    XCTAssertFalse(msg.hasOptionalSint32)
  }

  func testOptionalSint64() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalSint64, 0)
    XCTAssertFalse(msg.hasOptionalSint64)
    msg.optionalSint64 = 6
    XCTAssertTrue(msg.hasOptionalSint64)
    XCTAssertEqual(msg.optionalSint64, 6)
    msg.clearOptionalSint64()
    XCTAssertEqual(msg.optionalSint64, 0)
    XCTAssertFalse(msg.hasOptionalSint64)
  }

  func testOptionalFixed32() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalFixed32, 0)
    XCTAssertFalse(msg.hasOptionalFixed32)
    msg.optionalFixed32 = 7
    XCTAssertTrue(msg.hasOptionalFixed32)
    XCTAssertEqual(msg.optionalFixed32, 7)
    msg.clearOptionalFixed32()
    XCTAssertEqual(msg.optionalFixed32, 0)
    XCTAssertFalse(msg.hasOptionalFixed32)
  }

  func testOptionalFixed64() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalFixed64, 0)
    XCTAssertFalse(msg.hasOptionalFixed64)
    msg.optionalFixed64 = 8
    XCTAssertTrue(msg.hasOptionalFixed64)
    XCTAssertEqual(msg.optionalFixed64, 8)
    msg.clearOptionalFixed64()
    XCTAssertEqual(msg.optionalFixed64, 0)
    XCTAssertFalse(msg.hasOptionalFixed64)
  }

  func testOptionalSfixed32() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalSfixed32, 0)
    XCTAssertFalse(msg.hasOptionalSfixed32)
    msg.optionalSfixed32 = 9
    XCTAssertTrue(msg.hasOptionalSfixed32)
    XCTAssertEqual(msg.optionalSfixed32, 9)
    msg.clearOptionalSfixed32()
    XCTAssertEqual(msg.optionalSfixed32, 0)
    XCTAssertFalse(msg.hasOptionalSfixed32)
  }

  func testOptionalSfixed64() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalSfixed64, 0)
    XCTAssertFalse(msg.hasOptionalSfixed64)
    msg.optionalSfixed64 = 10
    XCTAssertTrue(msg.hasOptionalSfixed64)
    XCTAssertEqual(msg.optionalSfixed64, 10)
    msg.clearOptionalSfixed64()
    XCTAssertEqual(msg.optionalSfixed64, 0)
    XCTAssertFalse(msg.hasOptionalSfixed64)
  }

  func testOptionalFloat() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalFloat, 0.0)
    XCTAssertFalse(msg.hasOptionalFloat)
    msg.optionalFloat = 11.0
    XCTAssertTrue(msg.hasOptionalFloat)
    XCTAssertEqual(msg.optionalFloat, 11.0)
    msg.clearOptionalFloat()
    XCTAssertEqual(msg.optionalFloat, 0.0)
    XCTAssertFalse(msg.hasOptionalFloat)
  }

  func testOptionalDouble() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalDouble, 0.0)
    XCTAssertFalse(msg.hasOptionalDouble)
    msg.optionalDouble = 12.0
    XCTAssertTrue(msg.hasOptionalDouble)
    XCTAssertEqual(msg.optionalDouble, 12.0)
    msg.clearOptionalDouble()
    XCTAssertEqual(msg.optionalDouble, 0.0)
    XCTAssertFalse(msg.hasOptionalDouble)
  }

  func testOptionalBool() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalBool, false)
    XCTAssertFalse(msg.hasOptionalBool)
    msg.optionalBool = true
    XCTAssertTrue(msg.hasOptionalBool)
    XCTAssertEqual(msg.optionalBool, true)
    msg.clearOptionalBool()
    XCTAssertEqual(msg.optionalBool, false)
    XCTAssertFalse(msg.hasOptionalBool)
  }

  func testOptionalString() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalString, "")
    XCTAssertFalse(msg.hasOptionalString)
    msg.optionalString = "14"
    XCTAssertTrue(msg.hasOptionalString)
    XCTAssertEqual(msg.optionalString, "14")
    msg.clearOptionalString()
    XCTAssertEqual(msg.optionalString, "")
    XCTAssertFalse(msg.hasOptionalString)
  }

  func testOptionalBytes() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalBytes, Data())
    XCTAssertFalse(msg.hasOptionalBytes)
    msg.optionalBytes = Data([15])
    XCTAssertTrue(msg.hasOptionalBytes)
    XCTAssertEqual(msg.optionalBytes, Data([15]))
    msg.clearOptionalBytes()
    XCTAssertEqual(msg.optionalBytes, Data())
    XCTAssertFalse(msg.hasOptionalBytes)
  }

  func testOptionalGroup() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalGroup.a, 0)
    XCTAssertFalse(msg.hasOptionalGroup)
    var grp = ProtobufUnittest_TestAllTypes.OptionalGroup()
    grp.a = 16
    msg.optionalGroup = grp
    XCTAssertTrue(msg.hasOptionalGroup)
    XCTAssertEqual(msg.optionalGroup.a, 16)
    msg.clearOptionalGroup()
    XCTAssertEqual(msg.optionalGroup.a, 0)
    XCTAssertFalse(msg.hasOptionalGroup)
  }

  func testOptionalNestedMessage() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalNestedMessage.bb, 0)
    XCTAssertFalse(msg.hasOptionalNestedMessage)
    var nestedMsg = ProtobufUnittest_TestAllTypes.NestedMessage()
    nestedMsg.bb = 18
    msg.optionalNestedMessage = nestedMsg
    XCTAssertTrue(msg.hasOptionalNestedMessage)
    XCTAssertEqual(msg.optionalNestedMessage.bb, 18)
    XCTAssertEqual(msg.optionalNestedMessage, nestedMsg)
    msg.clearOptionalNestedMessage()
    XCTAssertEqual(msg.optionalNestedMessage.bb, 0)
    XCTAssertFalse(msg.hasOptionalNestedMessage)
  }

  func testOptionalForeignMessage() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalForeignMessage.c, 0)
    XCTAssertFalse(msg.hasOptionalForeignMessage)
    var foreignMsg = ProtobufUnittest_ForeignMessage()
    foreignMsg.c = 19
    msg.optionalForeignMessage = foreignMsg
    XCTAssertTrue(msg.hasOptionalForeignMessage)
    XCTAssertEqual(msg.optionalForeignMessage.c, 19)
    XCTAssertEqual(msg.optionalForeignMessage, foreignMsg)
    msg.clearOptionalForeignMessage()
    XCTAssertEqual(msg.optionalForeignMessage.c, 0)
    XCTAssertFalse(msg.hasOptionalForeignMessage)
  }

  func testOptionalImportMessage() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalImportMessage.d, 0)
    XCTAssertFalse(msg.hasOptionalImportMessage)
    var importedMsg = ProtobufUnittestImport_ImportMessage()
    importedMsg.d = 20
    msg.optionalImportMessage = importedMsg
    XCTAssertTrue(msg.hasOptionalImportMessage)
    XCTAssertEqual(msg.optionalImportMessage.d, 20)
    XCTAssertEqual(msg.optionalImportMessage, importedMsg)
    msg.clearOptionalImportMessage()
    XCTAssertEqual(msg.optionalImportMessage.d, 0)
    XCTAssertFalse(msg.hasOptionalImportMessage)
  }

  func testOptionalNestedEnum() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalNestedEnum, .foo)
    XCTAssertFalse(msg.hasOptionalNestedEnum)
    msg.optionalNestedEnum = .bar
    XCTAssertTrue(msg.hasOptionalNestedEnum)
    XCTAssertEqual(msg.optionalNestedEnum, .bar)
    msg.clearOptionalNestedEnum()
    XCTAssertEqual(msg.optionalNestedEnum, .foo)
    XCTAssertFalse(msg.hasOptionalNestedEnum)
  }

  func testOptionalForeignEnum() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalForeignEnum, .foreignFoo)
    XCTAssertFalse(msg.hasOptionalForeignEnum)
    msg.optionalForeignEnum = .foreignBar
    XCTAssertTrue(msg.hasOptionalForeignEnum)
    XCTAssertEqual(msg.optionalForeignEnum, .foreignBar)
    msg.clearOptionalForeignEnum()
    XCTAssertEqual(msg.optionalForeignEnum, .foreignFoo)
    XCTAssertFalse(msg.hasOptionalForeignEnum)
  }

  func testOptionalImportEnum() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalImportEnum, .importFoo)
    XCTAssertFalse(msg.hasOptionalImportEnum)
    msg.optionalImportEnum = .importBar
    XCTAssertTrue(msg.hasOptionalImportEnum)
    XCTAssertEqual(msg.optionalImportEnum, .importBar)
    msg.clearOptionalImportEnum()
    XCTAssertEqual(msg.optionalImportEnum, .importFoo)
    XCTAssertFalse(msg.hasOptionalImportEnum)
  }

  func testOptionalStringPiece() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalStringPiece, "")
    XCTAssertFalse(msg.hasOptionalStringPiece)
    msg.optionalStringPiece = "24"
    XCTAssertTrue(msg.hasOptionalStringPiece)
    XCTAssertEqual(msg.optionalStringPiece, "24")
    msg.clearOptionalStringPiece()
    XCTAssertEqual(msg.optionalStringPiece, "")
    XCTAssertFalse(msg.hasOptionalStringPiece)
  }

  func testOptionalCord() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalCord, "")
    XCTAssertFalse(msg.hasOptionalCord)
    msg.optionalCord = "25"
    XCTAssertTrue(msg.hasOptionalCord)
    XCTAssertEqual(msg.optionalCord, "25")
    msg.clearOptionalCord()
    XCTAssertEqual(msg.optionalCord, "")
    XCTAssertFalse(msg.hasOptionalCord)
  }

  func testOptionalPublicImportMessage() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalPublicImportMessage.e, 0)
    XCTAssertFalse(msg.hasOptionalPublicImportMessage)
    var pubImportedMsg = ProtobufUnittestImport_PublicImportMessage()
    pubImportedMsg.e = 26
    msg.optionalPublicImportMessage = pubImportedMsg
    XCTAssertTrue(msg.hasOptionalPublicImportMessage)
    XCTAssertEqual(msg.optionalPublicImportMessage.e, 26)
    XCTAssertEqual(msg.optionalPublicImportMessage, pubImportedMsg)
    msg.clearOptionalPublicImportMessage()
    XCTAssertEqual(msg.optionalPublicImportMessage.e, 0)
    XCTAssertFalse(msg.hasOptionalPublicImportMessage)
  }

  func testOptionalLazyMessage() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.optionalLazyMessage.bb, 0)
    XCTAssertFalse(msg.hasOptionalLazyMessage)
    var nestedMsg = ProtobufUnittest_TestAllTypes.NestedMessage()
    nestedMsg.bb = 27
    msg.optionalLazyMessage = nestedMsg
    XCTAssertTrue(msg.hasOptionalLazyMessage)
    XCTAssertEqual(msg.optionalLazyMessage.bb, 27)
    XCTAssertEqual(msg.optionalLazyMessage, nestedMsg)
    msg.clearOptionalLazyMessage()
    XCTAssertEqual(msg.optionalLazyMessage.bb, 0)
    XCTAssertFalse(msg.hasOptionalLazyMessage)
  }

  // Optional with explicit default values (non zero)

  func testDefaultInt32() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultInt32, 41)
    XCTAssertFalse(msg.hasDefaultInt32)
    msg.defaultInt32 = 61
    XCTAssertTrue(msg.hasDefaultInt32)
    XCTAssertEqual(msg.defaultInt32, 61)
    msg.clearDefaultInt32()
    XCTAssertEqual(msg.defaultInt32, 41)
    XCTAssertFalse(msg.hasDefaultInt32)
  }

  func testDefaultInt64() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultInt64, 42)
    XCTAssertFalse(msg.hasDefaultInt64)
    msg.defaultInt64 = 62
    XCTAssertTrue(msg.hasDefaultInt64)
    XCTAssertEqual(msg.defaultInt64, 62)
    msg.clearDefaultInt64()
    XCTAssertEqual(msg.defaultInt64, 42)
    XCTAssertFalse(msg.hasDefaultInt64)
  }

  func testDefaultUint32() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultUint32, 43)
    XCTAssertFalse(msg.hasDefaultUint32)
    msg.defaultUint32 = 63
    XCTAssertTrue(msg.hasDefaultUint32)
    XCTAssertEqual(msg.defaultUint32, 63)
    msg.clearDefaultUint32()
    XCTAssertEqual(msg.defaultUint32, 43)
    XCTAssertFalse(msg.hasDefaultUint32)
  }

  func testDefaultUint64() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultUint64, 44)
    XCTAssertFalse(msg.hasDefaultUint64)
    msg.defaultUint64 = 64
    XCTAssertTrue(msg.hasDefaultUint64)
    XCTAssertEqual(msg.defaultUint64, 64)
    msg.clearDefaultUint64()
    XCTAssertEqual(msg.defaultUint64, 44)
    XCTAssertFalse(msg.hasDefaultUint64)
  }

  func testDefaultSint32() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultSint32, -45)
    XCTAssertFalse(msg.hasDefaultSint32)
    msg.defaultSint32 = 65
    XCTAssertTrue(msg.hasDefaultSint32)
    XCTAssertEqual(msg.defaultSint32, 65)
    msg.clearDefaultSint32()
    XCTAssertEqual(msg.defaultSint32, -45)
    XCTAssertFalse(msg.hasDefaultSint32)
  }

  func testDefaultSint64() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultSint64, 46)
    XCTAssertFalse(msg.hasDefaultSint64)
    msg.defaultSint64 = 66
    XCTAssertTrue(msg.hasDefaultSint64)
    XCTAssertEqual(msg.defaultSint64, 66)
    msg.clearDefaultSint64()
    XCTAssertEqual(msg.defaultSint64, 46)
    XCTAssertFalse(msg.hasDefaultSint64)
  }

  func testDefaultFixed32() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultFixed32, 47)
    XCTAssertFalse(msg.hasDefaultFixed32)
    msg.defaultFixed32 = 67
    XCTAssertTrue(msg.hasDefaultFixed32)
    XCTAssertEqual(msg.defaultFixed32, 67)
    msg.clearDefaultFixed32()
    XCTAssertEqual(msg.defaultFixed32, 47)
    XCTAssertFalse(msg.hasDefaultFixed32)
  }

  func testDefaultFixed64() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultFixed64, 48)
    XCTAssertFalse(msg.hasDefaultFixed64)
    msg.defaultFixed64 = 68
    XCTAssertTrue(msg.hasDefaultFixed64)
    XCTAssertEqual(msg.defaultFixed64, 68)
    msg.clearDefaultFixed64()
    XCTAssertEqual(msg.defaultFixed64, 48)
    XCTAssertFalse(msg.hasDefaultFixed64)
  }

  func testDefaultSfixed32() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultSfixed32, 49)
    XCTAssertFalse(msg.hasDefaultSfixed32)
    msg.defaultSfixed32 = 69
    XCTAssertTrue(msg.hasDefaultSfixed32)
    XCTAssertEqual(msg.defaultSfixed32, 69)
    msg.clearDefaultSfixed32()
    XCTAssertEqual(msg.defaultSfixed32, 49)
    XCTAssertFalse(msg.hasDefaultSfixed32)
  }

  func testDefaultSfixed64() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultSfixed64, -50)
    XCTAssertFalse(msg.hasDefaultSfixed64)
    msg.defaultSfixed64 = 70
    XCTAssertTrue(msg.hasDefaultSfixed64)
    XCTAssertEqual(msg.defaultSfixed64, 70)
    msg.clearDefaultSfixed64()
    XCTAssertEqual(msg.defaultSfixed64, -50)
    XCTAssertFalse(msg.hasDefaultSfixed64)
  }

  func testDefaultFloat() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultFloat, 51.5)
    XCTAssertFalse(msg.hasDefaultFloat)
    msg.defaultFloat = 71
    XCTAssertTrue(msg.hasDefaultFloat)
    XCTAssertEqual(msg.defaultFloat, 71)
    msg.clearDefaultFloat()
    XCTAssertEqual(msg.defaultFloat, 51.5)
    XCTAssertFalse(msg.hasDefaultFloat)
  }

  func testDefaultDouble() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultDouble, 52e3)
    XCTAssertFalse(msg.hasDefaultDouble)
    msg.defaultDouble = 72
    XCTAssertTrue(msg.hasDefaultDouble)
    XCTAssertEqual(msg.defaultDouble, 72)
    msg.clearDefaultDouble()
    XCTAssertEqual(msg.defaultDouble, 52e3)
    XCTAssertFalse(msg.hasDefaultDouble)
  }

  func testDefaultBool() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultBool, true)
    XCTAssertFalse(msg.hasDefaultBool)
    msg.defaultBool = false
    XCTAssertTrue(msg.hasDefaultBool)
    XCTAssertEqual(msg.defaultBool, false)
    msg.clearDefaultBool()
    XCTAssertEqual(msg.defaultBool, true)
    XCTAssertFalse(msg.hasDefaultBool)
  }

  func testDefaultString() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultString, "hello")
    XCTAssertFalse(msg.hasDefaultString)
    msg.defaultString = "74"
    XCTAssertTrue(msg.hasDefaultString)
    XCTAssertEqual(msg.defaultString, "74")
    msg.clearDefaultString()
    XCTAssertEqual(msg.defaultString, "hello")
    XCTAssertFalse(msg.hasDefaultString)
  }

  func testDefaultBytes() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultBytes, "world".data(using: .utf8))
    XCTAssertFalse(msg.hasDefaultBytes)
    msg.defaultBytes = Data([75])
    XCTAssertTrue(msg.hasDefaultBytes)
    XCTAssertEqual(msg.defaultBytes, Data([75]))
    msg.clearDefaultBytes()
    XCTAssertEqual(msg.defaultBytes, "world".data(using: .utf8))
    XCTAssertFalse(msg.hasDefaultBytes)
  }

  func testDefaultNestedEnum() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultNestedEnum, .bar)
    XCTAssertFalse(msg.hasDefaultNestedEnum)
    msg.defaultNestedEnum = .baz
    XCTAssertTrue(msg.hasDefaultNestedEnum)
    XCTAssertEqual(msg.defaultNestedEnum, .baz)
    msg.clearDefaultNestedEnum()
    XCTAssertEqual(msg.defaultNestedEnum, .bar)
    XCTAssertFalse(msg.hasDefaultNestedEnum)
  }

  func testDefaultForeignEnum() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultForeignEnum, .foreignBar)
    XCTAssertFalse(msg.hasDefaultForeignEnum)
    msg.defaultForeignEnum = .foreignBaz
    XCTAssertTrue(msg.hasDefaultForeignEnum)
    XCTAssertEqual(msg.defaultForeignEnum, .foreignBaz)
    msg.clearDefaultForeignEnum()
    XCTAssertEqual(msg.defaultForeignEnum, .foreignBar)
    XCTAssertFalse(msg.hasDefaultForeignEnum)
  }

  func testDefaultImportEnum() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultImportEnum, .importBar)
    XCTAssertFalse(msg.hasDefaultImportEnum)
    msg.defaultImportEnum = .importBaz
    XCTAssertTrue(msg.hasDefaultImportEnum)
    XCTAssertEqual(msg.defaultImportEnum, .importBaz)
    msg.clearDefaultImportEnum()
    XCTAssertEqual(msg.defaultImportEnum, .importBar)
    XCTAssertFalse(msg.hasDefaultImportEnum)
  }

  func testDefaultStringPiece() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultStringPiece, "abc")
    XCTAssertFalse(msg.hasDefaultStringPiece)
    msg.defaultStringPiece = "84"
    XCTAssertTrue(msg.hasDefaultStringPiece)
    XCTAssertEqual(msg.defaultStringPiece, "84")
    msg.clearDefaultStringPiece()
    XCTAssertEqual(msg.defaultStringPiece, "abc")
    XCTAssertFalse(msg.hasDefaultStringPiece)
  }

  func testDefaultCord() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.defaultCord, "123")
    XCTAssertFalse(msg.hasDefaultCord)
    msg.defaultCord = "85"
    XCTAssertTrue(msg.hasDefaultCord)
    XCTAssertEqual(msg.defaultCord, "85")
    msg.clearDefaultCord()
    XCTAssertEqual(msg.defaultCord, "123")
    XCTAssertFalse(msg.hasDefaultCord)
  }

  // Repeated

  func testRepeatedInt32() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedInt32, [])
    msg.repeatedInt32 = [31]
    XCTAssertEqual(msg.repeatedInt32, [31])
    msg.repeatedInt32.append(131)
    XCTAssertEqual(msg.repeatedInt32, [31, 131])
  }

  func testRepeatedInt64() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedInt64, [])
    msg.repeatedInt64 = [32]
    XCTAssertEqual(msg.repeatedInt64, [32])
    msg.repeatedInt64.append(132)
    XCTAssertEqual(msg.repeatedInt64, [32, 132])
  }

  func testRepeatedUint32() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedUint32, [])
    msg.repeatedUint32 = [33]
    XCTAssertEqual(msg.repeatedUint32, [33])
    msg.repeatedUint32.append(133)
    XCTAssertEqual(msg.repeatedUint32, [33, 133])
  }

  func testRepeatedUint64() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedUint64, [])
    msg.repeatedUint64 = [34]
    XCTAssertEqual(msg.repeatedUint64, [34])
    msg.repeatedUint64.append(134)
    XCTAssertEqual(msg.repeatedUint64, [34, 134])
  }

  func testRepeatedSint32() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedSint32, [])
    msg.repeatedSint32 = [35]
    XCTAssertEqual(msg.repeatedSint32, [35])
    msg.repeatedSint32.append(135)
    XCTAssertEqual(msg.repeatedSint32, [35, 135])
  }

  func testRepeatedSint64() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedSint64, [])
    msg.repeatedSint64 = [36]
    XCTAssertEqual(msg.repeatedSint64, [36])
    msg.repeatedSint64.append(136)
    XCTAssertEqual(msg.repeatedSint64, [36, 136])
  }

  func testRepeatedFixed32() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedFixed32, [])
    msg.repeatedFixed32 = [37]
    XCTAssertEqual(msg.repeatedFixed32, [37])
    msg.repeatedFixed32.append(137)
    XCTAssertEqual(msg.repeatedFixed32, [37, 137])
  }

  func testRepeatedFixed64() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedFixed64, [])
    msg.repeatedFixed64 = [38]
    XCTAssertEqual(msg.repeatedFixed64, [38])
    msg.repeatedFixed64.append(138)
    XCTAssertEqual(msg.repeatedFixed64, [38, 138])
  }

  func testRepeatedSfixed32() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedSfixed32, [])
    msg.repeatedSfixed32 = [39]
    XCTAssertEqual(msg.repeatedSfixed32, [39])
    msg.repeatedSfixed32.append(139)
    XCTAssertEqual(msg.repeatedSfixed32, [39, 139])
  }

  func testRepeatedSfixed64() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedSfixed64, [])
    msg.repeatedSfixed64 = [40]
    XCTAssertEqual(msg.repeatedSfixed64, [40])
    msg.repeatedSfixed64.append(140)
    XCTAssertEqual(msg.repeatedSfixed64, [40, 140])
  }

  func testRepeatedFloat() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedFloat, [])
    msg.repeatedFloat = [41.0]
    XCTAssertEqual(msg.repeatedFloat, [41.0])
    msg.repeatedFloat.append(141.0)
    XCTAssertEqual(msg.repeatedFloat, [41.0, 141.0])
  }

  func testRepeatedDouble() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedDouble, [])
    msg.repeatedDouble = [42.0]
    XCTAssertEqual(msg.repeatedDouble, [42.0])
    msg.repeatedDouble.append(142.0)
    XCTAssertEqual(msg.repeatedDouble, [42.0, 142.0])
  }

  func testRepeatedBool() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedBool, [])
    msg.repeatedBool = [true]
    XCTAssertEqual(msg.repeatedBool, [true])
    msg.repeatedBool.append(false)
    XCTAssertEqual(msg.repeatedBool, [true, false])
  }

  func testRepeatedString() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedString, [])
    msg.repeatedString = ["44"]
    XCTAssertEqual(msg.repeatedString, ["44"])
    msg.repeatedString.append("144")
    XCTAssertEqual(msg.repeatedString, ["44", "144"])
  }

  func testRepeatedBytes() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedBytes, [])
    msg.repeatedBytes = [Data([45])]
    XCTAssertEqual(msg.repeatedBytes, [Data([45])])
    msg.repeatedBytes.append(Data([145]))
    XCTAssertEqual(msg.repeatedBytes, [Data([45]), Data([145])])
  }

  func testRepeatedGroup() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedGroup, [])
    var grp = ProtobufUnittest_TestAllTypes.RepeatedGroup()
    grp.a = 46
    msg.repeatedGroup = [grp]
    XCTAssertEqual(msg.repeatedGroup.count, 1)
    XCTAssertEqual(msg.repeatedGroup[0].a, 46)
    XCTAssertEqual(msg.repeatedGroup, [grp])
    var grp2 = ProtobufUnittest_TestAllTypes.RepeatedGroup()
    grp2.a = 146
    msg.repeatedGroup.append(grp2)
    XCTAssertEqual(msg.repeatedGroup.count, 2)
    XCTAssertEqual(msg.repeatedGroup[0].a, 46)
    XCTAssertEqual(msg.repeatedGroup[1].a, 146)
    XCTAssertEqual(msg.repeatedGroup, [grp, grp2])
  }

  func testRepeatedNestedMessage() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedNestedMessage, [])
    var nestedMsg = ProtobufUnittest_TestAllTypes.NestedMessage()
    nestedMsg.bb = 48
    msg.repeatedNestedMessage = [nestedMsg]
    XCTAssertEqual(msg.repeatedNestedMessage.count, 1)
    XCTAssertEqual(msg.repeatedNestedMessage[0].bb, 48)
    XCTAssertEqual(msg.repeatedNestedMessage, [nestedMsg])
    var nestedMsg2 = ProtobufUnittest_TestAllTypes.NestedMessage()
    nestedMsg2.bb = 148
    msg.repeatedNestedMessage.append(nestedMsg2)
    XCTAssertEqual(msg.repeatedNestedMessage.count, 2)
    XCTAssertEqual(msg.repeatedNestedMessage[0].bb, 48)
    XCTAssertEqual(msg.repeatedNestedMessage[1].bb, 148)
    XCTAssertEqual(msg.repeatedNestedMessage, [nestedMsg, nestedMsg2])
  }

  func testRepeatedForeignMessage() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedForeignMessage, [])
    var foreignMsg = ProtobufUnittest_ForeignMessage()
    foreignMsg.c = 49
    msg.repeatedForeignMessage = [foreignMsg]
    XCTAssertEqual(msg.repeatedForeignMessage.count, 1)
    XCTAssertEqual(msg.repeatedForeignMessage[0].c, 49)
    XCTAssertEqual(msg.repeatedForeignMessage, [foreignMsg])
    var foreignMsg2 = ProtobufUnittest_ForeignMessage()
    foreignMsg2.c = 149
    msg.repeatedForeignMessage.append(foreignMsg2)
    XCTAssertEqual(msg.repeatedForeignMessage.count, 2)
    XCTAssertEqual(msg.repeatedForeignMessage[0].c, 49)
    XCTAssertEqual(msg.repeatedForeignMessage[1].c, 149)
    XCTAssertEqual(msg.repeatedForeignMessage, [foreignMsg, foreignMsg2])
  }

  func testRepeatedImportMessage() {
    var msg = ProtobufUnittest_TestAllTypes()
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
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedNestedEnum, [])
    msg.repeatedNestedEnum = [.bar]
    XCTAssertEqual(msg.repeatedNestedEnum, [.bar])
    msg.repeatedNestedEnum.append(.baz)
    XCTAssertEqual(msg.repeatedNestedEnum, [.bar, .baz])
  }

  func testRepeatedForeignEnum() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedForeignEnum, [])
    msg.repeatedForeignEnum = [.foreignBar]
    XCTAssertEqual(msg.repeatedForeignEnum, [.foreignBar])
    msg.repeatedForeignEnum.append(.foreignBaz)
    XCTAssertEqual(msg.repeatedForeignEnum, [.foreignBar, .foreignBaz])
  }

  func testRepeatedImportEnum() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedImportEnum, [])
    msg.repeatedImportEnum = [.importBar]
    XCTAssertEqual(msg.repeatedImportEnum, [.importBar])
    msg.repeatedImportEnum.append(.importBaz)
    XCTAssertEqual(msg.repeatedImportEnum, [.importBar, .importBaz])
  }

  func testRepeatedStringPiece() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedStringPiece, [])
    msg.repeatedStringPiece = ["54"]
    XCTAssertEqual(msg.repeatedStringPiece, ["54"])
    msg.repeatedStringPiece.append("154")
    XCTAssertEqual(msg.repeatedStringPiece, ["54", "154"])
  }

  func testRepeatedCord() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedCord, [])
    msg.repeatedCord = ["55"]
    XCTAssertEqual(msg.repeatedCord, ["55"])
    msg.repeatedCord.append("155")
    XCTAssertEqual(msg.repeatedCord, ["55", "155"])
  }

  func testRepeatedLazyMessage() {
    var msg = ProtobufUnittest_TestAllTypes()
    XCTAssertEqual(msg.repeatedLazyMessage, [])
    var nestedMsg = ProtobufUnittest_TestAllTypes.NestedMessage()
    nestedMsg.bb = 57
    msg.repeatedLazyMessage = [nestedMsg]
    XCTAssertEqual(msg.repeatedLazyMessage.count, 1)
    XCTAssertEqual(msg.repeatedLazyMessage[0].bb, 57)
    XCTAssertEqual(msg.repeatedLazyMessage, [nestedMsg])
    var nestedMsg2 = ProtobufUnittest_TestAllTypes.NestedMessage()
    nestedMsg2.bb = 157
    msg.repeatedLazyMessage.append(nestedMsg2)
    XCTAssertEqual(msg.repeatedLazyMessage.count, 2)
    XCTAssertEqual(msg.repeatedLazyMessage[0].bb, 57)
    XCTAssertEqual(msg.repeatedLazyMessage[1].bb, 157)
    XCTAssertEqual(msg.repeatedLazyMessage, [nestedMsg, nestedMsg2])
  }

}
