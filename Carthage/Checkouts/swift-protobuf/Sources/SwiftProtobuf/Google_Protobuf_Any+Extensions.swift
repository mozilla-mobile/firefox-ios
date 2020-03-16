// Sources/SwiftProtobuf/Google_Protobuf_Any+Extensions.swift - Well-known Any type
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extends the `Google_Protobuf_Any` type with various custom behaviors.
///
// -----------------------------------------------------------------------------

// Explicit import of Foundation is necessary on Linux,
// don't remove unless obsolete on all platforms
import Foundation

public let defaultAnyTypeURLPrefix: String = "type.googleapis.com"

extension Google_Protobuf_Any {
  /// Initialize an Any object from the provided message.
  ///
  /// This corresponds to the `pack` operation in the C++ API.
  ///
  /// Unlike the C++ implementation, the message is not immediately
  /// serialized; it is merely stored until the Any object itself
  /// needs to be serialized.  This design avoids unnecessary
  /// decoding/recoding when writing JSON format.
  ///
  /// - Parameters:
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  ///   - typePrefix: The prefix to be used when building the `type_url`. 
  ///     Defaults to "type.googleapis.com".
  /// - Throws: `BinaryEncodingError.missingRequiredFields` if `partial` is
  ///     false and `message` wasn't fully initialized.
  public init(
    message: Message,
    partial: Bool = false,
    typePrefix: String = defaultAnyTypeURLPrefix
  ) throws {
    if !partial && !message.isInitialized {
      throw BinaryEncodingError.missingRequiredFields
    }
    self.init()
    typeURL = buildTypeURL(forMessage:message, typePrefix: typePrefix)
    _storage.state = .message(message)
  }

  /// Creates a new `Google_Protobuf_Any` by decoding the given string
  /// containing a serialized message in Protocol Buffer text format.
  ///
  /// - Parameters:
  ///   - textFormatString: The text format string to decode.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  /// - Throws: an instance of `TextFormatDecodingError` on failure.
  public init(
    textFormatString: String,
    extensions: ExtensionMap? = nil
  ) throws {
    self.init()
    if !textFormatString.isEmpty {
      if let data = textFormatString.data(using: String.Encoding.utf8) {
        try data.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
          if let baseAddress = body.baseAddress, body.count > 0 {
            var textDecoder = try TextFormatDecoder(
              messageType: Google_Protobuf_Any.self,
              utf8Pointer: baseAddress,
              count: body.count,
              extensions: extensions)
            try decodeTextFormat(decoder: &textDecoder)
            if !textDecoder.complete {
              throw TextFormatDecodingError.trailingGarbage
            }
          }
        }
      }
    }
  }

  /// Returns true if this `Google_Protobuf_Any` message contains the given
  /// message type.
  ///
  /// The check is performed by looking at the passed `Message.Type` and the
  /// `typeURL` of this message.
  ///
  /// - Parameter type: The concrete message type.
  /// - Returns: True if the receiver contains the given message type.
  public func isA<M: Message>(_ type: M.Type) -> Bool {
    return _storage.isA(type)
  }

#if swift(>=4.2)
  public func hash(into hasher: inout Hasher) {
    _storage.hash(into: &hasher)
  }
#else  // swift(>=4.2)
  public var hashValue: Int {
    return _storage.hashValue
  }
#endif  // swift(>=4.2)
}

extension Google_Protobuf_Any {
  internal func textTraverse(visitor: inout TextFormatEncodingVisitor) {
    _storage.textTraverse(visitor: &visitor)
    try! unknownFields.traverse(visitor: &visitor)
  }
}

extension Google_Protobuf_Any: _CustomJSONCodable {
  // Custom text format decoding support for Any objects.
  // (Note: This is not a part of any protocol; it's invoked
  // directly from TextFormatDecoder whenever it sees an attempt
  // to decode an Any object)
  internal mutating func decodeTextFormat(
    decoder: inout TextFormatDecoder
  ) throws {
    // First, check if this uses the "verbose" Any encoding.
    // If it does, and we have the type available, we can
    // eagerly decode the contained Message object.
    if let url = try decoder.scanner.nextOptionalAnyURL() {
      try _uniqueStorage().decodeTextFormat(typeURL: url, decoder: &decoder)
    } else {
      // This is not using the specialized encoding, so we can use the
      // standard path to decode the binary value.
      try decodeMessage(decoder: &decoder)
    }
  }

  internal func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    return try _storage.encodedJSONString(options: options)
  }

  internal mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    try _uniqueStorage().decodeJSON(from: &decoder)
  }
}
