// Tests/SwiftProtobufTests/Test_SimpleExtensionMap.swift - Test SimpleExtensionMap behaviors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test SimpleExtensionMap.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
@testable import SwiftProtobuf

extension AnyMessageExtension {
  // Support equality to simplify testing of getting the correct errors.
  func isEqual(_ other: AnyMessageExtension) -> Bool {
    return (fieldNumber == other.fieldNumber &&
      fieldName == other.fieldName &&
      messageType == other.messageType)
  }
}

// Define some extension to use for testing behaviors.

let ext1 = MessageExtension<OptionalExtensionField<ProtobufInt32>, ProtobufUnittest_TestAllExtensions>(
  _protobuf_fieldNumber: 1,
  fieldName: "my_ext1"
)

let ext2 = MessageExtension<OptionalExtensionField<ProtobufInt64>, ProtobufUnittest_TestAllExtensions>(
  _protobuf_fieldNumber: 2,
  fieldName: "my_ext2"
)

// Same field number as ext1, but different class being extended.
let ext3 = MessageExtension<OptionalExtensionField<ProtobufDouble>, ProtobufUnittest_TestPackedExtensions>(
  _protobuf_fieldNumber: 1,
  fieldName: "my_ext1b"
)

// Same field number and message type as ext2, so it will replace it in the mapping.
let ext4 = MessageExtension<OptionalExtensionField<ProtobufBool>, ProtobufUnittest_TestAllExtensions>(
  _protobuf_fieldNumber: 2,
  fieldName: "my_ext4"
)


class Test_SimpleExtensionMap: XCTestCase {
  func assert(map: SimpleExtensionMap, contains: [AnyMessageExtension], line: UInt = #line) {
    // Extact what it constaings.
    var includes = [AnyMessageExtension]()
    for (_, l) in map.fields {
      for e in l {
        includes.append(e)
      }
    }

    // Check that everything the lists match no matter the orders.
    for c in contains {
      var found = false
      for i in includes {
        if (c.isEqual(i)) {
          found = true
          break
        }
      }
      XCTAssertTrue(found, "Map didn't include \(c)", line: line)
    }
    for i in includes {
      var found = false
      for c in contains {
        if (i.isEqual(c)) {
          found = true
          break
        }
      }
      XCTAssertTrue(found, "Map wasn't supposed to include \(i)", line: line)
    }
  }

  func testInsert() {
    var map = SimpleExtensionMap()
    XCTAssertEqual(map.fields.count, 0)

    map.insert(ext1)
    assert(map: map, contains: [ext1])

    map.insert(ext2)
    assert(map: map, contains: [ext2, ext1])

    map.insert(ext3)
    assert(map: map, contains: [ext3, ext2, ext1])

    // ext4 has the same message and number as ext2, so should replace it.
    map.insert(ext4)
    assert(map: map, contains: [ext4, ext1, ext3])
  }

  func testInsert_contentsOf() {
    var map = SimpleExtensionMap()
    XCTAssertEqual(map.fields.count, 0)

    map.insert(contentsOf: [ext1, ext2])
    assert(map: map, contains: [ext1, ext2])

    // ext4 has the same message and number as ext2, so should replace it.
    map.insert(contentsOf: [ext3, ext4])
    assert(map: map, contains: [ext1, ext4, ext3])
  }

  func testInitialize_list() {
    let map1: SimpleExtensionMap = [ext1, ext2]
    assert(map: map1, contains: [ext1, ext2])

    let map2: SimpleExtensionMap = [ext1, ext2, ext3, ext4]
    assert(map: map2, contains: [ext1, ext3, ext4])
}

  func testFormUnion() {
    var map1: SimpleExtensionMap = [ext1]
    let map2: SimpleExtensionMap = [ext2]
    let map3: SimpleExtensionMap = [ext3, ext4]

    map1.formUnion(map2)
    assert(map: map1, contains: [ext1, ext2])

    // ext4 has the same message and number as ext2, so should replace it.
    map1.formUnion(map3)
    assert(map: map1, contains: [ext1, ext3, ext4])
  }

