// Tests/SwiftProtobufTests/Test_BinaryDelimited.swift - Delimited message tests
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_BinaryDelimited: XCTestCase {

  func testEverything() {
    // Don't need to test encode/decode since there are plenty of tests specific to that,
    // just test the delimited behaviors.

    let stream1 = OutputStream.toMemory()
    stream1.open()

    let msg1 = ProtobufUnittest_TestAllTypes.with {
      $0.optionalBool = true
      $0.optionalInt32 = 123
      $0.optionalInt64 = 123456789
      $0.optionalGroup.a = 456
      $0.optionalNestedEnum = .baz
      $0.repeatedString.append("wee")
      $0.repeatedFloat.append(1.23)
    }

    XCTAssertNoThrow(try BinaryDelimited.serialize(message: msg1, to: stream1))

    let msg2 = ProtobufUnittest_TestPackedTypes.with {
      $0.packedBool.append(true)
      $0.packedInt32.append(234)
      $0.packedDouble.append(345.67)
    }

    XCTAssertNoThrow(try BinaryDelimited.serialize(message: msg2, to: stream1))

    stream1.close()
    // See https://bugs.swift.org/browse/SR-5404
    let nsData = stream1.property(forKey: .dataWrittenToMemoryStreamKey) as! NSData
    let data = Data(referencing: nsData)
    let stream2 = InputStream(data: data)
    stream2.open()

    var msg1a = ProtobufUnittest_TestAllTypes()
    XCTAssertNoThrow(try BinaryDelimited.merge(into: &msg1a, from: stream2))
    XCTAssertEqual(msg1, msg1a)

    do {
      let msg2a = try BinaryDelimited.parse(
        messageType: ProtobufUnittest_TestPackedTypes.self,
        from: stream2)
      XCTAssertEqual(msg2, msg2a)
    } catch let e {
      XCTFail("Unexpected failure: \(e)")
    }

    do {
      _ = try BinaryDelimited.parse(messageType: ProtobufUnittest_TestAllTypes.self, from: stream2)
      XCTFail("Should not have gotten here")
    } catch BinaryDelimited.Error.truncated {
      // Nothing, this is what we expect since there is nothing left to read.
    } catch let e {
      XCTFail("Unexpected failure: \(e)")
    }
  }

}
