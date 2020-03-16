// Sources/SwiftProtobuf/JSONMapEncodingVisitor.swift - JSON map encoding visitor
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Visitor that writes out the key/value pairs for a JSON map.
///
// -----------------------------------------------------------------------------

import Foundation

/// Visitor that serializes a message into JSON map format.
///
/// This expects to alternately visit the keys and values for a JSON
/// map.  It only accepts singular values.  Keys should be identified
/// as `fieldNumber:1`, values should be identified as `fieldNumber:2`
///
internal struct JSONMapEncodingVisitor: SelectiveVisitor {
  private var separator: StaticString?
  internal var encoder: JSONEncoder
  private let options: JSONEncodingOptions

  init(encoder: JSONEncoder, options: JSONEncodingOptions) {
      self.encoder = encoder
      self.options = options
  }

  private mutating func startKey() {
      if let s = separator {
          encoder.append(staticText: s)
      } else {
          separator = ","
      }
  }

  private mutating func startValue() {
      encoder.append(staticText: ":")
  }

  mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws {
      // Doubles/Floats can never be map keys, only values
      assert(fieldNumber == 2)
      startValue()
      encoder.putFloatValue(value: value)
  }

  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
      // Doubles/Floats can never be map keys, only values
      assert(fieldNumber == 2)
      startValue()
      encoder.putDoubleValue(value: value)
  }

  mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws {
      if fieldNumber == 1 {
          startKey()
          encoder.putQuotedInt32(value: value)
      } else {
          startValue()
          encoder.putInt32(value: value)
      }
  }

  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
      if fieldNumber == 1 {
          startKey()
      } else {
          startValue()
      }
      // Int64 fields are always quoted anyway
      encoder.putInt64(value: value)
  }

  mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws {
      if fieldNumber == 1 {
          startKey()
          encoder.putQuotedUInt32(value: value)
      } else {
          startValue()
          encoder.putUInt32(value: value)
      }
  }

  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
      if fieldNumber == 1 {
          startKey()
      } else {
          startValue()
      }
      encoder.putUInt64(value: value)
  }

  mutating func visitSingularSInt32Field(value: Int32, fieldNumber: Int) throws {
      try visitSingularInt32Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitSingularSInt64Field(value: Int64, fieldNumber: Int) throws {
      try visitSingularInt64Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws {
      try visitSingularUInt32Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitSingularFixed64Field(value: UInt64, fieldNumber: Int) throws {
      try visitSingularUInt64Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws {
      try visitSingularInt32Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitSingularSFixed64Field(value: Int64, fieldNumber: Int) throws {
      try visitSingularInt64Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
      if fieldNumber == 1 {
          startKey()
          encoder.putQuotedBoolValue(value: value)
      } else {
          startValue()
          encoder.putBoolValue(value: value)
      }
  }

  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
      if fieldNumber == 1 {
          startKey()
      } else {
          startValue()
      }
      encoder.putStringValue(value: value)
  }

  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
      // Bytes can only be map values, never keys
      assert(fieldNumber == 2)
      startValue()
      encoder.putBytesValue(value: value)
  }

  mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws {
      // Enums can only be map values, never keys
      assert(fieldNumber == 2)
      startValue()
      if !options.alwaysPrintEnumsAsInts, let n = value.name {
          encoder.putStringValue(value: String(describing: n))
      } else {
          encoder.putEnumInt(value: value.rawValue)
      }
  }

  mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
      // Messages can only be map values, never keys
      assert(fieldNumber == 2)
      startValue()
      let json = try value.jsonString(options: options)
      encoder.append(text: json)
  }

  // SelectiveVisitor will block:
  // - single Groups
  // - everything repeated
  // - everything packed
  // - all maps
  // - unknown fields
  // - extensions
}
