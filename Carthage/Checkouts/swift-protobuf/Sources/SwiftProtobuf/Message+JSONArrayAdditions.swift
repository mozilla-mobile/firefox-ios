// Sources/SwiftProtobuf/Array+JSONAdditions.swift - JSON format primitive types
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Array` to support JSON encoding/decoding.
///
// -----------------------------------------------------------------------------

import Foundation

/// JSON encoding and decoding methods for arrays of messages.
extension Message {
  /// Returns a string containing the JSON serialization of the messages.
  ///
  /// Unlike binary encoding, presence of required fields is not enforced when
  /// serializing to JSON.
  ///
  /// - Returns: A string containing the JSON serialization of the messages.
  /// - Parameters:
  ///   - collection: The list of messages to encode.
  ///   - options: The JSONEncodingOptions to use.
  /// - Throws: `JSONEncodingError` if encoding fails.
  public static func jsonString<C: Collection>(
    from collection: C,
    options: JSONEncodingOptions = JSONEncodingOptions()
  ) throws -> String where C.Iterator.Element == Self {
    let data = try jsonUTF8Data(from: collection, options: options)
    return String(data: data, encoding: String.Encoding.utf8)!
  }

  /// Returns a Data containing the UTF-8 JSON serialization of the messages.
  ///
  /// Unlike binary encoding, presence of required fields is not enforced when
  /// serializing to JSON.
  ///
  /// - Returns: A Data containing the JSON serialization of the messages.
  /// - Parameters:
  ///   - collection: The list of messages to encode.
  ///   - options: The JSONEncodingOptions to use.
  /// - Throws: `JSONEncodingError` if encoding fails.
  public static func jsonUTF8Data<C: Collection>(
    from collection: C,
    options: JSONEncodingOptions = JSONEncodingOptions()
  ) throws -> Data where C.Iterator.Element == Self {
    var visitor = try JSONEncodingVisitor(type: Self.self, options: options)
    visitor.startArray()
    for message in collection {
        visitor.startObject()
        try message.traverse(visitor: &visitor)
        visitor.endObject()
    }
    visitor.endArray()
    return visitor.dataResult
  }

  /// Creates a new array of messages by decoding the given string containing a
  /// serialized array of messages in JSON format.
  ///
  /// - Parameter jsonString: The JSON-formatted string to decode.
  /// - Parameter options: The JSONDecodingOptions to use.
  /// - Throws: `JSONDecodingError` if decoding fails.
  public static func array(
    fromJSONString jsonString: String,
    options: JSONDecodingOptions = JSONDecodingOptions()
  ) throws -> [Self] {
    if jsonString.isEmpty {
      throw JSONDecodingError.truncated
    }
    if let data = jsonString.data(using: String.Encoding.utf8) {
      return try array(fromJSONUTF8Data: data, options: options)
    } else {
      throw JSONDecodingError.truncated
    }
  }

  /// Creates a new array of messages by decoding the given `Data` containing a
  /// serialized array of messages in JSON format, interpreting the data as
  /// UTF-8 encoded text.
  ///
  /// - Parameter jsonUTF8Data: The JSON-formatted data to decode, represented
  ///   as UTF-8 encoded text.
  /// - Parameter options: The JSONDecodingOptions to use.
  /// - Throws: `JSONDecodingError` if decoding fails.
  public static func array(
    fromJSONUTF8Data jsonUTF8Data: Data,
    options: JSONDecodingOptions = JSONDecodingOptions()
  ) throws -> [Self] {
    return try jsonUTF8Data.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
      var array = [Self]()

      if body.count > 0 {
        var decoder = JSONDecoder(source: body, options: options)
        try decoder.decodeRepeatedMessageField(value: &array)
        if !decoder.scanner.complete {
          throw JSONDecodingError.trailingGarbage
        }
      }

      return array
    }
  }

}
