// Tests/SwiftProtobufTests/Test_Empty.swift - Verify well-known empty message
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Since Empty is purely compiled (there is no hand-coding
/// in it) this is a fairly thin test just to ensure that the proto
/// does get into the runtime.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_Empty: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Google_Protobuf_Empty

    func testExists() throws {
        let e = Google_Protobuf_Empty()
        XCTAssertEqual(Data(), try e.serializedData())
    }
}
