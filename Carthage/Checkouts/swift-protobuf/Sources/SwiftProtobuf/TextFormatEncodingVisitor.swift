// Sources/SwiftProtobuf/TextFormatEncodingVisitor.swift - Text format encoding support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Text format serialization engine.
///
// -----------------------------------------------------------------------------

import Foundation

private let mapNameResolver: [Int:StaticString] = [1: "key", 2: "value"]

/// Visitor that serializes a message into protobuf text format.
internal struct TextFormatEncodingVisitor: Visitor {

  private var encoder: TextFormatEncoder
  private var nameMap: _NameMap?
  private var nameResolver: [Int:StaticString]
  private var extensions: ExtensionFieldValueSet?
  private let options: TextFormatEncodingOptions

  /// The protobuf text produced by the visitor.
  var result: String {
    return encoder.stringResult
  }

  /// Creates a new visitor that serializes the given message to protobuf text
  /// format.
  init(message: Message, options: TextFormatEncodingOptions) {
    self.init(message: message, encoder: TextFormatEncoder(), options: options)
  }

  /// Creates a new visitor that serializes the given message to protobuf text
  /// format, using an existing encoder.
  private init(message: Message, encoder: TextFormatEncoder, options: TextFormatEncodingOptions) {
    let nameMap: _NameMap?
    if let nameProviding = message as? _ProtoNameProviding {
        nameMap = type(of: nameProviding)._protobuf_nameMap
    } else {
        nameMap = nil
    }
    let extensions = (message as? ExtensibleMessage)?._protobuf_extensionFieldValues
    self.init(nameMap: nameMap, nameResolver: [:], extensions: extensions, encoder: encoder, options: options)
  }

  private init(
    nameMap: _NameMap?,
    nameResolver: [Int:StaticString],
    extensions: ExtensionFieldValueSet?,
    encoder: TextFormatEncoder,
    options: TextFormatEncodingOptions
  ) {
    self.nameMap = nameMap
    self.nameResolver = nameResolver
    self.extensions = extensions
    self.encoder = encoder
    self.options = options
  }

  private func formatFieldName(lookingUp fieldNumber: Int) -> [UInt8] {
      var bytes = [UInt8]()
      if let protoName = nameMap?.names(for: fieldNumber)?.proto {
          bytes.append(contentsOf: protoName.utf8Buffer)
      } else if let protoName = nameResolver[fieldNumber] {
          let buff = UnsafeBufferPointer(start: protoName.utf8Start, count: protoName.utf8CodeUnitCount)
          bytes.append(contentsOf: buff)
      } else if let extensionName = extensions?[fieldNumber]?.protobufExtension.fieldName {
          bytes.append(UInt8(ascii: "["))
          bytes.append(contentsOf: extensionName.utf8)
          bytes.append(UInt8(ascii: "]"))
      } else {
          bytes.append(contentsOf: fieldNumber.description.utf8)
      }
      return bytes
  }

  private mutating func emitFieldName(lookingUp fieldNumber: Int) {
      if let protoName = nameMap?.names(for: fieldNumber)?.proto {
          encoder.emitFieldName(name: protoName.utf8Buffer)
      } else if let protoName = nameResolver[fieldNumber] {
          encoder.emitFieldName(name: protoName)
      } else if let extensionName = extensions?[fieldNumber]?.protobufExtension.fieldName {
          encoder.emitExtensionFieldName(name: extensionName)
      } else {
          encoder.emitFieldNumber(number: fieldNumber)
      }
  }

  mutating func visitUnknown(bytes: Data) throws {
      if options.printUnknownFields {
          try bytes.withUnsafeBytes { (body: UnsafeRawBufferPointer) -> () in
            if let baseAddress = body.baseAddress, body.count > 0 {
              // All fields will be directly handled, so there is no need for
              // the unknown field buffering/collection (when scannings to see
              // if something is a message, this would be extremely wasteful).
              var binaryOptions = BinaryDecodingOptions()
              binaryOptions.discardUnknownFields = true
              var decoder = BinaryDecoder(forReadingFrom: baseAddress,
                                          count: body.count,
                                          options: binaryOptions)
              try visitUnknown(decoder: &decoder)
            }
          }
      }
  }

