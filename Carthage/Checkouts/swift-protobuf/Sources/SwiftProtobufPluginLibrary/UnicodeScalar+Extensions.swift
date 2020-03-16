// Sources/SwiftProtobufPluginLibrary/UnicodeScalar+Extensions.swift - Utilities for working with UnicodeScalars
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Internal utility functions and properties for working with UnicodeScalars.
///
/// NOTE: This is a purely internal extension that provides the limited
/// functionality needed to manipulate ASCII characters that are represented as
/// UnicodeScalars. It does not support the full range of Unicode code points.
///
// -----------------------------------------------------------------------------

extension UnicodeScalar {

  /// True if the receiver is a numeric digit.
  ///
  /// - Precondition: The receiver is 7-bit ASCII.
  var isDigit: Bool {
    precondition(value < 0x80, "Scalar must be 7-bit ASCII")
    if case "0"..."9" = self { return true }
    return false
  }

  /// True if the receiver is a lowercase character.
  ///
  /// - Precondition: The receiver is 7-bit ASCII.
  var isLowercase: Bool {
    precondition(value < 0x80, "Scalar must be 7-bit ASCII")
    if case "a"..."z" = self { return true }
    return false
  }

  /// True if the receiver is an uppercase character.
  ///
  /// - Precondition: The receiver is 7-bit ASCII.
  var isUppercase: Bool {
    precondition(value < 0x80, "Scalar must be 7-bit ASCII")
    if case "A"..."Z" = self { return true }
    return false
  }

  /// Returns the lowercased version of the receiver, or the receiver itself if
  /// it is not a cased character.
  ///
  /// - Precondition: The receiver is 7-bit ASCII.
  /// - Returns: The lowercased version of the receiver, or `self`.
  func lowercased() -> UnicodeScalar {
    if isUppercase { return UnicodeScalar(value + 0x20)! }
    return self
  }

  /// Returns the uppercased version of the receiver, or the receiver itself if
  /// it is not a cased character.
  ///
  /// - Precondition: The receiver is 7-bit ASCII.
  /// - Returns: The uppercased version of the receiver, or `self`.
  func uppercased() -> UnicodeScalar {
    if isLowercase { return UnicodeScalar(value - 0x20)! }
    return self
  }
}
