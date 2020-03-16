// Test/Sources/TestSuite/Test_MapFields_Access_Proto3.swift
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Exercises the apis map fields.
///
// -----------------------------------------------------------------------------

import XCTest
import Foundation

// NOTE: The generator changes what is generated based on the number/types
// of fields (using a nested storage class or not), to be completel, all
// these tests should be done once with a message that gets that storage
// class and a second time with messages that avoid that.

class Test_MapFields_Access_Proto3: XCTestCase {

  func testMapInt32Int32() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapInt32Int32, [:])
    msg.mapInt32Int32 = [70: 1070]
    XCTAssertEqual(msg.mapInt32Int32, [70: 1070])
    msg.mapInt32Int32[170] = 1170
    XCTAssertEqual(msg.mapInt32Int32, [70: 1070, 170: 1170])
  }

  func testMapInt64Int64() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapInt64Int64, [:])
    msg.mapInt64Int64 = [71: 1071]
    XCTAssertEqual(msg.mapInt64Int64, [71: 1071])
    msg.mapInt64Int64[171] = 1171
    XCTAssertEqual(msg.mapInt64Int64, [71: 1071, 171: 1171])
  }

  func testMapUint32Uint32() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapUint32Uint32, [:])
    msg.mapUint32Uint32 = [72: 1072]
    XCTAssertEqual(msg.mapUint32Uint32, [72: 1072])
    msg.mapUint32Uint32[172] = 1172
    XCTAssertEqual(msg.mapUint32Uint32, [72: 1072, 172: 1172])
  }

  func testMapUint64Uint64() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapUint64Uint64, [:])
    msg.mapUint64Uint64 = [73: 1073]
    XCTAssertEqual(msg.mapUint64Uint64, [73: 1073])
    msg.mapUint64Uint64[173] = 1173
    XCTAssertEqual(msg.mapUint64Uint64, [73: 1073, 173: 1173])
  }

  func testMapSint32Sint32() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapSint32Sint32, [:])
    msg.mapSint32Sint32 = [74: 1074]
    XCTAssertEqual(msg.mapSint32Sint32, [74: 1074])
    msg.mapSint32Sint32[174] = 1174
    XCTAssertEqual(msg.mapSint32Sint32, [74: 1074, 174: 1174])
  }

  func testMapSint64Sint64() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapSint64Sint64, [:])
    msg.mapSint64Sint64 = [75: 1075]
    XCTAssertEqual(msg.mapSint64Sint64, [75: 1075])
    msg.mapSint64Sint64[175] = 1175
    XCTAssertEqual(msg.mapSint64Sint64, [75: 1075, 175: 1175])
  }

  func testMapFixed32Fixed32() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapFixed32Fixed32, [:])
    msg.mapFixed32Fixed32 = [76: 1076]
    XCTAssertEqual(msg.mapFixed32Fixed32, [76: 1076])
    msg.mapFixed32Fixed32[176] = 1176
    XCTAssertEqual(msg.mapFixed32Fixed32, [76: 1076, 176: 1176])
  }

  func testMapFixed64Fixed64() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapFixed64Fixed64, [:])
    msg.mapFixed64Fixed64 = [77: 1077]
    XCTAssertEqual(msg.mapFixed64Fixed64, [77: 1077])
    msg.mapFixed64Fixed64[177] = 1177
    XCTAssertEqual(msg.mapFixed64Fixed64, [77: 1077, 177: 1177])
  }

  func testMapSfixed32Sfixed32() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapSfixed32Sfixed32, [:])
    msg.mapSfixed32Sfixed32 = [78: 1078]
    XCTAssertEqual(msg.mapSfixed32Sfixed32, [78: 1078])
    msg.mapSfixed32Sfixed32[178] = 1178
    XCTAssertEqual(msg.mapSfixed32Sfixed32, [78: 1078, 178: 1178])
  }

  func testMapSfixed64Sfixed64() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapSfixed64Sfixed64, [:])
    msg.mapSfixed64Sfixed64 = [79: 1079]
    XCTAssertEqual(msg.mapSfixed64Sfixed64, [79: 1079])
    msg.mapSfixed64Sfixed64[179] = 1179
    XCTAssertEqual(msg.mapSfixed64Sfixed64, [79: 1079, 179: 1179])
  }

  func testMapInt32Float() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapInt32Float, [:])
    msg.mapInt32Float = [80: 1080.0]
    XCTAssertEqual(msg.mapInt32Float, [80: 1080.0])
    msg.mapInt32Float[180] = 1180.0
    XCTAssertEqual(msg.mapInt32Float, [80: 1080.0, 180: 1180.0])
  }

  func testMapInt32Double() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapInt32Double, [:])
    msg.mapInt32Double = [81: 1081.0]
    XCTAssertEqual(msg.mapInt32Double, [81: 1081.0])
    msg.mapInt32Double[181] = 1181.0
    XCTAssertEqual(msg.mapInt32Double, [81: 1081, 181: 1181.0])
  }

  func testMapBoolBool() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapBoolBool, [:])
    msg.mapBoolBool = [true: false]
    XCTAssertEqual(msg.mapBoolBool, [true: false])
    msg.mapBoolBool[false] = true
    XCTAssertEqual(msg.mapBoolBool, [true: false, false: true])
  }

  func testMapStringString() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapStringString, [:])
    msg.mapStringString = ["83": "1083"]
    XCTAssertEqual(msg.mapStringString, ["83": "1083"])
    msg.mapStringString["183"] = "1183"
    XCTAssertEqual(msg.mapStringString, ["83": "1083", "183": "1183"])
  }

  func testMapStringBytes() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapStringBytes, [:])
    msg.mapStringBytes = ["84": Data([84])]
    XCTAssertEqual(msg.mapStringBytes, ["84": Data([84])])
    msg.mapStringBytes["184"] = Data([184])
    XCTAssertEqual(msg.mapStringBytes, ["84": Data([84]), "184": Data([184])])
  }

  func testMapStringMessage() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapStringMessage, [:])
    var valueMsg1 = ProtobufUnittest_Message3()
    valueMsg1.optionalInt32 = 1085
    msg.mapStringMessage = ["85": valueMsg1]
    XCTAssertEqual(msg.mapStringMessage.count, 1)
    if let v = msg.mapStringMessage["85"] {
      XCTAssertEqual(v.optionalInt32, 1085)
    } else {
      XCTFail("Lookup failed")
    }
    XCTAssertEqual(msg.mapStringMessage, ["85": valueMsg1])
    var valueMsg2 = ProtobufUnittest_Message3()
    valueMsg2.optionalInt32 = 1185
    msg.mapStringMessage["185"] = valueMsg2
    XCTAssertEqual(msg.mapStringMessage.count, 2)
    if let v = msg.mapStringMessage["85"] {
      XCTAssertEqual(v.optionalInt32, 1085)
    } else {
      XCTFail("Lookup failed")
    }
    if let v = msg.mapStringMessage["185"] {
      XCTAssertEqual(v.optionalInt32, 1185)
    } else {
      XCTFail("Lookup failed")
    }
    XCTAssertEqual(msg.mapStringMessage, ["85": valueMsg1, "185": valueMsg2])
  }

  func testMapInt32Bytes() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapInt32Bytes, [:])
    msg.mapInt32Bytes = [86: Data([86])]
    XCTAssertEqual(msg.mapInt32Bytes, [86: Data([86])])
    msg.mapInt32Bytes[186] = Data([186])
    XCTAssertEqual(msg.mapInt32Bytes, [86: Data([86]), 186: Data([186])])
  }

  func testMapInt32Enum() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapInt32Enum, [:])
    msg.mapInt32Enum = [87: .bar]
    XCTAssertEqual(msg.mapInt32Enum, [87: .bar])
    msg.mapInt32Enum[187] = .baz
    XCTAssertEqual(msg.mapInt32Enum, [87: .bar, 187: .baz])
  }

  func testMapInt32Message() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.mapInt32Message, [:])
    var valueMsg1 = ProtobufUnittest_Message3()
    valueMsg1.optionalInt32 = 1088
    msg.mapInt32Message = [88: valueMsg1]
    XCTAssertEqual(msg.mapInt32Message.count, 1)
    if let v = msg.mapInt32Message[88] {
      XCTAssertEqual(v.optionalInt32, 1088)
    } else {
      XCTFail("Lookup failed")
    }
    XCTAssertEqual(msg.mapInt32Message, [88: valueMsg1])
    var valueMsg2 = ProtobufUnittest_Message3()
    valueMsg2.optionalInt32 = 1188
    msg.mapInt32Message[188] = valueMsg2
    XCTAssertEqual(msg.mapInt32Message.count, 2)
    if let v = msg.mapInt32Message[88] {
      XCTAssertEqual(v.optionalInt32, 1088)
    } else {
      XCTFail("Lookup failed")
    }
    if let v = msg.mapInt32Message[188] {
      XCTAssertEqual(v.optionalInt32, 1188)
    } else {
      XCTFail("Lookup failed")
    }
    XCTAssertEqual(msg.mapInt32Message, [88: valueMsg1, 188: valueMsg2])
  }

}
