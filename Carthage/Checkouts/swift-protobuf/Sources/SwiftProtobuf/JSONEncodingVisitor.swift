// Sources/SwiftProtobuf/JSONEncodingVisitor.swift - JSON encoding visitor
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Visitor that writes a message in JSON format.
///
// -----------------------------------------------------------------------------

import Foundation

/// Visitor that serializes a message into JSON format.
internal struct JSONEncodingVisitor: Visitor {

  private var encoder = JSONEncoder()
  private var nameMap: _NameMap
  private let options: JSONEncodingOptions

  /// The JSON text produced by the visitor, as raw UTF8 bytes.
  var dataResult: Data {
    return encoder.dataResult
  }

  /// The JSON text produced by the visitor, as a String.
  internal var stringResult: String {
      return encoder.stringResult
  }

  /// Creates a new visitor for serializing a message of the given type to JSON
  /// format.
  init(type: Message.Type, options: JSONEncodingOptions) throws {
    if let nameProviding = type as? _ProtoNameProviding.Type {
      self.nameMap = nameProviding._protobuf_nameMap
    } else {
      throw JSONEncodingError.missingFieldNames
    }
    self.options = options
  }

  /// Creates a new visitor that serializes the given message to JSON format.
  init(message: Message, options: JSONEncodingOptions) throws {
    if let nameProviding = message as? _ProtoNameProviding {
      self.nameMap = type(of: nameProviding)._protobuf_nameMap
    } else {
      throw JSONEncodingError.missingFieldNames
    }
    self.options = options
  }

  mutating func startArray() {
    encoder.startArray()
  }

  mutating func endArray() {
    encoder.endArray()
  }

  mutating func startObject() {
    encoder.startObject()
  }

  mutating func endObject() {
    encoder.endObject()
  }

  mutating func encodeField(name: String, stringValue value: String) {
    encoder.startField(name: name)
    encoder.putStringValue(value: value)
  }

  mutating func encodeField(name: String, jsonText text: String) {
    encoder.startField(name: name)
    encoder.append(text: text)
  }

  mutating func visitUnknown(bytes: Data) throws {
    // JSON encoding has no provision for carrying proto2 unknown fields.
  }

  mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putFloatValue(value: value)
  }

  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putDoubleValue(value: value)
  }

  mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putInt32(value: value)
  }

  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putInt64(value: value)
  }

  mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putUInt32(value: value)
  }

  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putUInt64(value: value)
  }

  mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putUInt32(value: value)
  }

  mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putInt32(value: value)
  }

  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putBoolValue(value: value)
  }

  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putStringValue(value: value)
  }

  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putBytesValue(value: value)
  }

  private mutating func _visitRepeated<T>(
    value: [T],
    fieldNumber: Int,
    encode: (inout JSONEncoder, T) throws -> ()
  ) throws {
    try startField(for: fieldNumber)
    var comma = false
    encoder.startArray()
    for v in value {
      if comma {
          encoder.comma()
      }
      comma = true
      try encode(&encoder, v)
    }
    encoder.endArray()
  }

  mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    if !options.alwaysPrintEnumsAsInts, let n = value.name {
      encoder.appendQuoted(name: n)
    } else {
      encoder.putEnumInt(value: value.rawValue)
    }
  }

  mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    if let m = value as? _CustomJSONCodable {
      let json = try m.encodedJSONString(options: options)
      encoder.append(text: json)
    } else if let newNameMap = (M.self as? _ProtoNameProviding.Type)?._protobuf_nameMap {
      encoder.startNestedObject()
      let oldNameMap = self.nameMap
      self.nameMap = newNameMap
      try value.traverse(visitor: &self)
      self.nameMap = oldNameMap
      endObject()
    } else {
      throw JSONEncodingError.missingFieldNames
    }
  }

  mutating func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws {
    // Google does not serialize groups into JSON
  }

  mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
    try _visitRepeated(value: value, fieldNumber: fieldNumber) {
      (encoder: inout JSONEncoder, v: Float) in
      encoder.putFloatValue(value: v)
    }
  }

  mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
    try _visitRepeated(value: value, fieldNumber: fieldNumber) {
      (encoder: inout JSONEncoder, v: Double) in
      encoder.putDoubleValue(value: v)
    }
  }

  mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
    try _visitRepeated(value: value, fieldNumber: fieldNumber) {
      (encoder: inout JSONEncoder, v: Int32) in
      encoder.putInt32(value: v)
    }
  }

  mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
    try _visitRepeated(value: value, fieldNumber: fieldNumber) {
      (encoder: inout JSONEncoder, v: Int64) in
      encoder.putInt64(value: v)
    }
  }

   mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    try _visitRepeated(value: value, fieldNumber: fieldNumber) {
      (encoder: inout JSONEncoder, v: UInt32) in
      encoder.putUInt32(value: v)
    }
  }

  mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    try _visitRepeated(value: value, fieldNumber: fieldNumber) {
      (encoder: inout JSONEncoder, v: UInt64) in
      encoder.putUInt64(value: v)
    }
  }

   mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    try visitRepeatedInt32Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    try visitRepeatedInt64Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    try visitRepeatedUInt32Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    try visitRepeatedUInt64Field(value: value, fieldNumber: fieldNumber)
  }

   mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    try visitRepeatedInt32Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    try visitRepeatedInt64Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {
    try _visitRepeated(value: value, fieldNumber: fieldNumber) {
      (encoder: inout JSONEncoder, v: Bool) in
      encoder.putBoolValue(value: v)
    }
  }

  mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
    try _visitRepeated(value: value, fieldNumber: fieldNumber) {
      (encoder: inout JSONEncoder, v: String) in
      encoder.putStringValue(value: v)
    }
  }

  mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
    try _visitRepeated(value: value, fieldNumber: fieldNumber) {
      (encoder: inout JSONEncoder, v: Data) in
      encoder.putBytesValue(value: v)
    }
  }

  mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
    let alwaysPrintEnumsAsInts = options.alwaysPrintEnumsAsInts
    try _visitRepeated(value: value, fieldNumber: fieldNumber) {
      (encoder: inout JSONEncoder, v: E) throws in
      if !alwaysPrintEnumsAsInts, let n = v.name {
        encoder.appendQuoted(name: n)
      } else {
        encoder.putEnumInt(value: v.rawValue)
      }
    }
  }

  mutating func visitRepeatedMessageField<M: Message>(value: [M], fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    var comma = false
    encoder.startArray()
    if let _ = M.self as? _CustomJSONCodable.Type {
      for v in value {
        if comma {
          encoder.comma()
        }
        comma = true
        let json = try v.jsonString(options: options)
        encoder.append(text: json)
      }
    } else if let newNameMap = (M.self as? _ProtoNameProviding.Type)?._protobuf_nameMap {
      // Install inner object's name map
      let oldNameMap = self.nameMap
      self.nameMap = newNameMap
      // Restore outer object's name map before returning
      defer { self.nameMap = oldNameMap }
      for v in value {
        if comma {
          encoder.comma()
        }
        comma = true
        encoder.startNestedObject()
        try v.traverse(visitor: &self)
        encoder.endObject()
      }
    } else {
      throw JSONEncodingError.missingFieldNames
    }
    encoder.endArray()
  }

  mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws {
    // Google does not serialize groups into JSON
  }

  // Packed fields are handled the same as non-packed fields, so JSON just
  // relies on the default implementations in Visitor.swift



  mutating func visitMapField<KeyType, ValueType: MapValueType>(fieldType: _ProtobufMap<KeyType, ValueType>.Type, value: _ProtobufMap<KeyType, ValueType>.BaseType, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.append(text: "{")
    var mapVisitor = JSONMapEncodingVisitor(encoder: encoder, options: options)
    for (k,v) in value {
        try KeyType.visitSingular(value: k, fieldNumber: 1, with: &mapVisitor)
        try ValueType.visitSingular(value: v, fieldNumber: 2, with: &mapVisitor)
    }
    encoder = mapVisitor.encoder
    encoder.append(text: "}")
  }

  mutating func visitMapField<KeyType, ValueType>(fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type, value: _ProtobufEnumMap<KeyType, ValueType>.BaseType, fieldNumber: Int) throws  where ValueType.RawValue == Int {
    try startField(for: fieldNumber)
    encoder.append(text: "{")
    var mapVisitor = JSONMapEncodingVisitor(encoder: encoder, options: options)
    for (k, v) in value {
      try KeyType.visitSingular(value: k, fieldNumber: 1, with: &mapVisitor)
      try mapVisitor.visitSingularEnumField(value: v, fieldNumber: 2)
    }
    encoder = mapVisitor.encoder
    encoder.append(text: "}")
  }

  mutating func visitMapField<KeyType, ValueType>(fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type, value: _ProtobufMessageMap<KeyType, ValueType>.BaseType, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.append(text: "{")
    var mapVisitor = JSONMapEncodingVisitor(encoder: encoder, options: options)
    for (k,v) in value {
        try KeyType.visitSingular(value: k, fieldNumber: 1, with: &mapVisitor)
        try mapVisitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }
    encoder = mapVisitor.encoder
    encoder.append(text: "}")
  }

  /// Called for each extension range.
  mutating func visitExtensionFields(fields: ExtensionFieldValueSet, start: Int, end: Int) throws {
    // JSON does not store extensions
  }

  /// Helper function that throws an error if the field number could not be
  /// resolved.
  private mutating func startField(for number: Int) throws {
    let name: _NameMap.Name?

    if options.preserveProtoFieldNames {
        name = nameMap.names(for: number)?.proto
    } else {
        name = nameMap.names(for: number)?.json
    }

    if let nm = name {
        encoder.startField(name: nm)
    } else {
        throw JSONEncodingError.missingFieldNames
    }
  }
}
