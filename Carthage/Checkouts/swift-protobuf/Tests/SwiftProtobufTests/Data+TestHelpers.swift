// Tests/SwiftProtobufTests/TestHelpers.swift - Test helpers
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation
@testable import SwiftProtobuf

/// Helpers for building up wire encoding in tests.
extension Data {
    mutating func appendStartField(fieldNumber: Int, wireFormat: WireFormat) {
        appendStartField(tag: FieldTag(fieldNumber: fieldNumber, wireFormat: wireFormat))
    }

    mutating func appendStartField(tag: FieldTag) {
        appendVarInt(value: UInt64(tag.rawValue))
    }

    mutating func appendVarInt(value: UInt64) {
        var v = value
        while v > 127 {
            append(UInt8(v & 0x7f | 0x80))
            v >>= 7
        }
        append(UInt8(v))
    }

    mutating func appendVarInt(value: Int64) {
        appendVarInt(value: UInt64(bitPattern: value))
    }

    mutating func appendVarInt(value: Int) {
        appendVarInt(value: Int64(value))
    }

    mutating func appendVarInt(value: Int32) {
        appendVarInt(value: Int64(value))
    }

}

