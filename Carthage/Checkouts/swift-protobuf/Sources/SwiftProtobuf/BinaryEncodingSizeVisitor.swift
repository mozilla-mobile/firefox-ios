// Sources/SwiftProtobuf/BinaryEncodingSizeVisitor.swift - Binary size calculation support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Visitor used during binary encoding that precalcuates the size of a
/// serialized message.
///
// -----------------------------------------------------------------------------

import Foundation

/// Visitor that calculates the binary-encoded size of a message so that a
/// properly sized `Data` or `UInt8` array can be pre-allocated before
/// serialization.
internal struct BinaryEncodingSizeVisitor: Visitor {

  /// Accumulates the required size of the message during traversal.
  var serializedSize: Int = 0

  init() {}

  mutating func visitUnknown(bytes: Data) throws {
    serializedSize += bytes.count
  }

  mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed32).encodedSize
    serializedSize += tagSize + MemoryLayout<Float>.size
  }

  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed64).encodedSize
    serializedSize += tagSize + MemoryLayout<Double>.size
  }

  mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws {
    try visitSingularInt64Field(value: Int64(value), fieldNumber: fieldNumber)
  }

  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint).encodedSize
    serializedSize += tagSize + Varint.encodedSize(of: value)
  }

  mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws {
    try visitSingularUInt64Field(value: UInt64(value), fieldNumber: fieldNumber)
  }

  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint).encodedSize
    serializedSize += tagSize + Varint.encodedSize(of: value)
  }

  mutating func visitSingularSInt32Field(value: Int32, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint).encodedSize
    serializedSize += tagSize + Varint.encodedSize(of: ZigZag.encoded(value))
  }

  mutating func visitSingularSInt64Field(value: Int64, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint).encodedSize
    serializedSize += tagSize + Varint.encodedSize(of: ZigZag.encoded(value))
  }

  mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed32).encodedSize
    serializedSize += tagSize + MemoryLayout<UInt32>.size
  }

  mutating func visitSingularFixed64Field(value: UInt64, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed64).encodedSize
    serializedSize += tagSize + MemoryLayout<UInt64>.size
  }

  mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed32).encodedSize
    serializedSize += tagSize + MemoryLayout<Int32>.size
  }

  mutating func visitSingularSFixed64Field(value: Int64, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed64).encodedSize
    serializedSize += tagSize + MemoryLayout<Int64>.size
  }

  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint).encodedSize
    serializedSize += tagSize + 1
  }

  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let count = value.utf8.count
    serializedSize += tagSize + Varint.encodedSize(of: Int64(count)) + count
  }

  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let count = value.count
    serializedSize += tagSize + Varint.encodedSize(of: Int64(count)) + count
  }

  mutating func visitPackedFloatField(value: [Float], fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.count * MemoryLayout<Float>.size
    serializedSize += tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedDoubleField(value: [Double], fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.count * MemoryLayout<Double>.size
    serializedSize += tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedInt32Field(value: [Int32], fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    var dataSize = 0
    for v in value {
      dataSize += Varint.encodedSize(of: v)
    }
    serializedSize +=
      tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedInt64Field(value: [Int64], fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    var dataSize = 0
    for v in value {
      dataSize += Varint.encodedSize(of: v)
    }
    serializedSize +=
      tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    var dataSize = 0
    for v in value {
      dataSize += Varint.encodedSize(of: ZigZag.encoded(v))
    }
    serializedSize +=
      tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    var dataSize = 0
    for v in value {
      dataSize += Varint.encodedSize(of: ZigZag.encoded(v))
    }
    serializedSize +=
      tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    var dataSize = 0
    for v in value {
      dataSize += Varint.encodedSize(of: v)
    }
    serializedSize +=
      tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    var dataSize = 0
    for v in value {
      dataSize += Varint.encodedSize(of: v)
    }
    serializedSize +=
      tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.count * MemoryLayout<UInt32>.size
    serializedSize += tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.count * MemoryLayout<UInt64>.size
    serializedSize += tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.count * MemoryLayout<Int32>.size
    serializedSize += tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.count * MemoryLayout<Int64>.size
    serializedSize += tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedBoolField(value: [Bool], fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.count
    serializedSize += tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitSingularEnumField<E: Enum>(value: E,
                                       fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .varint).encodedSize
    serializedSize += tagSize
    let dataSize = Varint.encodedSize(of: Int32(truncatingIfNeeded: value.rawValue))
    serializedSize += dataSize
  }

  mutating func visitRepeatedEnumField<E: Enum>(value: [E],
                                       fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .varint).encodedSize
    serializedSize += value.count * tagSize
    for v in value {
      let dataSize = Varint.encodedSize(of: Int32(truncatingIfNeeded: v.rawValue))
      serializedSize += dataSize
    }
  }

  mutating func visitPackedEnumField<E: Enum>(value: [E],
                                     fieldNumber: Int) throws {
    guard !value.isEmpty else {
      return
    }

    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .varint).encodedSize
    serializedSize += tagSize
    var dataSize = 0
    for v in value {
      dataSize += Varint.encodedSize(of: Int32(truncatingIfNeeded: v.rawValue))
    }
    serializedSize += Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitSingularMessageField<M: Message>(value: M,
                                             fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .lengthDelimited).encodedSize
    let messageSize = try value.serializedDataSize()
    serializedSize +=
      tagSize + Varint.encodedSize(of: UInt64(messageSize)) + messageSize
  }

  mutating func visitRepeatedMessageField<M: Message>(value: [M],
                                             fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .lengthDelimited).encodedSize
    serializedSize += value.count * tagSize
    for v in value {
      let messageSize = try v.serializedDataSize()
      serializedSize +=
        Varint.encodedSize(of: UInt64(messageSize)) + messageSize
    }
  }

  mutating func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws {
    // The wire format doesn't matter here because the encoded size of the
    // integer won't change based on the low three bits.
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .startGroup).encodedSize
    serializedSize += 2 * tagSize
    try value.traverse(visitor: &self)
  }

  mutating func visitRepeatedGroupField<G: Message>(value: [G],
                                           fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .startGroup).encodedSize
    serializedSize += 2 * value.count * tagSize
    for v in value {
      try v.traverse(visitor: &self)
    }
  }

  mutating func visitMapField<KeyType, ValueType: MapValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: _ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .lengthDelimited).encodedSize
    for (k,v) in value {
        var sizer = BinaryEncodingSizeVisitor()
        try KeyType.visitSingular(value: k, fieldNumber: 1, with: &sizer)
        try ValueType.visitSingular(value: v, fieldNumber: 2, with: &sizer)
        let entrySize = sizer.serializedSize
        serializedSize += Varint.encodedSize(of: Int64(entrySize)) + entrySize
    }
    serializedSize += value.count * tagSize
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where ValueType.RawValue == Int {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .lengthDelimited).encodedSize
    for (k,v) in value {
        var sizer = BinaryEncodingSizeVisitor()
        try KeyType.visitSingular(value: k, fieldNumber: 1, with: &sizer)
        try sizer.visitSingularEnumField(value: v, fieldNumber: 2)
        let entrySize = sizer.serializedSize
        serializedSize += Varint.encodedSize(of: Int64(entrySize)) + entrySize
    }
    serializedSize += value.count * tagSize
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .lengthDelimited).encodedSize
    for (k,v) in value {
        var sizer = BinaryEncodingSizeVisitor()
        try KeyType.visitSingular(value: k, fieldNumber: 1, with: &sizer)
        try sizer.visitSingularMessageField(value: v, fieldNumber: 2)
        let entrySize = sizer.serializedSize
        serializedSize += Varint.encodedSize(of: Int64(entrySize)) + entrySize
    }
    serializedSize += value.count * tagSize
  }

  mutating func visitExtensionFieldsAsMessageSet(
    fields: ExtensionFieldValueSet,
    start: Int,
    end: Int
  ) throws {
    var sizer = BinaryEncodingMessageSetSizeVisitor()
    try fields.traverse(visitor: &sizer, start: start, end: end)
    serializedSize += sizer.serializedSize
  }
}

extension BinaryEncodingSizeVisitor {

  // Helper Visitor to compute the sizes when writing out the extensions as MessageSets.
  internal struct BinaryEncodingMessageSetSizeVisitor: SelectiveVisitor {
    var serializedSize: Int = 0

    init() {}

    mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
      var groupSize = WireFormat.MessageSet.itemTagsEncodedSize

      groupSize += Varint.encodedSize(of: Int32(fieldNumber))

      let messageSize = try value.serializedDataSize()
      groupSize += Varint.encodedSize(of: UInt64(messageSize)) + messageSize

      serializedSize += groupSize
    }

    // SelectiveVisitor handles the rest.
  }

}