  /// Helper for printing out unknowns.
  ///
  /// The implementation tries to be "helpful" and if a length delimited field
  /// appears to be a submessage, it prints it as such. However, that opens the
  /// door to someone sending a message with an unknown field that is a stack
  /// bomb, i.e. - it causes this code to recurse, exhausing the stack and
  /// thus opening up an attack vector. To keep this "help", but avoid the
  /// attack, a limit is placed on how many times it will recurse before just
  /// treating the length delimted fields as bytes and not trying to decode
  /// them.
  private mutating func visitUnknown(
    decoder: inout BinaryDecoder,
    recursionBudget: Int = 10
  ) throws {
      // This stack serves to avoid recursion for groups within groups within
      // groups..., this avoid the stack attack that the message detection
      // hits. No limit is placed on this because there is no stack risk with
      // recursion, and because if a limit was hit, there is no other way to
      // encode the group (the message field can just print as length
      // delimited, groups don't have an option like that).
      var groupFieldNumberStack: [Int] = []

      while let tag = try decoder.getTag() {
          switch tag.wireFormat {
          case .varint:
              encoder.emitFieldNumber(number: tag.fieldNumber)
              var value: UInt64 = 0
              encoder.startRegularField()
              try decoder.decodeSingularUInt64Field(value: &value)
              encoder.putUInt64(value: value)
              encoder.endRegularField()
          case .fixed64:
              encoder.emitFieldNumber(number: tag.fieldNumber)
              var value: UInt64 = 0
              encoder.startRegularField()
              try decoder.decodeSingularFixed64Field(value: &value)
              encoder.putUInt64Hex(value: value, digits: 16)
              encoder.endRegularField()
          case .lengthDelimited:
              encoder.emitFieldNumber(number: tag.fieldNumber)
              var bytes = Internal.emptyData
              try decoder.decodeSingularBytesField(value: &bytes)
              bytes.withUnsafeBytes { (body: UnsafeRawBufferPointer) -> () in
                  if let baseAddress = body.baseAddress, body.count > 0 {
                      var encodeAsBytes: Bool
                      if (recursionBudget > 0) {
                          do {
                              // Walk all the fields to test if it looks like a message
                              var testDecoder = BinaryDecoder(forReadingFrom: baseAddress,
                                                              count: body.count,
                                                              parent: decoder)
                              while let _ = try testDecoder.nextFieldNumber() {
                              }
                              // No error?  Output the message body.
                              encodeAsBytes = false
                              var subDecoder = BinaryDecoder(forReadingFrom: baseAddress,
                                                             count: bytes.count,
                                                             parent: decoder)
                              encoder.startMessageField()
                              try visitUnknown(decoder: &subDecoder,
                                               recursionBudget: recursionBudget - 1)
                              encoder.endMessageField()
                          } catch {
                              encodeAsBytes = true
                          }
                      } else {
                          encodeAsBytes = true
                      }
                      if (encodeAsBytes) {
                        encoder.startRegularField()
                        encoder.putBytesValue(value: bytes)
                        encoder.endRegularField()
                      }
                  }
              }
          case .startGroup:
              encoder.emitFieldNumber(number: tag.fieldNumber)
              encoder.startMessageField()
              groupFieldNumberStack.append(tag.fieldNumber)
          case .endGroup:
              let groupFieldNumber = groupFieldNumberStack.popLast()
              // Unknown data is scanned and verified by the
              // binary parser, so this can never fail.
              assert(tag.fieldNumber == groupFieldNumber)
              encoder.endMessageField()
          case .fixed32:
              encoder.emitFieldNumber(number: tag.fieldNumber)
              var value: UInt32 = 0
              encoder.startRegularField()
              try decoder.decodeSingularFixed32Field(value: &value)
              encoder.putUInt64Hex(value: UInt64(value), digits: 8)
              encoder.endRegularField()
          }
      }

    // Unknown data is scanned and verified by the binary parser, so this can
    // never fail.
    assert(groupFieldNumberStack.isEmpty)
  }

  // Visitor.swift defines default versions for other singular field types
  // that simply widen and dispatch to one of the following.  Since Text format
  // does not distinguish e.g., Fixed64 vs. UInt64, this is sufficient.

  mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws {
      emitFieldName(lookingUp: fieldNumber)
      encoder.startRegularField()
      encoder.putFloatValue(value: value)
      encoder.endRegularField()
  }

  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
      emitFieldName(lookingUp: fieldNumber)
      encoder.startRegularField()
      encoder.putDoubleValue(value: value)
      encoder.endRegularField()
  }

  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
      emitFieldName(lookingUp: fieldNumber)
      encoder.startRegularField()
      encoder.putInt64(value: value)
      encoder.endRegularField()
  }

  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
      emitFieldName(lookingUp: fieldNumber)
      encoder.startRegularField()
      encoder.putUInt64(value: value)
      encoder.endRegularField()
  }

  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
      emitFieldName(lookingUp: fieldNumber)
      encoder.startRegularField()
      encoder.putBoolValue(value: value)
      encoder.endRegularField()
  }

  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
      emitFieldName(lookingUp: fieldNumber)
      encoder.startRegularField()
      encoder.putStringValue(value: value)
      encoder.endRegularField()
  }

  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
      emitFieldName(lookingUp: fieldNumber)
      encoder.startRegularField()
      encoder.putBytesValue(value: value)
      encoder.endRegularField()
  }

  mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws {
      emitFieldName(lookingUp: fieldNumber)
      encoder.startRegularField()
      encoder.putEnumValue(value: value)
      encoder.endRegularField()
  }

  mutating func visitSingularMessageField<M: Message>(value: M,
                                             fieldNumber: Int) throws {
      emitFieldName(lookingUp: fieldNumber)

      // Cache old encoder state
      let oldNameMap = self.nameMap
      let oldNameResolver = self.nameResolver
      let oldExtensions = self.extensions
      // Update encoding state for new message
      self.nameMap = (M.self as? _ProtoNameProviding.Type)?._protobuf_nameMap
      self.nameResolver = [:]
      self.extensions = (value as? ExtensibleMessage)?._protobuf_extensionFieldValues
      // Restore state before returning
      defer {
        self.extensions = oldExtensions
        self.nameResolver = oldNameResolver
        self.nameMap = oldNameMap
      }
      // Encode submessage
      encoder.startMessageField()
      if let any = value as? Google_Protobuf_Any {
          any.textTraverse(visitor: &self)
      } else {
          try! value.traverse(visitor: &self)
      }
      encoder.endMessageField()
  }

  // Emit the full "verbose" form of an Any.  This writes the typeURL
  // as a field name in `[...]` followed by the fields of the
  // contained message.
  internal mutating func visitAnyVerbose(value: Message, typeURL: String) {
      encoder.emitExtensionFieldName(name: typeURL)
      encoder.startMessageField()
      var visitor = TextFormatEncodingVisitor(message: value, encoder: encoder, options: options)
      if let any = value as? Google_Protobuf_Any {
          any.textTraverse(visitor: &visitor)
      } else {
          try! value.traverse(visitor: &visitor)
      }
      encoder = visitor.encoder
      encoder.endMessageField()
  }

  // Write a single special field called "#json".  This
  // is used for Any objects with undecoded JSON contents.
  internal mutating func visitAnyJSONDataField(value: Data) {
      encoder.indent()
      encoder.append(staticText: "#json: ")
      encoder.putBytesValue(value: value)
      encoder.append(staticText: "\n")
  }

  // The default implementations in Visitor.swift provide the correct
  // results, but we get significantly better performance by only doing
  // the name lookup once for the array, rather than once for each element:

  mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
      let fieldName = formatFieldName(lookingUp: fieldNumber)
      for v in value {
          encoder.emitFieldName(name: fieldName)
          encoder.startRegularField()
          encoder.putFloatValue(value: v)
          encoder.endRegularField()
      }
  }

  mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
      let fieldName = formatFieldName(lookingUp: fieldNumber)
      for v in value {
          encoder.emitFieldName(name: fieldName)
          encoder.startRegularField()
          encoder.putDoubleValue(value: v)
          encoder.endRegularField()
      }
  }

  mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
      let fieldName = formatFieldName(lookingUp: fieldNumber)
      for v in value {
          encoder.emitFieldName(name: fieldName)
          encoder.startRegularField()
          encoder.putInt64(value: Int64(v))
          encoder.endRegularField()
      }
  }

  mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
      let fieldName = formatFieldName(lookingUp: fieldNumber)
      for v in value {
          encoder.emitFieldName(name: fieldName)
          encoder.startRegularField()
          encoder.putInt64(value: v)
          encoder.endRegularField()
      }
  }

  mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
      let fieldName = formatFieldName(lookingUp: fieldNumber)
      for v in value {
          encoder.emitFieldName(name: fieldName)
          encoder.startRegularField()
          encoder.putUInt64(value: UInt64(v))
          encoder.endRegularField()
      }
  }

  mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
      let fieldName = formatFieldName(lookingUp: fieldNumber)
      for v in value {
          encoder.emitFieldName(name: fieldName)
          encoder.startRegularField()
          encoder.putUInt64(value: v)
          encoder.endRegularField()
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
      let fieldName = formatFieldName(lookingUp: fieldNumber)
      for v in value {
          encoder.emitFieldName(name: fieldName)
          encoder.startRegularField()
          encoder.putBoolValue(value: v)
          encoder.endRegularField()
      }
  }

  mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
      let fieldName = formatFieldName(lookingUp: fieldNumber)
      for v in value {
          encoder.emitFieldName(name: fieldName)
          encoder.startRegularField()
          encoder.putStringValue(value: v)
          encoder.endRegularField()
      }
  }

  mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
      let fieldName = formatFieldName(lookingUp: fieldNumber)
      for v in value {
          encoder.emitFieldName(name: fieldName)
          encoder.startRegularField()
          encoder.putBytesValue(value: v)
          encoder.endRegularField()
      }
  }

  mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
      let fieldName = formatFieldName(lookingUp: fieldNumber)
      for v in value {
          encoder.emitFieldName(name: fieldName)
          encoder.startRegularField()
          encoder.putEnumValue(value: v)
          encoder.endRegularField()
      }
  }

  // Messages and groups
  mutating func visitRepeatedMessageField<M: Message>(value: [M],
                                             fieldNumber: Int) throws {
      // Look up field name against outer message encoding state
      let fieldName = formatFieldName(lookingUp: fieldNumber)
      // Cache old encoder state
      let oldNameMap = self.nameMap
      let oldNameResolver = self.nameResolver
      let oldExtensions = self.extensions
      // Update encoding state for new message type
      self.nameMap = (M.self as? _ProtoNameProviding.Type)?._protobuf_nameMap
      self.nameResolver = [:]
      self.extensions = (value as? ExtensibleMessage)?._protobuf_extensionFieldValues
      // Iterate and encode each message
      for v in value {
          encoder.emitFieldName(name: fieldName)
          encoder.startMessageField()
          if let any = v as? Google_Protobuf_Any {
              any.textTraverse(visitor: &self)
          } else {
              try! v.traverse(visitor: &self)
          }
          encoder.endMessageField()
      }
      // Restore state
      self.extensions = oldExtensions
      self.nameResolver = oldNameResolver
      self.nameMap = oldNameMap
  }

  // Google's C++ implementation of Text format supports two formats
  // for repeated numeric fields: "short" format writes the list as a
  // single field with values enclosed in `[...]`, "long" format
  // writes a separate field name/value for each item.  They provide
  // an option for callers to select which output version they prefer.

  // Since this distinction mirrors the difference in Protobuf Binary
  // between "packed" and "non-packed", I've chosen to use the short
  // format for packed fields and the long version for repeated
  // fields.  This provides a clear visual distinction between these
  // fields (including proto3's default use of packed) without
  // introducing the baggage of a separate option.

  private mutating func _visitPacked<T>(
    value: [T], fieldNumber: Int,
    encode: (T, inout TextFormatEncoder) -> ()
  ) throws {
      emitFieldName(lookingUp: fieldNumber)
      encoder.startRegularField()
      var firstItem = true
      encoder.startArray()
      for v in value {
          if !firstItem {
              encoder.arraySeparator()
          }
          encode(v, &encoder)
          firstItem = false
      }
      encoder.endArray()
      encoder.endRegularField()
  }

  mutating func visitPackedFloatField(value: [Float], fieldNumber: Int) throws {
    try _visitPacked(value: value, fieldNumber: fieldNumber) {
      (v: Float, encoder: inout TextFormatEncoder) in
      encoder.putFloatValue(value: v)
    }
  }

  mutating func visitPackedDoubleField(value: [Double], fieldNumber: Int) throws {
    try _visitPacked(value: value, fieldNumber: fieldNumber) {
      (v: Double, encoder: inout TextFormatEncoder) in
      encoder.putDoubleValue(value: v)
    }
  }

  mutating func visitPackedInt32Field(value: [Int32], fieldNumber: Int) throws {
    try _visitPacked(value: value, fieldNumber: fieldNumber) {
      (v: Int32, encoder: inout TextFormatEncoder) in
      encoder.putInt64(value: Int64(v))
    }
  }

  mutating func visitPackedInt64Field(value: [Int64], fieldNumber: Int) throws {
    try _visitPacked(value: value, fieldNumber: fieldNumber) {
      (v: Int64, encoder: inout TextFormatEncoder) in
      encoder.putInt64(value: v)
    }
  }

  mutating func visitPackedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    try _visitPacked(value: value, fieldNumber: fieldNumber) {
      (v: UInt32, encoder: inout TextFormatEncoder) in
      encoder.putUInt64(value: UInt64(v))
    }
  }

  mutating func visitPackedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    try _visitPacked(value: value, fieldNumber: fieldNumber) {
      (v: UInt64, encoder: inout TextFormatEncoder) in
      encoder.putUInt64(value: v)
    }
  }

  mutating func visitPackedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    try visitPackedInt32Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitPackedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    try visitPackedInt64Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitPackedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    try visitPackedUInt32Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitPackedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    try visitPackedUInt64Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitPackedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    try visitPackedInt32Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitPackedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    try visitPackedInt64Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitPackedBoolField(value: [Bool], fieldNumber: Int) throws {
    try _visitPacked(value: value, fieldNumber: fieldNumber) {
      (v: Bool, encoder: inout TextFormatEncoder) in
      encoder.putBoolValue(value: v)
    }
  }

  mutating func visitPackedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
    try _visitPacked(value: value, fieldNumber: fieldNumber) {
      (v: E, encoder: inout TextFormatEncoder) in
      encoder.putEnumValue(value: v)
    }
  }

  /// Helper to encapsulate the common structure of iterating over a map
  /// and encoding the keys and values.
  private mutating func _visitMap<K, V>(
    map: Dictionary<K, V>,
    fieldNumber: Int,
    coder: (inout TextFormatEncodingVisitor, K, V) throws -> ()
  ) throws {
      for (k,v) in map {
          emitFieldName(lookingUp: fieldNumber)
          encoder.startMessageField()
          var visitor = TextFormatEncodingVisitor(nameMap: nil, nameResolver: mapNameResolver, extensions: nil, encoder: encoder, options: options)
          try coder(&visitor, k, v)
          encoder = visitor.encoder
          encoder.endMessageField()
      }
  }

  mutating func visitMapField<KeyType, ValueType: MapValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: _ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
      try _visitMap(map: value, fieldNumber: fieldNumber) {
          (visitor: inout TextFormatEncodingVisitor, key, value) throws -> () in
          try KeyType.visitSingular(value: key, fieldNumber: 1, with: &visitor)
          try ValueType.visitSingular(value: value, fieldNumber: 2, with: &visitor)
      }
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where ValueType.RawValue == Int {
      try _visitMap(map: value, fieldNumber: fieldNumber) {
          (visitor: inout TextFormatEncodingVisitor, key, value) throws -> () in
          try KeyType.visitSingular(value: key, fieldNumber: 1, with: &visitor)
          try visitor.visitSingularEnumField(value: value, fieldNumber: 2)
      }
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
      try _visitMap(map: value, fieldNumber: fieldNumber) {
          (visitor: inout TextFormatEncodingVisitor, key, value) throws -> () in
          try KeyType.visitSingular(value: key, fieldNumber: 1, with: &visitor)
          try visitor.visitSingularMessageField(value: value, fieldNumber: 2)
      }
  }
}
