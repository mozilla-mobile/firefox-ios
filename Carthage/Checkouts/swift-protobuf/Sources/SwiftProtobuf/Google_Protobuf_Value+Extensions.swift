// Sources/SwiftProtobuf/Google_Protobuf_Value+Extensions.swift - Value extensions
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Value is a well-known message type that can be used to parse or encode
/// arbitrary JSON without a predefined schema.
///
// -----------------------------------------------------------------------------

extension Google_Protobuf_Value: ExpressibleByIntegerLiteral {
  public typealias IntegerLiteralType = Int64

  /// Creates a new `Google_Protobuf_Value` from an integer literal.
  public init(integerLiteral value: Int64) {
    self.init(kind: .numberValue(Double(value)))
  }
}

extension Google_Protobuf_Value: ExpressibleByFloatLiteral {
  public typealias FloatLiteralType = Double

  /// Creates a new `Google_Protobuf_Value` from a floating point literal.
  public init(floatLiteral value: Double) {
    self.init(kind: .numberValue(value))
  }
}

extension Google_Protobuf_Value: ExpressibleByBooleanLiteral {
  public typealias BooleanLiteralType = Bool

  /// Creates a new `Google_Protobuf_Value` from a boolean literal.
  public init(booleanLiteral value: Bool) {
    self.init(kind: .boolValue(value))
  }
}

extension Google_Protobuf_Value: ExpressibleByStringLiteral {
  public typealias StringLiteralType = String
  public typealias ExtendedGraphemeClusterLiteralType = String
  public typealias UnicodeScalarLiteralType = String

  /// Creates a new `Google_Protobuf_Value` from a string literal.
  public init(stringLiteral value: String) {
    self.init(kind: .stringValue(value))
  }

  /// Creates a new `Google_Protobuf_Value` from a Unicode scalar literal.
  public init(unicodeScalarLiteral value: String) {
    self.init(kind: .stringValue(value))
  }

  /// Creates a new `Google_Protobuf_Value` from a character literal.
  public init(extendedGraphemeClusterLiteral value: String) {
    self.init(kind: .stringValue(value))
  }
}

extension Google_Protobuf_Value: ExpressibleByNilLiteral {
  /// Creates a new `Google_Protobuf_Value` from the nil literal.
  public init(nilLiteral: ()) {
    self.init(kind: .nullValue(.nullValue))
  }
}

extension Google_Protobuf_Value: _CustomJSONCodable {
  internal func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    var jsonEncoder = JSONEncoder()
    try serializeJSONValue(to: &jsonEncoder, options: options)
    return jsonEncoder.stringResult
  }

  internal mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    let c = try decoder.scanner.peekOneCharacter()
    switch c {
    case "n":
      if !decoder.scanner.skipOptionalNull() {
        throw JSONDecodingError.failure
      }
      kind = .nullValue(.nullValue)
    case "[":
      var l = Google_Protobuf_ListValue()
      try l.decodeJSON(from: &decoder)
      kind = .listValue(l)
    case "{":
      var s = Google_Protobuf_Struct()
      try s.decodeJSON(from: &decoder)
      kind = .structValue(s)
    case "t", "f":
      let b = try decoder.scanner.nextBool()
      kind = .boolValue(b)
    case "\"":
      let s = try decoder.scanner.nextQuotedString()
      kind = .stringValue(s)
    default:
      let d = try decoder.scanner.nextDouble()
      kind = .numberValue(d)
    }
  }

  internal static func decodedFromJSONNull() -> Google_Protobuf_Value? {
    return Google_Protobuf_Value(kind: .nullValue(.nullValue))
  }
}

extension Google_Protobuf_Value {
  /// Creates a new `Google_Protobuf_Value` with the given kind.
  fileprivate init(kind: OneOf_Kind) {
    self.init()
    self.kind = kind
  }

  /// Creates a new `Google_Protobuf_Value` whose `kind` is `numberValue` with
  /// the given floating-point value.
  public init(numberValue: Double) {
    self.init(kind: .numberValue(numberValue))
  }

  /// Creates a new `Google_Protobuf_Value` whose `kind` is `stringValue` with
  /// the given string value.
  public init(stringValue: String) {
    self.init(kind: .stringValue(stringValue))
  }

  /// Creates a new `Google_Protobuf_Value` whose `kind` is `boolValue` with the
  /// given boolean value.
  public init(boolValue: Bool) {
    self.init(kind: .boolValue(boolValue))
  }

  /// Creates a new `Google_Protobuf_Value` whose `kind` is `structValue` with
  /// the given `Google_Protobuf_Struct` value.
  public init(structValue: Google_Protobuf_Struct) {
    self.init(kind: .structValue(structValue))
  }

  /// Creates a new `Google_Protobuf_Value` whose `kind` is `listValue` with the
  /// given `Google_Struct_ListValue` value.
  public init(listValue: Google_Protobuf_ListValue) {
    self.init(kind: .listValue(listValue))
  }

  /// Writes out the JSON representation of the value to the given encoder.
  internal func serializeJSONValue(
    to encoder: inout JSONEncoder,
    options: JSONEncodingOptions
  ) throws {
    switch kind {
    case .nullValue?: encoder.putNullValue()
    case .numberValue(let v)?: encoder.putDoubleValue(value: v)
    case .stringValue(let v)?: encoder.putStringValue(value: v)
    case .boolValue(let v)?: encoder.putBoolValue(value: v)
    case .structValue(let v)?: encoder.append(text: try v.jsonString(options: options))
    case .listValue(let v)?: encoder.append(text: try v.jsonString(options: options))
    case nil: throw JSONEncodingError.missingValue
    }
  }
}
