// Sources/SwiftProtobuf/HashVisitor.swift - Hashing support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Hashing is basically a serialization problem, so we can leverage the
/// generated traversal methods for that.
///
// -----------------------------------------------------------------------------

import Foundation

private let i_2166136261 = Int(bitPattern: 2166136261)
private let i_16777619 = Int(16777619)

/// Computes the hash of a message by visiting its fields recursively.
///
/// Note that because this visits every field, it has the potential to be slow
/// for large or deeply nested messages. Users who need to use such messages as
/// dictionary keys or set members can use a wrapper struct around the message
/// and use a custom Hashable implementation that looks at the subset of the
/// message fields they want to include.
internal struct HashVisitor: Visitor {

#if swift(>=4.2)
  internal private(set) var hasher: Hasher
#else  // swift(>=4.2)
  // Roughly based on FNV hash: http://tools.ietf.org/html/draft-eastlake-fnv-03
  private(set) var hashValue = i_2166136261

  private mutating func mix(_ hash: Int) {
    hashValue = (hashValue ^ hash) &* i_16777619
  }

  private mutating func mixMap<K, V: Hashable>(map: Dictionary<K,V>) {
    var mapHash = 0
    for (k, v) in map {
      // Note: This calculation cannot depend on the order of the items.
      mapHash = mapHash &+ (k.hashValue ^ v.hashValue)
    }
    mix(mapHash)
  }
#endif // swift(>=4.2)

#if swift(>=4.2)
  init(_ hasher: Hasher) {
    self.hasher = hasher
  }
#else
  init() {}
#endif

  mutating func visitUnknown(bytes: Data) throws {
    #if swift(>=4.2)
      hasher.combine(bytes)
    #else
      mix(bytes.hashValue)
    #endif
  }

  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mix(value.hashValue)
   #endif
  }

  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mix(value.hashValue)
    #endif
  }

  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mix(value.hashValue)
    #endif
  }

  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mix(value.hashValue)
    #endif
  }

  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mix(value.hashValue)
    #endif
  }

  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mix(value.hashValue)
    #endif
  }

  mutating func visitSingularEnumField<E: Enum>(value: E,
                                                fieldNumber: Int) {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mix(value.hashValue)
    #endif
  }

  mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      value.hash(into: &hasher)
    #else
      mix(fieldNumber)
      mix(value.hashValue)
    #endif
  }

  mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedMessageField<M: Message>(value: [M], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      for v in value {
        v.hash(into: &hasher)
      }
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      for v in value {
        v.hash(into: &hasher)
      }
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitMapField<KeyType, ValueType: MapValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: _ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mixMap(map: value)
    #endif
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where ValueType.RawValue == Int {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mixMap(map: value)
    #endif
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mixMap(map: value)
    #endif
  }
}
