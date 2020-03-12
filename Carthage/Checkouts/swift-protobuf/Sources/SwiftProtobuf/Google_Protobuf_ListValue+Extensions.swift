// Sources/SwiftProtobuf/Google_Protobuf_ListValue+Extensions.swift - ListValue extensions
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// ListValue is a well-known message type that can be used to parse or encode
/// arbitrary JSON arrays without a predefined schema.
///
// -----------------------------------------------------------------------------

extension Google_Protobuf_ListValue: ExpressibleByArrayLiteral {
  // TODO: Give this a direct array interface by proxying the interesting
  // bits down to values
  public typealias Element = Google_Protobuf_Value

  /// Creates a new `Google_Protobuf_ListValue` from an array literal containing
  /// `Google_Protobuf_Value` elements.
  public init(arrayLiteral elements: Element...) {
    self.init(values: elements)
  }
}

extension Google_Protobuf_ListValue: _CustomJSONCodable {
  internal func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    var jsonEncoder = JSONEncoder()
    jsonEncoder.append(text: "[")
    var separator: StaticString = ""
    for v in values {
      jsonEncoder.append(staticText: separator)
      try v.serializeJSONValue(to: &jsonEncoder, options: options)
      separator = ","
    }
    jsonEncoder.append(text: "]")
    return jsonEncoder.stringResult
  }

  internal mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    if decoder.scanner.skipOptionalNull() {
      return
    }
    try decoder.scanner.skipRequiredArrayStart()
    if decoder.scanner.skipOptionalArrayEnd() {
      return
    }
    while true {
      var v = Google_Protobuf_Value()
      try v.decodeJSON(from: &decoder)
      values.append(v)
      if decoder.scanner.skipOptionalArrayEnd() {
        return
      }
      try decoder.scanner.skipRequiredComma()
    }
  }
}

extension Google_Protobuf_ListValue {
  /// Creates a new `Google_Protobuf_ListValue` from the given array of
  /// `Google_Protobuf_Value` elements.
  ///
  /// - Parameter values: The list of `Google_Protobuf_Value` messages from
  ///   which to create the `Google_Protobuf_ListValue`.
  public init(values: [Google_Protobuf_Value]) {
    self.init()
    self.values = values
  }

  /// Accesses the `Google_Protobuf_Value` at the specified position.
  ///
  /// - Parameter index: The position of the element to access.
  public subscript(index: Int) -> Google_Protobuf_Value {
    get {return values[index]}
    set(newValue) {values[index] = newValue}
  }
}
