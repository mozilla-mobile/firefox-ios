// Sources/SwiftProtobuf/BinaryDecodingError.swift - Protobuf binary decoding errors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Protobuf binary format decoding errors
///
// -----------------------------------------------------------------------------

/// Describes errors that can occur when decoding a message from binary format.
public enum BinaryDecodingError: Error {
  /// Extraneous data remained after decoding should have been complete.
  case trailingGarbage

  /// The decoder unexpectedly reached the end of the data before it was
  /// expected.
  case truncated

  /// A string field was not encoded as valid UTF-8.
  case invalidUTF8

  /// The binary data was malformed in some way, such as an invalid wire format
  /// or field tag.
  case malformedProtobuf

  /// The definition of the message or one of its nested messages has required
  /// fields but the binary data did not include values for them. You must pass
  /// `partial: true` during decoding if you wish to explicitly ignore missing
  /// required fields.
  case missingRequiredFields

  /// An internal error happened while decoding.  If this is ever encountered,
  /// please file an issue with SwiftProtobuf with as much details as possible
  /// for what happened (proto definitions, bytes being decoded (if possible)).
  case internalExtensionError

  /// Reached the nesting limit for messages within messages while decoding.
  case messageDepthLimit
}
