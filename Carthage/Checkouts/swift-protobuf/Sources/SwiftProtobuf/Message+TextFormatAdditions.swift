// Sources/SwiftProtobuf/Message+TextFormatAdditions.swift - Text format primitive types
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Message` to support text format encoding/decoding.
///
// -----------------------------------------------------------------------------

import Foundation

/// Text format encoding and decoding methods for messages.
extension Message {
  /// Returns a string containing the Protocol Buffer text format serialization
  /// of the message.
  ///
  /// Unlike binary encoding, presence of required fields is not enforced when
  /// serializing to text format.
  ///
  /// - Returns: A string containing the text format serialization of the
  ///   message.
  public func textFormatString() -> String {
    // This is implemented as a separate zero-argument function
    // to preserve binary compatibility.
    return textFormatString(options: TextFormatEncodingOptions())
  }

  /// Returns a string containing the Protocol Buffer text format serialization
  /// of the message.
  ///
  /// Unlike binary encoding, presence of required fields is not enforced when
  /// serializing to JSON.
  ///
  /// - Returns: A string containing the text format serialization of the message.
  /// - Parameters:
  ///   - options: The TextFormatEncodingOptions to use.
  public func textFormatString(
    options: TextFormatEncodingOptions
  ) -> String {
    var visitor = TextFormatEncodingVisitor(message: self, options: options)
    if let any = self as? Google_Protobuf_Any {
      any._storage.textTraverse(visitor: &visitor)
    } else {
      // Although the general traversal/encoding infrastructure supports
      // throwing errors (needed for JSON/Binary WKTs support, binary format
      // missing required fields); TextEncoding never actually does throw.
      try! traverse(visitor: &visitor)
    }
    return visitor.result
  }

  /// Creates a new message by decoding the given string containing a
  /// serialized message in Protocol Buffer text format.
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
            var decoder = try TextFormatDecoder(messageType: Self.self,
                                                utf8Pointer: baseAddress,
                                                count: body.count,
                                                extensions: extensions)
            try decodeMessage(decoder: &decoder)
            if !decoder.complete {
              throw TextFormatDecodingError.trailingGarbage
            }
          }
        }
      }
    }
  }
}
