// Sources/SwiftProtobuf/Google_Protobuf_Wrappers+Extensions.swift - Well-known wrapper type extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to the well-known types in wrapper.proto that customize the JSON
/// format of those messages and provide convenience initializers from literals.
///
// -----------------------------------------------------------------------------

import Foundation

/// Internal protocol that minimizes the code duplication across the multiple
/// wrapper types extended below.
protocol ProtobufWrapper {

  /// The wrapped protobuf type (for example, `ProtobufDouble`).
  associatedtype WrappedType: FieldType

  /// Exposes the generated property to the extensions here.
  var value: WrappedType.BaseType { get set }

  /// Exposes the parameterless initializer to the extensions here.
  init()

  /// Creates a new instance of the wrapper with the given value.
  init(_ value: WrappedType.BaseType)
}

extension Google_Protobuf_DoubleValue:
  ProtobufWrapper, ExpressibleByFloatLiteral, _CustomJSONCodable {

  public typealias WrappedType = ProtobufDouble
  public typealias FloatLiteralType = WrappedType.BaseType

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public init(floatLiteral: FloatLiteralType) {
    self.init(floatLiteral)
  }

  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    var encoder = JSONEncoder()
    encoder.putDoubleValue(value: value)
    return encoder.stringResult
  }

  mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    var v: WrappedType.BaseType?
    try WrappedType.decodeSingular(value: &v, from: &decoder)
    value = v ?? WrappedType.proto3DefaultValue
  }
}

extension Google_Protobuf_FloatValue:
  ProtobufWrapper, ExpressibleByFloatLiteral, _CustomJSONCodable {

  public typealias WrappedType = ProtobufFloat
  public typealias FloatLiteralType = Float

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public init(floatLiteral: FloatLiteralType) {
    self.init(floatLiteral)
  }

  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    var encoder = JSONEncoder()
    encoder.putFloatValue(value: value)
    return encoder.stringResult
  }

  mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    var v: WrappedType.BaseType?
    try WrappedType.decodeSingular(value: &v, from: &decoder)
    value = v ?? WrappedType.proto3DefaultValue
  }
}

extension Google_Protobuf_Int64Value:
  ProtobufWrapper, ExpressibleByIntegerLiteral, _CustomJSONCodable {

  public typealias WrappedType = ProtobufInt64
  public typealias IntegerLiteralType = WrappedType.BaseType

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public init(integerLiteral: IntegerLiteralType) {
    self.init(integerLiteral)
  }

  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    var encoder = JSONEncoder()
    encoder.putInt64(value: value)
    return encoder.stringResult
  }

  mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    var v: WrappedType.BaseType?
    try WrappedType.decodeSingular(value: &v, from: &decoder)
    value = v ?? WrappedType.proto3DefaultValue
  }
}

extension Google_Protobuf_UInt64Value:
  ProtobufWrapper, ExpressibleByIntegerLiteral, _CustomJSONCodable {

  public typealias WrappedType = ProtobufUInt64
  public typealias IntegerLiteralType = WrappedType.BaseType

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public init(integerLiteral: IntegerLiteralType) {
    self.init(integerLiteral)
  }

  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    var encoder = JSONEncoder()
    encoder.putUInt64(value: value)
    return encoder.stringResult
  }

  mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    var v: WrappedType.BaseType?
    try WrappedType.decodeSingular(value: &v, from: &decoder)
    value = v ?? WrappedType.proto3DefaultValue
  }
}

extension Google_Protobuf_Int32Value:
  ProtobufWrapper, ExpressibleByIntegerLiteral, _CustomJSONCodable {

  public typealias WrappedType = ProtobufInt32
  public typealias IntegerLiteralType = WrappedType.BaseType

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public init(integerLiteral: IntegerLiteralType) {
    self.init(integerLiteral)
  }

  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    return String(value)
  }

  mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    var v: WrappedType.BaseType?
    try WrappedType.decodeSingular(value: &v, from: &decoder)
    value = v ?? WrappedType.proto3DefaultValue
  }
}

extension Google_Protobuf_UInt32Value:
  ProtobufWrapper, ExpressibleByIntegerLiteral, _CustomJSONCodable {

  public typealias WrappedType = ProtobufUInt32
  public typealias IntegerLiteralType = WrappedType.BaseType

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public init(integerLiteral: IntegerLiteralType) {
    self.init(integerLiteral)
  }

  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    return String(value)
  }

  mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    var v: WrappedType.BaseType?
    try WrappedType.decodeSingular(value: &v, from: &decoder)
    value = v ?? WrappedType.proto3DefaultValue
  }
}

extension Google_Protobuf_BoolValue:
  ProtobufWrapper, ExpressibleByBooleanLiteral, _CustomJSONCodable {

  public typealias WrappedType = ProtobufBool
  public typealias BooleanLiteralType = Bool

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public init(booleanLiteral: Bool) {
    self.init(booleanLiteral)
  }

  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    return value ? "true" : "false"
  }

  mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    var v: WrappedType.BaseType?
    try WrappedType.decodeSingular(value: &v, from: &decoder)
    value = v ?? WrappedType.proto3DefaultValue
  }
}

extension Google_Protobuf_StringValue:
  ProtobufWrapper, ExpressibleByStringLiteral, _CustomJSONCodable {

  public typealias WrappedType = ProtobufString
  public typealias StringLiteralType = String
  public typealias ExtendedGraphemeClusterLiteralType = String
  public typealias UnicodeScalarLiteralType = String

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public init(stringLiteral: String) {
    self.init(stringLiteral)
  }

  public init(extendedGraphemeClusterLiteral: String) {
    self.init(extendedGraphemeClusterLiteral)
  }

  public init(unicodeScalarLiteral: String) {
    self.init(unicodeScalarLiteral)
  }

  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    var encoder = JSONEncoder()
    encoder.putStringValue(value: value)
    return encoder.stringResult
  }

  mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    var v: WrappedType.BaseType?
    try WrappedType.decodeSingular(value: &v, from: &decoder)
    value = v ?? WrappedType.proto3DefaultValue
  }
}

extension Google_Protobuf_BytesValue: ProtobufWrapper, _CustomJSONCodable {

  public typealias WrappedType = ProtobufBytes

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    var encoder = JSONEncoder()
    encoder.putBytesValue(value: value)
    return encoder.stringResult
  }

  mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    var v: WrappedType.BaseType?
    try WrappedType.decodeSingular(value: &v, from: &decoder)
    value = v ?? WrappedType.proto3DefaultValue
  }
}
