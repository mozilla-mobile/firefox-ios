// Tests/SwiftProtobufTests/Test_GroupWithGroups.swift - Verify groups within groups
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

class Test_GroupWithinGroup: XCTestCase, PBTestHelpers {
  typealias MessageTestType = SwiftTestNestingGroupsMessage

  func testGroupWithGroup_Single() {
    assertEncode([8, 1, 19, 8, 2, 19, 8, 3, 20, 20]) {(o: inout MessageTestType) in
      o.outerA = 1
      o.subGroup1.sub1A = 2
      o.subGroup1.subGroup2.sub2A = 3
    }
    assertDecodeSucceeds([19, 19, 8, 1, 20, 20]) {
      $0.subGroup1.subGroup2.sub2A == 1
    }
    // Empty group
    assertDecodeSucceeds([19, 19, 20, 20]) {
      $0.subGroup1.hasSubGroup2 &&
        $0.subGroup1.subGroup2 == MessageTestType.SubGroup1.SubGroup2()
    }
    assertDecodeFails([8, 1, 19, 8, 2, 19, 8, 3, 20]) // End group missing.
    assertDecodeFails([8, 1, 19, 8, 2, 19, 8, 3, 20, 28]) // Wrong end group.
  }

  func testGroupWithGroup_Repeated() {
    assertEncode([8, 4, 27, 8, 5, 19, 8, 6, 20, 28]) {(o: inout MessageTestType) in
      var grp2 = MessageTestType.SubGroup3.SubGroup4()
      grp2.sub4A = 6

      var grp = MessageTestType.SubGroup3()
      grp.sub3A = 5
      grp.subGroup4.append(grp2)

      o.outerA = 4
      o.subGroup3.append(grp)
    }
    assertDecodeSucceeds([27, 19, 8, 1, 20, 28]) {
      $0.subGroup3.count == 1 &&
        $0.subGroup3[0].subGroup4.count == 1 &&
        $0.subGroup3[0].subGroup4[0].sub4A == 1
    }
    // Empty group
    assertDecodeSucceeds([27, 19, 20, 28]) { (o: MessageTestType) -> Bool in
      o.subGroup3.count == 1 &&
        o.subGroup3[0].subGroup4.count == 1 &&
        o.subGroup3[0].subGroup4[0] == MessageTestType.SubGroup3.SubGroup4()
    }
    assertDecodeFails([8, 4, 27, 8, 5, 19, 8, 6, 20]) // End group missing.
    assertDecodeFails([8, 4, 27, 8, 5, 19, 8, 6, 28, 20]) // Wrong end groups (reversed).
  }
}
