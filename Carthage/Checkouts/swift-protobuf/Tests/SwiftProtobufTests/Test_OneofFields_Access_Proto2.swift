// Test/Sources/TestSuite/Test_OneofFields_Access_Proto2.swift
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

class Test_OneofFields_Access_Proto2: XCTestCase {

  // Accessing one field.
  // - Returns default
  // - Accepts/Captures value
  // - Resets
  // - Accepts/Captures default value

  func testOneofInt32() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofInt32, 100)
    XCTAssertNil(msg.o)
    msg.oneofInt32 = 51
    XCTAssertEqual(msg.oneofInt32, 51)
    XCTAssertEqual(msg.o, .oneofInt32(51))
    msg.o = nil
    XCTAssertEqual(msg.oneofInt32, 100)
    XCTAssertNil(msg.o)
    msg.oneofInt32 = 100
    XCTAssertEqual(msg.oneofInt32, 100)
    XCTAssertEqual(msg.o, .oneofInt32(100))
  }

  func testOneofInt64() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofInt64, 101)
    XCTAssertNil(msg.o)
    msg.oneofInt64 = 52
    XCTAssertEqual(msg.oneofInt64, 52)
    XCTAssertEqual(msg.o, .oneofInt64(52))
    msg.o = nil
    XCTAssertEqual(msg.oneofInt64, 101)
    XCTAssertNil(msg.o)
    msg.oneofInt64 = 101
    XCTAssertEqual(msg.oneofInt64, 101)
    XCTAssertEqual(msg.o, .oneofInt64(101))
  }

  func testOneofUint32() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofUint32, 102)
    XCTAssertNil(msg.o)
    msg.oneofUint32 = 53
    XCTAssertEqual(msg.oneofUint32, 53)
    XCTAssertEqual(msg.o, .oneofUint32(53))
    msg.o = nil
    XCTAssertEqual(msg.oneofUint32, 102)
    XCTAssertNil(msg.o)
    msg.oneofUint32 = 102
    XCTAssertEqual(msg.oneofUint32, 102)
    XCTAssertEqual(msg.o, .oneofUint32(102))
  }

  func testOneofUint64() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofUint64, 103)
    XCTAssertNil(msg.o)
    msg.oneofUint64 = 54
    XCTAssertEqual(msg.oneofUint64, 54)
    XCTAssertEqual(msg.o, .oneofUint64(54))
    msg.o = nil
    XCTAssertEqual(msg.oneofUint64, 103)
    XCTAssertNil(msg.o)
    msg.oneofUint64 = 103
    XCTAssertEqual(msg.oneofUint64, 103)
    XCTAssertEqual(msg.o, .oneofUint64(103))
  }

  func testOneofSint32() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofSint32, 104)
    XCTAssertNil(msg.o)
    msg.oneofSint32 = 55
    XCTAssertEqual(msg.oneofSint32, 55)
    XCTAssertEqual(msg.o, .oneofSint32(55))
    msg.o = nil
    XCTAssertEqual(msg.oneofSint32, 104)
    XCTAssertNil(msg.o)
    msg.oneofSint32 = 104
    XCTAssertEqual(msg.oneofSint32, 104)
    XCTAssertEqual(msg.o, .oneofSint32(104))
  }

  func testOneofSint64() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofSint64, 105)
    XCTAssertNil(msg.o)
    msg.oneofSint64 = 56
    XCTAssertEqual(msg.oneofSint64, 56)
    XCTAssertEqual(msg.o, .oneofSint64(56))
    msg.o = nil
    XCTAssertEqual(msg.oneofSint64, 105)
    XCTAssertNil(msg.o)
    msg.oneofSint64 = 105
    XCTAssertEqual(msg.oneofSint64, 105)
    XCTAssertEqual(msg.o, .oneofSint64(105))
  }

  func testOneofFixed32() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofFixed32, 106)
    XCTAssertNil(msg.o)
    msg.oneofFixed32 = 57
    XCTAssertEqual(msg.oneofFixed32, 57)
    XCTAssertEqual(msg.o, .oneofFixed32(57))
    msg.o = nil
    XCTAssertEqual(msg.oneofFixed32, 106)
    XCTAssertNil(msg.o)
    msg.oneofFixed32 = 106
    XCTAssertEqual(msg.oneofFixed32, 106)
    XCTAssertEqual(msg.o, .oneofFixed32(106))
  }

  func testOneofFixed64() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofFixed64, 107)
    XCTAssertNil(msg.o)
    msg.oneofFixed64 = 58
    XCTAssertEqual(msg.oneofFixed64, 58)
    XCTAssertEqual(msg.o, .oneofFixed64(58))
    msg.o = nil
    XCTAssertEqual(msg.oneofFixed64, 107)
    XCTAssertNil(msg.o)
    msg.oneofFixed64 = 107
    XCTAssertEqual(msg.oneofFixed64, 107)
    XCTAssertEqual(msg.o, .oneofFixed64(107))
  }

  func testOneofSfixed32() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofSfixed32, 108)
    XCTAssertNil(msg.o)
    msg.oneofSfixed32 = 59
    XCTAssertEqual(msg.oneofSfixed32, 59)
    XCTAssertEqual(msg.o, .oneofSfixed32(59))
    msg.o = nil
    XCTAssertEqual(msg.oneofSfixed32, 108)
    XCTAssertNil(msg.o)
    msg.oneofSfixed32 = 108
    XCTAssertEqual(msg.oneofSfixed32, 108)
    XCTAssertEqual(msg.o, .oneofSfixed32(108))
  }

  func testOneofSfixed64() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofSfixed64, 109)
    XCTAssertNil(msg.o)
    msg.oneofSfixed64 = 60
    XCTAssertEqual(msg.oneofSfixed64, 60)
    XCTAssertEqual(msg.o, .oneofSfixed64(60))
    msg.o = nil
    XCTAssertEqual(msg.oneofSfixed64, 109)
    XCTAssertNil(msg.o)
    msg.oneofSfixed64 = 109
    XCTAssertEqual(msg.oneofSfixed64, 109)
    XCTAssertEqual(msg.o, .oneofSfixed64(109))
  }

  func testOneofFloat() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofFloat, 110.0)
    XCTAssertNil(msg.o)
    msg.oneofFloat = 61.0
    XCTAssertEqual(msg.oneofFloat, 61.0)
    XCTAssertEqual(msg.o, .oneofFloat(61.0))
    msg.o = nil
    XCTAssertEqual(msg.oneofFloat, 110.0)
    XCTAssertNil(msg.o)
    msg.oneofFloat = 110.0
    XCTAssertEqual(msg.oneofFloat, 110.0)
    XCTAssertEqual(msg.o, .oneofFloat(110.0))
  }

  func testOneofDouble() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofDouble, 111.0)
    XCTAssertNil(msg.o)
    msg.oneofDouble = 62.0
    XCTAssertEqual(msg.oneofDouble, 62.0)
    XCTAssertEqual(msg.o, .oneofDouble(62.0))
    msg.o = nil
    XCTAssertEqual(msg.oneofDouble, 111.0)
    XCTAssertNil(msg.o)
    msg.oneofDouble = 111.0
    XCTAssertEqual(msg.oneofDouble, 111.0)
    XCTAssertEqual(msg.o, .oneofDouble(111.0))
  }

  func testOneofBool() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofBool, true)
    XCTAssertNil(msg.o)
    msg.oneofBool = false
    XCTAssertEqual(msg.oneofBool, false)
    XCTAssertEqual(msg.o, .oneofBool(false))
    msg.o = nil
    XCTAssertEqual(msg.oneofBool, true)
    XCTAssertNil(msg.o)
    msg.oneofBool = true
    XCTAssertEqual(msg.oneofBool, true)
    XCTAssertEqual(msg.o, .oneofBool(true))
  }

  func testOneofString() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofString, "string")
    XCTAssertNil(msg.o)
    msg.oneofString = "64"
    XCTAssertEqual(msg.oneofString, "64")
    XCTAssertEqual(msg.o, .oneofString("64"))
    msg.o = nil
    XCTAssertEqual(msg.oneofString, "string")
    XCTAssertNil(msg.o)
    msg.oneofString = "string"
    XCTAssertEqual(msg.oneofString, "string")
    XCTAssertEqual(msg.o, .oneofString("string"))
  }

  func testOneofBytes() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofBytes, "data".data(using: .utf8))
    XCTAssertNil(msg.o)
    msg.oneofBytes = Data([65])
    XCTAssertEqual(msg.oneofBytes, Data([65]))
    XCTAssertEqual(msg.o, .oneofBytes(Data([65])))
    msg.o = nil
    XCTAssertEqual(msg.oneofBytes, "data".data(using: .utf8))
    XCTAssertNil(msg.o)
    msg.oneofBytes = "data".data(using: .utf8)!
    XCTAssertEqual(msg.oneofBytes, "data".data(using: .utf8))
    XCTAssertEqual(msg.o, .oneofBytes("data".data(using: .utf8)!))
  }

  func testOneofGroup() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofGroup.a, 116)
    XCTAssertFalse(msg.oneofGroup.hasA)
    XCTAssertNil(msg.o)
    var grp = ProtobufUnittest_Message2.OneofGroup()
    grp.a = 66
    msg.oneofGroup = grp
    XCTAssertEqual(msg.oneofGroup.a, 66)
    XCTAssertTrue(msg.oneofGroup.hasA)
    XCTAssertEqual(msg.oneofGroup, grp)
    if case .oneofGroup(let v)? = msg.o {
      XCTAssertTrue(v.hasA)
      XCTAssertEqual(v.a, 66)
      XCTAssertEqual(v, grp)
    } else {
      XCTFail("Wasn't the right case")
    }
    msg.o = nil
    XCTAssertEqual(msg.oneofGroup.a, 116)
    XCTAssertFalse(msg.oneofGroup.hasA)
    XCTAssertNil(msg.o)
    // Default within the group
    var grp2 = ProtobufUnittest_Message2.OneofGroup()
    grp2.a = 116
    msg.oneofGroup = grp2
    XCTAssertEqual(msg.oneofGroup.a, 116)
    XCTAssertTrue(msg.oneofGroup.hasA)
    XCTAssertEqual(msg.oneofGroup, grp2)
    if case .oneofGroup(let v)? = msg.o {
      XCTAssertTrue(v.hasA)
      XCTAssertEqual(v.a, 116)
      XCTAssertEqual(v, grp2)
    } else {
      XCTFail("Wasn't the right case")
    }
    msg.o = nil
    // Group with nothing set.
    let grp3 = ProtobufUnittest_Message2.OneofGroup()
    msg.oneofGroup = grp3
    XCTAssertEqual(msg.oneofGroup.a, 116)
    XCTAssertFalse(msg.oneofGroup.hasA)
    XCTAssertEqual(msg.oneofGroup, grp3)
    if case .oneofGroup(let v)? = msg.o {
      XCTAssertFalse(v.hasA)
      XCTAssertEqual(v.a, 116)
      XCTAssertEqual(v, grp3)
    } else {
      XCTFail("Wasn't the right case")
    }
  }

  func testOneofMessage() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofMessage.optionalInt32, 0)
    XCTAssertNil(msg.o)
    var subMsg = ProtobufUnittest_Message2()
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
    var subMsg2 = ProtobufUnittest_Message2()
    subMsg2.optionalInt32 = 0
    msg.oneofMessage = subMsg2
    XCTAssertEqual(msg.oneofMessage.optionalInt32, 0)
    XCTAssertTrue(msg.oneofMessage.hasOptionalInt32)
    XCTAssertEqual(msg.oneofMessage, subMsg2)
    if case .oneofMessage(let v)? = msg.o {
      XCTAssertTrue(v.hasOptionalInt32)
      XCTAssertEqual(v.optionalInt32, 0)
      XCTAssertEqual(v, subMsg2)
    } else {
      XCTFail("Wasn't the right case")
    }
    msg.o = nil
    // Message with nothing set.
    let subMsg3 = ProtobufUnittest_Message2()
    msg.oneofMessage = subMsg3
    XCTAssertEqual(msg.oneofMessage.optionalInt32, 0)
    XCTAssertFalse(msg.oneofMessage.hasOptionalInt32)
    XCTAssertEqual(msg.oneofMessage, subMsg3)
    if case .oneofMessage(let v)? = msg.o {
      XCTAssertFalse(v.hasOptionalInt32)
      XCTAssertEqual(v.optionalInt32, 0)
      XCTAssertEqual(v, subMsg3)
    } else {
      XCTFail("Wasn't the right case")
    }
  }

  func testOneofEnum() {
    var msg = ProtobufUnittest_Message2()
    XCTAssertEqual(msg.oneofEnum, .baz)
    XCTAssertNil(msg.o)
    msg.oneofEnum = .bar
    XCTAssertEqual(msg.oneofEnum, .bar)
    XCTAssertEqual(msg.o, .oneofEnum(.bar))
    msg.o = nil
    XCTAssertEqual(msg.oneofEnum, .baz)
    XCTAssertNil(msg.o)
    msg.oneofEnum = .baz
    XCTAssertEqual(msg.oneofEnum, .baz)
    XCTAssertEqual(msg.o, .oneofEnum(.baz))
  }

  // Chaining. Set each item in the oneof clear the previous one.

  func testOneofOnlyOneSet() {
    var msg = ProtobufUnittest_Message2()

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
        XCTAssertEqual(v, false)
      case .oneofString(let v)?:
        XCTAssertEqual(i, 14)
        XCTAssertEqual(v, "64")
      case .oneofBytes(let v)?:
        XCTAssertEqual(i, 15)
        XCTAssertEqual(v, Data([65]))
      case .oneofGroup(let v)?:
        XCTAssertEqual(i, 16)
        XCTAssertTrue(v.hasA)
        XCTAssertEqual(v.a, 66)
      case .oneofMessage(let v)?:
        XCTAssertEqual(i, 17)
        XCTAssertTrue(v.hasOptionalInt32)
        XCTAssertEqual(v.optionalInt32, 68)
      case .oneofEnum(let v)?:
        XCTAssertEqual(i, 18)
        XCTAssertEqual(v, .bar)
      }

      // Check direct field access (gets the right value or the default)
      if i == 1 {
        XCTAssertEqual(msg.oneofInt32, 51)
      } else {
        XCTAssertEqual(msg.oneofInt32, 100, "i = \(i)")
      }
      if i == 2 {
        XCTAssertEqual(msg.oneofInt64, 52)
      } else {
        XCTAssertEqual(msg.oneofInt64, 101, "i = \(i)")
      }
      if i == 3 {
        XCTAssertEqual(msg.oneofUint32, 53)
      } else {
        XCTAssertEqual(msg.oneofUint32, 102, "i = \(i)")
      }
      if i == 4 {
        XCTAssertEqual(msg.oneofUint64, 54)
      } else {
        XCTAssertEqual(msg.oneofUint64, 103, "i = \(i)")
      }
      if i == 5 {
        XCTAssertEqual(msg.oneofSint32, 55)
      } else {
        XCTAssertEqual(msg.oneofSint32, 104, "i = \(i)")
      }
      if i == 6 {
        XCTAssertEqual(msg.oneofSint64, 56)
      } else {
        XCTAssertEqual(msg.oneofSint64, 105, "i = \(i)")
      }
      if i == 7 {
        XCTAssertEqual(msg.oneofFixed32, 57)
      } else {
        XCTAssertEqual(msg.oneofFixed32, 106, "i = \(i)")
      }
      if i == 8 {
        XCTAssertEqual(msg.oneofFixed64, 58)
      } else {
        XCTAssertEqual(msg.oneofFixed64, 107, "i = \(i)")
      }
      if i == 9 {
        XCTAssertEqual(msg.oneofSfixed32, 59)
      } else {
        XCTAssertEqual(msg.oneofSfixed32, 108, "i = \(i)")
      }
      if i == 10 {
        XCTAssertEqual(msg.oneofSfixed64, 60)
      } else {
        XCTAssertEqual(msg.oneofSfixed64, 109, "i = \(i)")
      }
      if i == 11 {
        XCTAssertEqual(msg.oneofFloat, 61.0)
      } else {
        XCTAssertEqual(msg.oneofFloat, 110.0, "i = \(i)")
      }
      if i == 12 {
        XCTAssertEqual(msg.oneofDouble, 62.0)
      } else {
        XCTAssertEqual(msg.oneofDouble, 111.0, "i = \(i)")
      }
      if i == 13 {
        XCTAssertEqual(msg.oneofBool, false)
      } else {
        XCTAssertEqual(msg.oneofBool, true, "i = \(i)")
      }
      if i == 14 {
        XCTAssertEqual(msg.oneofString, "64")
      } else {
        XCTAssertEqual(msg.oneofString, "string", "i = \(i)")
      }
      if i == 15 {
        XCTAssertEqual(msg.oneofBytes, Data([65]))
      } else {
        XCTAssertEqual(msg.oneofBytes, "data".data(using: .utf8), "i = \(i)")
      }
      if i == 16 {
        XCTAssertTrue(msg.oneofGroup.hasA)
        XCTAssertEqual(msg.oneofGroup.a, 66)
      } else {
        XCTAssertFalse(msg.oneofGroup.hasA, "i = \(i)")
        XCTAssertEqual(msg.oneofGroup.a, 116, "i = \(i)")
      }
      if i == 17 {
        XCTAssertTrue(msg.oneofMessage.hasOptionalInt32)
        XCTAssertEqual(msg.oneofMessage.optionalInt32, 68)
      } else {
        XCTAssertFalse(msg.oneofMessage.hasOptionalInt32, "i = \(i)")
        XCTAssertEqual(msg.oneofMessage.optionalInt32, 0, "i = \(i)")
      }
      if i == 18 {
        XCTAssertEqual(msg.oneofEnum, .bar)
      } else {
        XCTAssertEqual(msg.oneofEnum, .baz, "i = \(i)")
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
    msg.oneofFloat = 61.0
    assertRightFiledSet(11)
    msg.oneofDouble = 62.0
    assertRightFiledSet(12)
    msg.oneofBool = false
    assertRightFiledSet(13)
    msg.oneofString = "64"
    assertRightFiledSet(14)
    msg.oneofBytes = Data([65])
    assertRightFiledSet(15)
    msg.oneofGroup.a = 66
    assertRightFiledSet(16)
    msg.oneofMessage.optionalInt32 = 68
    assertRightFiledSet(17)
    msg.oneofEnum = .bar
    assertRightFiledSet(18)
  }
}
