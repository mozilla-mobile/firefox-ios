// Sources/SwiftProtobuf/Varint.swift - Varint encoding/decoding helpers
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Helper functions to varint-encode and decode integers.
///
// -----------------------------------------------------------------------------


/// Contains helper methods to varint-encode and decode integers.
internal enum Varint {

  /// Computes the number of bytes that would be needed to store a 32-bit varint.
  ///
  /// - Parameter value: The number whose varint size should be calculated.
  /// - Returns: The size, in bytes, of the 32-bit varint.
  static func encodedSize(of value: UInt32) -> Int {
    if (value & (~0 << 7)) == 0 {
      return 1
    }
    if (value & (~0 << 14)) == 0 {
      return 2
    }
    if (value & (~0 << 21)) == 0 {
      return 3
    }
    if (value & (~0 << 28)) == 0 {
      return 4
    }
    return 5
  }

  /// Computes the number of bytes that would be needed to store a signed 32-bit varint, if it were
  /// treated as an unsigned integer with the same bit pattern.
  ///
  /// - Parameter value: The number whose varint size should be calculated.
  /// - Returns: The size, in bytes, of the 32-bit varint.
  static func encodedSize(of value: Int32) -> Int {
    if value >= 0 {
      return encodedSize(of: UInt32(bitPattern: value))
    } else {
      // Must sign-extend.
      return encodedSize(of: Int64(value))
    }
  }

  /// Computes the number of bytes that would be needed to store a 64-bit varint.
  ///
  /// - Parameter value: The number whose varint size should be calculated.
  /// - Returns: The size, in bytes, of the 64-bit varint.
  static func encodedSize(of value: Int64) -> Int {
    // Handle two common special cases up front.
    if (value & (~0 << 7)) == 0 {
      return 1
    }
    if value < 0 {
      return 10
    }

    // Divide and conquer the remaining eight cases.
    var value = value
    var n = 2

    if (value & (~0 << 35)) != 0 {
      n += 4
      value >>= 28
    }
    if (value & (~0 << 21)) != 0 {
      n += 2
      value >>= 14
    }
    if (value & (~0 << 14)) != 0 {
      n += 1
    }
    return n
  }

  /// Computes the number of bytes that would be needed to store an unsigned 64-bit varint, if it
  /// were treated as a signed integer witht he same bit pattern.
  ///
  /// - Parameter value: The number whose varint size should be calculated.
  /// - Returns: The size, in bytes, of the 64-bit varint.
  static func encodedSize(of value: UInt64) -> Int {
    return encodedSize(of: Int64(bitPattern: value))
  }

  /// Counts the number of distinct varints in a packed byte buffer.
  static func countVarintsInBuffer(start: UnsafeRawPointer, count: Int) -> Int {
    // We don't need to decode all the varints to count how many there
    // are.  Just observe that every varint has exactly one byte with
    // value < 128. So we just count those...
    var n = 0
    var ints = 0
    while n < count {
      if start.load(fromByteOffset: n, as: UInt8.self) < 128 {
        ints += 1
      }
      n += 1
    }
    return ints
  }
}
