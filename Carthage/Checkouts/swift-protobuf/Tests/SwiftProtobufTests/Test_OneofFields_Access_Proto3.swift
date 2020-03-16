// Test/Sources/TestSuite/Test_OneofFields_Access_Proto3.swift
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Exercises the apis for fields within a oneof.
///
// -----------------------------------------------------------------------------

import XCTest
import Foundation

// NOTE: The generator changes what is generated based on the number/types
// of fields (using a nested storage class or not), to be completel, all
// these tests should be done once with a message that gets that storage
// class and a second time with messages that avoid that.

class Test_OneofFields_Access_Proto3: XCTestCase {

  // Accessing one field.
  // - Returns default
  // - Accepts/Captures value
  // - Resets
  // - Accepts/Captures default value

  func testOneofInt32() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.oneofInt32, 0)
    XCTAssertNil(msg.o)
    msg.oneofInt32 = 51
    XCTAssertEqual(msg.oneofInt32, 51)
    XCTAssertEqual(msg.o, .oneofInt32(51))
    msg.o = nil
    XCTAssertEqual(msg.oneofInt32, 0)
    XCTAssertNil(msg.o)
    msg.oneofInt32 = 0
    XCTAssertEqual(msg.oneofInt32, 0)
    XCTAssertEqual(msg.o, .oneofInt32(0))
  }

  func testOneofInt64() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.oneofInt64, 0)
    XCTAssertNil(msg.o)
    msg.oneofInt64 = 52
    XCTAssertEqual(msg.oneofInt64, 52)
    XCTAssertEqual(msg.o, .oneofInt64(52))
    msg.o = nil
    XCTAssertEqual(msg.oneofInt64, 0)
    XCTAssertNil(msg.o)
    msg.oneofInt64 = 0
    XCTAssertEqual(msg.oneofInt64, 0)
    XCTAssertEqual(msg.o, .oneofInt64(0))
  }

  func testOneofUint32() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.oneofUint32, 0)
    XCTAssertNil(msg.o)
    msg.oneofUint32 = 53
    XCTAssertEqual(msg.oneofUint32, 53)
    XCTAssertEqual(msg.o, .oneofUint32(53))
    msg.o = nil
    XCTAssertEqual(msg.oneofUint32, 0)
    XCTAssertNil(msg.o)
    msg.oneofUint32 = 0
    XCTAssertEqual(msg.oneofUint32, 0)
    XCTAssertEqual(msg.o, .oneofUint32(0))
  }

  func testOneofUint64() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.oneofUint64, 0)
    XCTAssertNil(msg.o)
    msg.oneofUint64 = 54
    XCTAssertEqual(msg.oneofUint64, 54)
    XCTAssertEqual(msg.o, .oneofUint64(54))
    msg.o = nil
    XCTAssertEqual(msg.oneofUint64, 0)
    XCTAssertNil(msg.o)
    msg.oneofUint64 = 0
    XCTAssertEqual(msg.oneofUint64, 0)
    XCTAssertEqual(msg.o, .oneofUint64(0))
  }

  func testOneofSint32() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.oneofSint32, 0)
    XCTAssertNil(msg.o)
    msg.oneofSint32 = 55
    XCTAssertEqual(msg.oneofSint32, 55)
    XCTAssertEqual(msg.o, .oneofSint32(55))
    msg.o = nil
    XCTAssertEqual(msg.oneofSint32, 0)
    XCTAssertNil(msg.o)
    msg.oneofSint32 = 0
    XCTAssertEqual(msg.oneofSint32, 0)
    XCTAssertEqual(msg.o, .oneofSint32(0))
  }

  func testOneofSint64() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.oneofSint64, 0)
    XCTAssertNil(msg.o)
    msg.oneofSint64 = 56
    XCTAssertEqual(msg.oneofSint64, 56)
    XCTAssertEqual(msg.o, .oneofSint64(56))
    msg.o = nil
    XCTAssertEqual(msg.oneofSint64, 0)
    XCTAssertNil(msg.o)
    msg.oneofSint64 = 0
    XCTAssertEqual(msg.oneofSint64, 0)
    XCTAssertEqual(msg.o, .oneofSint64(0))
  }

  func testOneofFixed32() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.oneofFixed32, 0)
    XCTAssertNil(msg.o)
    msg.oneofFixed32 = 57
    XCTAssertEqual(msg.oneofFixed32, 57)
    XCTAssertEqual(msg.o, .oneofFixed32(57))
    msg.o = nil
    XCTAssertEqual(msg.oneofFixed32, 0)
    XCTAssertNil(msg.o)
    msg.oneofFixed32 = 0
    XCTAssertEqual(msg.oneofFixed32, 0)
    XCTAssertEqual(msg.o, .oneofFixed32(0))
  }

  func testOneofFixed64() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.oneofFixed64, 0)
    XCTAssertNil(msg.o)
    msg.oneofFixed64 = 58
    XCTAssertEqual(msg.oneofFixed64, 58)
    XCTAssertEqual(msg.o, .oneofFixed64(58))
    msg.o = nil
    XCTAssertEqual(msg.oneofFixed64, 0)
    XCTAssertNil(msg.o)
    msg.oneofFixed64 = 0
    XCTAssertEqual(msg.oneofFixed64, 0)
    XCTAssertEqual(msg.o, .oneofFixed64(0))
  }

  func testOneofSfixed32() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.oneofSfixed32, 0)
    XCTAssertNil(msg.o)
    msg.oneofSfixed32 = 59
    XCTAssertEqual(msg.oneofSfixed32, 59)
    XCTAssertEqual(msg.o, .oneofSfixed32(59))
    msg.o = nil
    XCTAssertEqual(msg.oneofSfixed32, 0)
    XCTAssertNil(msg.o)
    msg.oneofSfixed32 = 0
    XCTAssertEqual(msg.oneofSfixed32, 0)
    XCTAssertEqual(msg.o, .oneofSfixed32(0))
  }

  func testOneofSfixed64() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.oneofSfixed64, 0)
    XCTAssertNil(msg.o)
    msg.oneofSfixed64 = 60
    XCTAssertEqual(msg.oneofSfixed64, 60)
    XCTAssertEqual(msg.o, .oneofSfixed64(60))
    msg.o = nil
    XCTAssertEqual(msg.oneofSfixed64, 0)
    XCTAssertNil(msg.o)
    msg.oneofSfixed64 = 0
    XCTAssertEqual(msg.oneofSfixed64, 0)
    XCTAssertEqual(msg.o, .oneofSfixed64(0))
  }

  func testOneofFloat() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.oneofFloat, 0.0)
    XCTAssertNil(msg.o)
    msg.oneofFloat = 61.0
    XCTAssertEqual(msg.oneofFloat, 61.0)
    XCTAssertEqual(msg.o, .oneofFloat(61.0))
    msg.o = nil
    XCTAssertEqual(msg.oneofFloat, 0.0)
    XCTAssertNil(msg.o)
    msg.oneofFloat = 0.0
    XCTAssertEqual(msg.oneofFloat, 0.0)
    XCTAssertEqual(msg.o, .oneofFloat(0.0))
  }

  func testOneofDouble() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.oneofDouble, 0.0)
    XCTAssertNil(msg.o)
    msg.oneofDouble = 62.0
    XCTAssertEqual(msg.oneofDouble, 62.0)
    XCTAssertEqual(msg.o, .oneofDouble(62.0))
    msg.o = nil
    XCTAssertEqual(msg.oneofDouble, 0.0)
    XCTAssertNil(msg.o)
    msg.oneofDouble = 0.0
    XCTAssertEqual(msg.oneofDouble, 0.0)
    XCTAssertEqual(msg.o, .oneofDouble(0.0))
  }

  func testOneofBool() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.oneofBool, false)
    XCTAssertNil(msg.o)
    msg.oneofBool = true
    XCTAssertEqual(msg.oneofBool, true)
    XCTAssertEqual(msg.o, .oneofBool(true))
    msg.o = nil
    XCTAssertEqual(msg.oneofBool, false)
    XCTAssertNil(msg.o)
    msg.oneofBool = false
    XCTAssertEqual(msg.oneofBool, false)
    XCTAssertEqual(msg.o, .oneofBool(false))
  }

  func testOneofString() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.oneofString, "")
    XCTAssertNil(msg.o)
    msg.oneofString = "64"
    XCTAssertEqual(msg.oneofString, "64")
    XCTAssertEqual(msg.o, .oneofString("64"))
    msg.o = nil
    XCTAssertEqual(msg.oneofString, "")
    XCTAssertNil(msg.o)
    msg.oneofString = ""
    XCTAssertEqual(msg.oneofString, "")
    XCTAssertEqual(msg.o, .oneofString(""))
  }

  func testOneofBytes() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.oneofBytes, Data())
    XCTAssertNil(msg.o)
    msg.oneofBytes = Data([65])
    XCTAssertEqual(msg.oneofBytes, Data([65]))
    XCTAssertEqual(msg.o, .oneofBytes(Data([65])))
    msg.o = nil
    XCTAssertEqual(msg.oneofBytes, Data())
    XCTAssertNil(msg.o)
    msg.oneofBytes = Data()
    XCTAssertEqual(msg.oneofBytes, Data())
    XCTAssertEqual(msg.o, .oneofBytes(Data()))
  }

  // No group.

  func testOneofMessage() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.oneofMessage.optionalInt32, 0)
    XCTAssertNil(msg.o)
    var subMsg = ProtobufUnittest_Message3()
    subMsg.optionalInt32 = 66
    msg.oneofMessage = subMsg
    XCTAssertEqual(msg.oneofMessage.optionalInt32, 66)
    XCTAssertEqual(msg.oneofMessage, subMsg)
    if case .oneofMessage(let v)? = msg.o {
      XCTAssertEqual(v.optionalInt32, 66)
      XCTAssertEqual(v, subMsg)
    } else {
      XCTFail("Wasn't the right case")
    }
    msg.o = nil
    XCTAssertEqual(msg.oneofMessage.optionalInt32, 0)
    XCTAssertNil(msg.o)
    // Default within the message
    var subMsg2 = ProtobufUnittest_Message3()
    subMsg2.optionalInt32 = 0
    msg.oneofMessage = subMsg2
    XCTAssertEqual(msg.oneofMessage.optionalInt32, 0)
    XCTAssertEqual(msg.oneofMessage, subMsg2)
    if case .oneofMessage(let v)? = msg.o {
      XCTAssertEqual(v.optionalInt32, 0)
      XCTAssertEqual(v, subMsg2)
    } else {
      XCTFail("Wasn't the right case")
    }
    msg.o = nil
    // Message with nothing set.
    let subMsg3 = ProtobufUnittest_Message3()
    msg.oneofMessage = subMsg3
    XCTAssertEqual(msg.oneofMessage.optionalInt32, 0)
    XCTAssertEqual(msg.oneofMessage, subMsg3)
    if case .oneofMessage(let v)? = msg.o {
      XCTAssertEqual(v.optionalInt32, 0)
      XCTAssertEqual(v, subMsg3)
    } else {
      XCTFail("Wasn't the right case")
    }
  }

  func testOneofEnum() {
    var msg = ProtobufUnittest_Message3()
    XCTAssertEqual(msg.oneofEnum, .foo)
    XCTAssertNil(msg.o)
    msg.oneofEnum = .bar
    XCTAssertEqual(msg.oneofEnum, .bar)
    XCTAssertEqual(msg.o, .oneofEnum(.bar))
    msg.o = nil
    XCTAssertEqual(msg.oneofEnum, .foo)
    XCTAssertNil(msg.o)
    msg.oneofEnum = .foo
    XCTAssertEqual(msg.oneofEnum, .foo)
    XCTAssertEqual(msg.o, .oneofEnum(.foo))
  }

  // Chaining. Set each item in the oneof clear the previous one.

  func testOneofOnlyOneSet() {
    var msg = ProtobufUnittest_Message3()

    func assertRightFiledSet(_ i: Int) {
      // Make sure the case is correct for the enum based access.
      switch msg.o {
      case nil:
        XCTAssertEqual(i, 0)
      case .oneofInt32(let v)?:
        XCTAssertEqual(i, 1)
        XCTAssertEqual(v, 51)
      case .oneofInt64(let v)?:
        XCTAssertEqual(i, 2)
        XCTAssertEqual(v, 52)
      case .oneofUint32(let v)?:
        XCTAssertEqual(i, 3)
        XCTAssertEqual(v, 53)
      case .oneofUint64(let v)?:
        XCTAssertEqual(i, 4)
        XCTAssertEqual(v, 54)
      case .oneofSint32(let v)?:
        XCTAssertEqual(i, 5)
        XCTAssertEqual(v, 55)
      case .oneofSint64(let v)?:
        XCTAssertEqual(i, 6)
        XCTAssertEqual(v, 56)
      case .oneofFixed32(let v)?:
        XCTAssertEqual(i, 7)
        XCTAssertEqual(v, 57)
      case .oneofFixed64(let v)?:
        XCTAssertEqual(i, 8)
        XCTAssertEqual(v, 58)
      case .oneofSfixed32(let v)?:
        XCTAssertEqual(i, 9)
        XCTAssertEqual(v, 59)
      case .oneofSfixed64(let v)?:
        XCTAssertEqual(i, 10)
        XCTAssertEqual(v, 60)
      case .oneofFloat(let v)?:
        XCTAssertEqual(i, 11)
        XCTAssertEqual(v, 61.0)
      case .oneofDouble(let v)?:
        XCTAssertEqual(i, 12)
        XCTAssertEqual(v, 62.0)
      case .oneofBool(let v)?:
        XCTAssertEqual(i, 13)
        XCTAssertEqual(v, true)
      case .oneofString(let v)?:
        XCTAssertEqual(i, 14)
        XCTAssertEqual(v, "64")
      case .oneofBytes(let v)?:
        XCTAssertEqual(i, 15)
        XCTAssertEqual(v, Data([65]))
      // No group.
      case .oneofMessage(let v)?:
        XCTAssertEqual(i, 17)
        XCTAssertEqual(v.optionalInt32, 68)
      case .oneofEnum(let v)?:
        XCTAssertEqual(i, 18)
        XCTAssertEqual(v, .bar)
      }

      // Check direct field access (gets the right value or the default)
      if i == 1 {
        XCTAssertEqual(msg.oneofInt32, 51)
      } else {
        XCTAssertEqual(msg.oneofInt32, 0, "i = \(i)")
      }
      if i == 2 {
        XCTAssertEqual(msg.oneofInt64, 52)
      } else {
        XCTAssertEqual(msg.oneofInt64, 0, "i = \(i)")
      }
      if i == 3 {
        XCTAssertEqual(msg.oneofUint32, 53)
      } else {
        XCTAssertEqual(msg.oneofUint32, 0, "i = \(i)")
      }
      if i == 4 {
        XCTAssertEqual(msg.oneofUint64, 54)
      } else {
        XCTAssertEqual(msg.oneofUint64, 0, "i = \(i)")
      }
      if i == 5 {
        XCTAssertEqual(msg.oneofSint32, 55)
      } else {
        XCTAssertEqual(msg.oneofSint32, 0, "i = \(i)")
      }
      if i == 6 {
        XCTAssertEqual(msg.oneofSint64, 56)
      } else {
        XCTAssertEqual(msg.oneofSint64, 0, "i = \(i)")
      }
      if i == 7 {
        XCTAssertEqual(msg.oneofFixed32, 57)
      } else {
        XCTAssertEqual(msg.oneofFixed32, 0, "i = \(i)")
      }
      if i == 8 {
        XCTAssertEqual(msg.oneofFixed64, 58)
      } else {
        XCTAssertEqual(msg.oneofFixed64, 0, "i = \(i)")
      }
      if i == 9 {
        XCTAssertEqual(msg.oneofSfixed32, 59)
      } else {
        XCTAssertEqual(msg.oneofSfixed32, 0, "i = \(i)")
      }
      if i == 10 {
        XCTAssertEqual(msg.oneofSfixed64, 60)
      } else {
        XCTAssertEqual(msg.oneofSfixed64, 0, "i = \(i)")
      }
      if i == 11 {
        XCTAssertEqual(msg.oneofFloat, 61.0)
      } else {
        XCTAssertEqual(msg.oneofFloat, 0.0, "i = \(i)")
      }
      if i == 12 {
        XCTAssertEqual(msg.oneofDouble, 62.0)
      } else {
        XCTAssertEqual(msg.oneofDouble, 0.0, "i = \(i)")
      }
      if i == 13 {
        XCTAssertEqual(msg.oneofBool, true)
      } else {
        XCTAssertEqual(msg.oneofBool, false, "i = \(i)")
      }
      if i == 14 {
        XCTAssertEqual(msg.oneofString, "64")
      } else {
        XCTAssertEqual(msg.oneofString, "", "i = \(i)")
      }
      if i == 15 {
        XCTAssertEqual(msg.oneofBytes, Data([65]))
      } else {
        XCTAssertEqual(msg.oneofBytes, Data(), "i = \(i)")
      }
      // No group
      if i == 17 {
        XCTAssertEqual(msg.oneofMessage.optionalInt32, 68)
      } else {
        XCTAssertEqual(msg.oneofMessage.optionalInt32, 0, "i = \(i)")
      }
      if i == 18 {
        XCTAssertEqual(msg.oneofEnum, .bar)
      } else {
        XCTAssertEqual(msg.oneofEnum, .foo, "i = \(i)")
      }
    }

    // Now cycle through the cases.
    assertRightFiledSet(0)
    msg.oneofInt32 = 51
    assertRightFiledSet(1)
    msg.oneofInt64 = 52
    assertRightFiledSet(2)
    msg.oneofUint32 = 53
    assertRightFiledSet(3)
    msg.oneofUint64 = 54
    assertRightFiledSet(4)
    msg.oneofSint32 = 55
    assertRightFiledSet(5)
    msg.oneofSint64 = 56
    assertRightFiledSet(6)
    msg.oneofFixed32 = 57
    assertRightFiledSet(7)
    msg.oneofFixed64 = 58
    assertRightFiledSet(8)
    msg.oneofSfixed32 = 59
    assertRightFiledSet(9)
    msg.oneofSfixed64 = 60
    assertRightFiledSet(10)
    msg.oneofFloat = 61
    assertRightFiledSet(11)
    msg.oneofDouble = 62
    assertRightFiledSet(12)
    msg.oneofBool = true
    assertRightFiledSet(13)
    msg.oneofString = "64"
    assertRightFiledSet(14)
    msg.oneofBytes = Data([65])
    assertRightFiledSet(15)
    // No group
    msg.oneofMessage.optionalInt32 = 68
    assertRightFiledSet(17)
    msg.oneofEnum = .bar
    assertRightFiledSet(18)
  }
}
