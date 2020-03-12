// Sources/SwiftProtobuf/StringUtils.swift - String utility functions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Utility functions for converting UTF8 bytes into Strings.
/// These functions must:
///  * Accept any valid UTF8, including a zero byte (which is
///    a valid UTF8 encoding of U+0000)
///  * Return nil for any invalid UTF8
///  * Be fast (since they're extensively used by all decoders
///    and even some of the encoders)
///
// -----------------------------------------------------------------------------

import Foundation

// Wrapper that takes a buffer and start/end offsets
internal func utf8ToString(
  bytes: UnsafeRawBufferPointer,
  start: UnsafeRawBufferPointer.Index,
  end: UnsafeRawBufferPointer.Index
) -> String? {
  return utf8ToString(bytes: bytes.baseAddress! + start, count: end - start)
}


// Swift 4 introduced new faster String facilities
// that seem to work consistently across all platforms.

// Notes on performance:
//
// The pre-verification here only takes about 10% of
// the time needed for constructing the string.
// Eliminating it would provide only a very minor
// speed improvement.
//
// On macOS, this is only about 25% faster than
// the Foundation initializer used below for Swift 3.
// On Linux, the Foundation initializer is much
// slower than on macOS, so this is a much bigger
// win there.
internal func utf8ToString(bytes: UnsafeRawPointer, count: Int) -> String? {
  if count == 0 {
    return String()
  }
  let codeUnits = UnsafeRawBufferPointer(start: bytes, count: count)
  let sourceEncoding = Unicode.UTF8.self

  // Verify that the UTF-8 is valid.
  var p = sourceEncoding.ForwardParser()
  var i = codeUnits.makeIterator()
  Loop:
  while true {
    switch p.parseScalar(from: &i) {
    case .valid(_):
      break
    case .error:
      return nil
    case .emptyInput:
      break Loop
    }
  }

  // This initializer is fast but does not reject broken
  // UTF-8 (which is why we validate the UTF-8 above).
  return String(decoding: codeUnits, as: sourceEncoding)
 }
