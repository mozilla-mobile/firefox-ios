// Sources/SwiftProtobuf/CustomJSONCodable.swift - Custom JSON support for WKTs
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Custom protocol for the WKTs to support their custom JSON encodings.
///
// -----------------------------------------------------------------------------

/// Allows WKTs to provide their custom JSON encodings.
internal protocol _CustomJSONCodable {
  func encodedJSONString(options: JSONEncodingOptions) throws -> String
  mutating func decodeJSON(from: inout JSONDecoder) throws

  /// Called when the JSON `null` literal is encountered in a position where
  /// a message of the conforming type is expected. The message type can then
  /// handle the `null` value differently, if needed; for example,
  /// `Google_Protobuf_Value` returns a special instance whose `kind` is set to
  /// `.nullValue(.nullValue)`.
  ///
  /// The default behavior is to return `nil`, which indicates that `null`
  /// should be treated as the absence of a message.
  static func decodedFromJSONNull() throws -> Self?
}

extension _CustomJSONCodable {
  internal static func decodedFromJSONNull() -> Self? {
    // Return nil by default. Concrete types can provide custom logic.
    return nil
  }
}
