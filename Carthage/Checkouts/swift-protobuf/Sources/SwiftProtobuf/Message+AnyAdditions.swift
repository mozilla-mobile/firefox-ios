// Sources/SwiftProtobuf/Message+AnyAdditions.swift - Any-related Message extensions
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extends the `Message` type with `Google_Protobuf_Any`-specific behavior.
///
// -----------------------------------------------------------------------------

extension Message {
  /// Initialize this message from the provided `google.protobuf.Any`
  /// well-known type.
  ///
  /// This corresponds to the `unpack` method in the Google C++ API.
  ///
  /// If the Any object was decoded from Protobuf Binary or JSON
  /// format, then the enclosed field data was stored and is not
  /// fully decoded until you unpack the Any object into a message.
  /// As such, this method will typically need to perform a full
  /// deserialization of the enclosed data and can fail for any
  /// reason that deserialization can fail.
  ///
  /// See `Google_Protobuf_Any.unpackTo()` for more discussion.
  ///
  /// - Parameter unpackingAny: the message to decode.
  /// - Parameter extensions: An `ExtensionMap` used to look up and decode any
  ///   extensions in this message or messages nested within this message's
  ///   fields.
  /// - Parameter options: The BinaryDecodingOptions to use.
  /// - Throws: an instance of `AnyUnpackError`, `JSONDecodingError`, or
  ///   `BinaryDecodingError` on failure.
  public init(
    unpackingAny: Google_Protobuf_Any,
    extensions: ExtensionMap? = nil,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
    self.init()
    try unpackingAny._storage.unpackTo(target: &self, extensions: extensions, options: options)
  }
}
