// Sources/SwiftProtobuf/SelectiveVisitor.swift - Base for custom Visitors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A base for Visitors that only expect a subset of things to called.
///
// -----------------------------------------------------------------------------

import Foundation

/// A base for Visitors that only expects a subset of things to called.
internal protocol SelectiveVisitor: Visitor {
  // Adds nothing.
}

/// Default impls for everything so things using this only have to write the
/// methods they expect.  Asserts to catch developer errors, but becomes
/// nothing in release to keep code size small.
///
/// NOTE: This is an impl for *everything*. This means the default impls
/// provided by Visitor to bridge packed->repeated, repeated->singular, etc
/// won't kick in.
extension SelectiveVisitor {
  internal mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularSInt32Field(value: Int32, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularSInt64Field(value: Int64, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularFixed64Field(value: UInt64, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularSFixed64Field(value: Int64, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedMessageField<M: Message>(value: [M], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedFloatField(value: [Float], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedDoubleField(value: [Double], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedBoolField(value: [Bool], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitMapField<KeyType, ValueType: MapValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: _ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where ValueType.RawValue == Int {
    assert(false)
  }

  internal mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    assert(false)
  }

  internal mutating func visitExtensionFields(fields: ExtensionFieldValueSet, start: Int, end: Int) throws {
    assert(false)
  }

  internal mutating func visitExtensionFieldsAsMessageSet(
    fields: ExtensionFieldValueSet,
    start: Int,
    end: Int
  ) throws {
    assert(false)
  }

  internal mutating func visitUnknown(bytes: Data) throws {
    assert(false)
  }
}
