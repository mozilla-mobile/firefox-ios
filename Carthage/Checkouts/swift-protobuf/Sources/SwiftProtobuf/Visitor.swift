// Sources/SwiftProtobuf/Visitor.swift - Basic serialization machinery
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Protocol for traversing the object tree.
///
/// This is used by:
/// = Protobuf serialization
/// = JSON serialization (with some twists to account for specialty JSON
///   encodings)
/// = Protobuf text serialization
/// = Hashable computation
///
/// Conceptually, serializers create visitor objects that are
/// then passed recursively to every message and field via generated
/// 'traverse' methods.  The details get a little involved due to
/// the need to allow particular messages to override particular
/// behaviors for specific encodings, but the general idea is quite simple.
///
// -----------------------------------------------------------------------------

import Foundation

/// This is the key interface used by the generated `traverse()` methods
/// used for serialization.  It is implemented by each serialization protocol:
/// Protobuf Binary, Protobuf Text, JSON, and the Hash encoder.
public protocol Visitor {

  /// Called for each non-repeated float field
  ///
  /// A default implementation is provided that just widens the value
  /// and calls `visitSingularDoubleField`
  mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws

  /// Called for each non-repeated double field
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws

  /// Called for each non-repeated int32 field
  ///
  /// A default implementation is provided that just widens the value
  /// and calls `visitSingularInt64Field`
  mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws

  /// Called for each non-repeated int64 field
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws

  /// Called for each non-repeated uint32 field
  ///
  /// A default implementation is provided that just widens the value
  /// and calls `visitSingularUInt64Field`
  mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws

  /// Called for each non-repeated uint64 field
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws

  /// Called for each non-repeated sint32 field
  ///
  /// A default implementation is provided that just forwards to
  /// `visitSingularInt32Field`
  mutating func visitSingularSInt32Field(value: Int32, fieldNumber: Int) throws

  /// Called for each non-repeated sint64 field
  ///
  /// A default implementation is provided that just forwards to
  /// `visitSingularInt64Field`
  mutating func visitSingularSInt64Field(value: Int64, fieldNumber: Int) throws

  /// Called for each non-repeated fixed32 field
  ///
  /// A default implementation is provided that just forwards to
  /// `visitSingularUInt32Field`
  mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws

  /// Called for each non-repeated fixed64 field
  ///
  /// A default implementation is provided that just forwards to
  /// `visitSingularUInt64Field`
  mutating func visitSingularFixed64Field(value: UInt64, fieldNumber: Int) throws

  /// Called for each non-repeated sfixed32 field
  ///
  /// A default implementation is provided that just forwards to
  /// `visitSingularInt32Field`
  mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws

  /// Called for each non-repeated sfixed64 field
  ///
  /// A default implementation is provided that just forwards to
  /// `visitSingularInt64Field`
  mutating func visitSingularSFixed64Field(value: Int64, fieldNumber: Int) throws

  /// Called for each non-repeated bool field
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws

  /// Called for each non-repeated string field
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws

  /// Called for each non-repeated bytes field
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws

  /// Called for each non-repeated enum field
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws

  /// Called for each non-repeated nested message field.
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws

  /// Called for each non-repeated proto2 group field.
  ///
  /// A default implementation is provided that simply forwards to
  /// `visitSingularMessageField`. Implementors who need to handle groups
  /// differently than nested messages can override this and provide distinct
  /// implementations.
  mutating func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws

  // Called for each non-packed repeated float field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularFloatField` once for each item in the array.
  mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws

  // Called for each non-packed repeated double field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularDoubleField` once for each item in the array.
  mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws

  // Called for each non-packed repeated int32 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularInt32Field` once for each item in the array.
  mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws

  // Called for each non-packed repeated int64 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularInt64Field` once for each item in the array.
  mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws

  // Called for each non-packed repeated uint32 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularUInt32Field` once for each item in the array.
  mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws

  // Called for each non-packed repeated uint64 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularUInt64Field` once for each item in the array.
  mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws

  // Called for each non-packed repeated sint32 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularSInt32Field` once for each item in the array.
  mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws

  // Called for each non-packed repeated sint64 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularSInt64Field` once for each item in the array.
  mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws

  // Called for each non-packed repeated fixed32 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularFixed32Field` once for each item in the array.
  mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws

  // Called for each non-packed repeated fixed64 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularFixed64Field` once for each item in the array.
  mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws

