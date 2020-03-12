// Sources/SwiftProtobuf/Message+JSONAdditions.swift - JSON format primitive types
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Message` to support JSON encoding/decoding.
///
// -----------------------------------------------------------------------------

import Foundation

/// JSON encoding and decoding methods for messages.
extension Message {
  /// Returns a string containing the JSON serialization of the message.
  ///
  /// Unlike binary encoding, presence of required fields is not enforced when
  /// serializing to JSON.
  ///
  /// - Returns: A string containing the JSON serialization of the message.
  /// - Parameters:
  ///   - options: The JSONEncodingOptions to use.
  /// - Throws: `JSONEncodingError` if encoding fails.
  public func jsonString(
    options: JSONEncodingOptions = JSONEncodingOptions()
  ) throws -> String {
    if let m = self as? _CustomJSONCodable {
      return try m.encodedJSONString(options: options)
    }
    let data = try jsonUTF8Data(options: options)
    return String(data: data, encoding: String.Encoding.utf8)!
  }

  /// Returns a Data containing the UTF-8 JSON serialization of the message.
  ///
  /// Unlike binary encoding, presence of required fields is not enforced when
  /// serializing to JSON.
  ///
  /// - Returns: A Data containing the JSON serialization of the message.
  /// - Parameters:
  ///   - options: The JSONEncodingOptions to use.
  /// - Throws: `JSONEncodingError` if encoding fails.
  public func jsonUTF8Data(
    options: JSONEncodingOptions = JSONEncodingOptions()
  ) throws -> Data {
    if let m = self as? _CustomJSONCodable {
      let string = try m.encodedJSONString(options: options)
      let data = string.data(using: String.Encoding.utf8)! // Cannot fail!
      return data
    }
    var visitor = try JSONEncodingVisitor(message: self, options: options)
    visitor.startObject()
    try traverse(visitor: &visitor)
    visitor.endObject()
    return visitor.dataResult
  }

  /// Creates a new message by decoding the given string containing a
  /// serialized message in JSON format.
  ///
  /// - Parameter jsonString: The JSON-formatted string to decode.
  /// - Parameter options: The JSONDecodingOptions to use.
  /// - Throws: `JSONDecodingError` if decoding fails.
  public init(
    jsonString: String,
    options: JSONDecodingOptions = JSONDecodingOptions()
  ) throws {
    if jsonString.isEmpty {
      throw JSONDecodingError.truncated
    }
    if let data = jsonString.data(using: String.Encoding.utf8) {
      try self.init(jsonUTF8Data: data, options: options)
    } else {
      throw JSONDecodingError.truncated
    }
  }

  /// Creates a new message by decoding the given `Data` containing a
  /// serialized message in JSON format, interpreting the data as UTF-8 encoded
  /// text.
  ///
  /// - Parameter jsonUTF8Data: The JSON-formatted data to decode, represented
  ///   as UTF-8 encoded text.
  /// - Parameter options: The JSONDecodingOptions to use.
  /// - Throws: `JSONDecodingError` if decoding fails.
  public init(
    jsonUTF8Data: Data,
    options: JSONDecodingOptions = JSONDecodingOptions()
  ) throws {
    self.init()
    try jsonUTF8Data.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
      // Empty input is valid for binary, but not for JSON.
      guard body.count > 0 else {
        throw JSONDecodingError.truncated
      }
      var decoder = JSONDecoder(source: body, options: options)
      if decoder.scanner.skipOptionalNull() {
        if let customCodable = Self.self as? _CustomJSONCodable.Type,
           let message = try customCodable.decodedFromJSONNull() {
          self = message as! Self
        } else {
          throw JSONDecodingError.illegalNull
        }
      } else {
        try decoder.decodeFullObject(message: &self)
      }
      if !decoder.scanner.complete {
        throw JSONDecodingError.trailingGarbage
      }
    }
  }
}