  func testUnion() {
    let map1: SimpleExtensionMap = [ext1]
    let map2: SimpleExtensionMap = [ext2]
    let map3: SimpleExtensionMap = [ext3, ext4]

    let map4 = map1.union(map2)
    assert(map: map4, contains: [ext1, ext2])

    // ext4 has the same message and number as ext2, so should replace it.
    let map5 = map4.union(map3)
    assert(map: map5, contains: [ext1, ext3, ext4])
  }
  
  func testInitialize_union() {
    let map1: SimpleExtensionMap = [ext1]
    let map2: SimpleExtensionMap = [ext2]
    let map3: SimpleExtensionMap = [ext3, ext4]

    let map4 = SimpleExtensionMap(map1, map2)
    assert(map: map4, contains: [ext1, ext2])

    // ext4 has the same message and number as ext2, so should replace it.
    let map5 = SimpleExtensionMap(map1, map2, map3)
    assert(map: map5, contains: [ext1, ext3, ext4])
  }

  func testSubscript() {
    let map1: SimpleExtensionMap = [ext1, ext2]

    let lookup1 = map1[ext1.messageType, ext1.fieldNumber]
    XCTAssertTrue(lookup1!.isEqual(ext1))

    let lookup2 = map1[ext2.messageType, ext2.fieldNumber]
    XCTAssertTrue(lookup2!.isEqual(ext2))

    let lookup3 = map1[ProtobufUnittest_TestAllTypes.self, ext1.fieldNumber]
    XCTAssertNil(lookup3)

    let lookup4 = map1[ext1.messageType, 999]
    XCTAssertNil(lookup4)

    // ext4 will replace ext2
    let map2: SimpleExtensionMap = [ext1, ext2, ext4]

    let lookup1b = map2[ext1.messageType, ext1.fieldNumber]
    XCTAssertTrue(lookup1b!.isEqual(ext1))

    let lookup2b = map2[ext2.messageType, ext2.fieldNumber]
    XCTAssertTrue(lookup2b!.isEqual(ext4))
    XCTAssertTrue(!lookup2b!.isEqual(ext2))
  }

  func testFieldNumberForProto() {
    let map1: SimpleExtensionMap = [ext1, ext2]

    let lookup1 = map1.fieldNumberForProto(messageType: ext1.messageType,
                                           protoFieldName: ext1.fieldName)
    XCTAssertEqual(lookup1, ext1.fieldNumber)

    let lookup2 = map1.fieldNumberForProto(messageType: ext2.messageType,
                                           protoFieldName: ext2.fieldName)
    XCTAssertEqual(lookup2, ext2.fieldNumber)

    let lookup3 = map1.fieldNumberForProto(messageType: ext1.messageType,
                                           protoFieldName: "foo_bar_baz")
    XCTAssertNil(lookup3)

    let lookup4 = map1.fieldNumberForProto(messageType: ProtobufUnittest_TestAllTypes.self,
                                           protoFieldName: ext1.fieldName)
    XCTAssertNil(lookup4)

    // ext4 will replace ext2
    let map2: SimpleExtensionMap = [ext1, ext2, ext4]

    let lookup1b = map2.fieldNumberForProto(messageType: ext1.messageType,
                                            protoFieldName: ext1.fieldName)
    XCTAssertEqual(lookup1b, ext1.fieldNumber)

    let lookup2b = map2.fieldNumberForProto(messageType: ext2.messageType,
                                            protoFieldName: ext2.fieldName)
    XCTAssertNil(lookup2b)

    let lookup3b = map2.fieldNumberForProto(messageType: ext4.messageType,
                                            protoFieldName: ext4.fieldName)
    XCTAssertEqual(lookup3b, ext4.fieldNumber)
  }

}