  // Called for each non-packed repeated sfixed32 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularSFixed32Field` once for each item in the array.
  mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws

  // Called for each non-packed repeated sfixed64 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularSFixed64Field` once for each item in the array.
  mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws

  // Called for each non-packed repeated bool field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularBoolField` once for each item in the array.
  mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws

  // Called for each non-packed repeated string field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularStringField` once for each item in the array.
  mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws

  // Called for each non-packed repeated bytes field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularBytesField` once for each item in the array.
  mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws

  /// Called for each repeated, unpacked enum field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularEnumField` once for each item in the array.
  mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws

  /// Called for each repeated nested message field. The method is called once
  /// with the complete array of values for the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularMessageField` once for each item in the array.
  mutating func visitRepeatedMessageField<M: Message>(value: [M],
                                                      fieldNumber: Int) throws

  /// Called for each repeated proto2 group field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularGroupField` once for each item in the array.
  mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws

  // Called for each packed, repeated float field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedFloatField(value: [Float], fieldNumber: Int) throws

  // Called for each packed, repeated double field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedDoubleField(value: [Double], fieldNumber: Int) throws

  // Called for each packed, repeated int32 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedInt32Field(value: [Int32], fieldNumber: Int) throws

  // Called for each packed, repeated int64 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedInt64Field(value: [Int64], fieldNumber: Int) throws

  // Called for each packed, repeated uint32 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedUInt32Field(value: [UInt32], fieldNumber: Int) throws

  // Called for each packed, repeated uint64 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedUInt64Field(value: [UInt64], fieldNumber: Int) throws

  // Called for each packed, repeated sint32 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedSInt32Field(value: [Int32], fieldNumber: Int) throws

  // Called for each packed, repeated sint64 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedSInt64Field(value: [Int64], fieldNumber: Int) throws

  // Called for each packed, repeated fixed32 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedFixed32Field(value: [UInt32], fieldNumber: Int) throws

  // Called for each packed, repeated fixed64 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedFixed64Field(value: [UInt64], fieldNumber: Int) throws

  // Called for each packed, repeated sfixed32 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedSFixed32Field(value: [Int32], fieldNumber: Int) throws

  // Called for each packed, repeated sfixed64 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedSFixed64Field(value: [Int64], fieldNumber: Int) throws

  // Called for each packed, repeated bool field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedBoolField(value: [Bool], fieldNumber: Int) throws

  /// Called for each repeated, packed enum field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply forwards to
  /// `visitRepeatedEnumField`. Implementors who need to handle packed fields
  /// differently than unpacked fields can override this and provide distinct
  /// implementations.
  mutating func visitPackedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws

  /// Called for each map field with primitive values. The method is
  /// called once with the complete dictionary of keys/values for the
  /// field.
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitMapField<KeyType, ValueType: MapValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: _ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int) throws

  /// Called for each map field with enum values. The method is called
  /// once with the complete dictionary of keys/values for the field.
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int) throws where ValueType.RawValue == Int

  /// Called for each map field with message values. The method is
  /// called once with the complete dictionary of keys/values for the
  /// field.
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int) throws

  /// Called for each extension range.
  mutating func visitExtensionFields(fields: ExtensionFieldValueSet, start: Int, end: Int) throws

  /// Called for each extension range.
  mutating func visitExtensionFieldsAsMessageSet(
    fields: ExtensionFieldValueSet,
    start: Int,
    end: Int) throws

  /// Called with the raw bytes that represent any unknown fields.
  mutating func visitUnknown(bytes: Data) throws
}

/// Forwarding default implementations of some visitor methods, for convenience.
extension Visitor {

  // Default definitions of numeric serializations.
  //
  // The 32-bit versions widen and delegate to 64-bit versions.
  // The specialized integer codings delegate to standard Int/UInt.
  //
  // These "just work" for Hash and Text formats.  Most of these work
  // for JSON (32-bit integers are overridden to suppress quoting),
  // and a few even work for Protobuf Binary (thanks to varint coding
  // which erases the size difference between 32-bit and 64-bit ints).

