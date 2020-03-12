// Sources/SwiftProtobuf/Google_Protobuf_Struct+Extensions.swift - Struct extensions
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Struct is a well-known message type that can be used to parse or encode
/// arbitrary JSON objects without a predefined schema.
///
// -----------------------------------------------------------------------------

extension Google_Protobuf_Struct: ExpressibleByDictionaryLiteral {
  public typealias Key = String
  public typealias Value = Google_Protobuf_Value

  /// Creates a new `Google_Protobuf_Struct` from a dictionary of string keys to
  /// values of type `Google_Protobuf_Value`.
  public init(dictionaryLiteral: (String, Google_Protobuf_Value)...) {
    self.init()
    for (k,v) in dictionaryLiteral {
      fields[k] = v
    }
  }
}

extension Google_Protobuf_Struct: _CustomJSONCodable {
  internal func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    var jsonEncoder = JSONEncoder()
    jsonEncoder.startObject()
    var mapVisitor = JSONMapEncodingVisitor(encoder: jsonEncoder, options: options)
    for (k,v) in fields {
      try mapVisitor.visitSingularStringField(value: k, fieldNumber: 1)
      try mapVisitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }
    mapVisitor.encoder.endObject()
    return mapVisitor.encoder.stringResult
  }

  internal mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    try decoder.scanner.skipRequiredObjectStart()
    if decoder.scanner.skipOptionalObjectEnd() {
      return
    }
    while true {
      let key = try decoder.scanner.nextQuotedString()
      try decoder.scanner.skipRequiredColon()
      var value = Google_Protobuf_Value()
      try value.decodeJSON(from: &decoder)
      fields[key] = value
      if decoder.scanner.skipOptionalObjectEnd() {
        return
      }
      try decoder.scanner.skipRequiredComma()
    }
  }
}

extension Google_Protobuf_Struct {
  /// Creates a new `Google_Protobuf_Struct` from a dictionary of string keys to
  /// values of type `Google_Protobuf_Value`.
  ///
  /// - Parameter fields: The dictionary from field names to
  ///   `Google_Protobuf_Value` messages that should be used to create the
  ///   `Struct`.
  public init(fields: [String: Google_Protobuf_Value]) {
    self.init()
    self.fields = fields
  }

  /// Accesses the `Google_Protobuf_Value` with the given key for reading and
  /// writing.
  ///
  /// This key-based subscript returns the `Value` for the given key if the key
  /// is found in the `Struct`, or nil if the key is not found. If you assign
  /// nil as the `Value` for the given key, the `Struct` removes that key and
  /// its associated `Value`.
  public subscript(key: String) -> Google_Protobuf_Value? {
    get {return fields[key]}
    set(newValue) {fields[key] = newValue}
  }
}