  public mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws {
    try visitSingularDoubleField(value: Double(value), fieldNumber: fieldNumber)
  }
  public mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws {
    try visitSingularInt64Field(value: Int64(value), fieldNumber: fieldNumber)
  }
  public mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws {
    try visitSingularUInt64Field(value: UInt64(value), fieldNumber: fieldNumber)
  }
  public mutating func visitSingularSInt32Field(value: Int32, fieldNumber: Int) throws {
    try visitSingularInt32Field(value: value, fieldNumber: fieldNumber)
  }
  public mutating func visitSingularSInt64Field(value: Int64, fieldNumber: Int) throws {
    try visitSingularInt64Field(value: value, fieldNumber: fieldNumber)
  }
  public mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws {
    try visitSingularUInt32Field(value: value, fieldNumber: fieldNumber)
  }
  public mutating func visitSingularFixed64Field(value: UInt64, fieldNumber: Int) throws {
    try visitSingularUInt64Field(value: value, fieldNumber: fieldNumber)
  }
  public mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws {
    try visitSingularInt32Field(value: value, fieldNumber: fieldNumber)
  }
  public mutating func visitSingularSFixed64Field(value: Int64, fieldNumber: Int) throws {
    try visitSingularInt64Field(value: value, fieldNumber: fieldNumber)
  }

  // Default definitions of repeated serializations that just iterate and
  // invoke the singular encoding.  These "just work" for Protobuf Binary (encoder
  // and size visitor), Protobuf Text, and Hash visitors.  JSON format stores
  // repeated values differently from singular, so overrides these.

  public mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
    for v in value {
      try visitSingularFloatField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
    for v in value {
      try visitSingularDoubleField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
    for v in value {
      try visitSingularInt32Field(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
    for v in value {
      try visitSingularInt64Field(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    for v in value {
      try visitSingularUInt32Field(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    for v in value {
      try visitSingularUInt64Field(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {
      for v in value {
          try visitSingularSInt32Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {
      for v in value {
          try visitSingularSInt64Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
      for v in value {
          try visitSingularFixed32Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
      for v in value {
          try visitSingularFixed64Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
      for v in value {
          try visitSingularSFixed32Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
      for v in value {
          try visitSingularSFixed64Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {
    for v in value {
      try visitSingularBoolField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
    for v in value {
      try visitSingularStringField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
    for v in value {
      try visitSingularBytesField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
    for v in value {
        try visitSingularEnumField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedMessageField<M: Message>(value: [M], fieldNumber: Int) throws {
    for v in value {
      try visitSingularMessageField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws {
    for v in value {
      try visitSingularGroupField(value: v, fieldNumber: fieldNumber)
    }
  }

  // Default definitions of packed serialization just defer to the
  // repeated implementation.  This works for Hash and JSON visitors
  // (which do not distinguish packed vs. non-packed) but are
  // overridden by Protobuf Binary and Text.

  public mutating func visitPackedFloatField(value: [Float], fieldNumber: Int) throws {
    try visitRepeatedFloatField(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedDoubleField(value: [Double], fieldNumber: Int) throws {
    try visitRepeatedDoubleField(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedInt32Field(value: [Int32], fieldNumber: Int) throws {
    try visitRepeatedInt32Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedInt64Field(value: [Int64], fieldNumber: Int) throws {
    try visitRepeatedInt64Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    try visitRepeatedUInt32Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    try visitRepeatedUInt64Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    try visitPackedInt32Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    try visitPackedInt64Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    try visitPackedUInt32Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    try visitPackedUInt64Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    try visitPackedInt32Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    try visitPackedInt64Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedBoolField(value: [Bool], fieldNumber: Int) throws {
    try visitRepeatedBoolField(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedEnumField<E: Enum>(value: [E],
                                            fieldNumber: Int) throws {
    try visitRepeatedEnumField(value: value, fieldNumber: fieldNumber)
  }

  // Default handling for Groups is to treat them just like messages.
  // This works for Text and Hash, but is overridden by Protobuf Binary
  // format (which has a different encoding for groups) and JSON
  // (which explicitly ignores all groups).

  public mutating func visitSingularGroupField<G: Message>(value: G,
                                                  fieldNumber: Int) throws {
    try visitSingularMessageField(value: value, fieldNumber: fieldNumber)
  }

  // Default handling of Extensions as a MessageSet to handing them just
  // as plain extensions. Formats that what custom behavior can override
  // it.

  public mutating func visitExtensionFieldsAsMessageSet(
    fields: ExtensionFieldValueSet,
    start: Int,
    end: Int) throws {
    try visitExtensionFields(fields: fields, start: start, end: end)
  }

  // Default handling for Extensions is to forward the traverse to
  // the ExtensionFieldValueSet. Formats that don't care about extensions
  // can override to avoid it.

  /// Called for each extension range.
  public mutating func visitExtensionFields(fields: ExtensionFieldValueSet, start: Int, end: Int) throws {
    try fields.traverse(visitor: &self, start: start, end: end)
  }
}
