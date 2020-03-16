// Sources/SwiftProtobuf/ProtobufMap.swift - Map<> support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Generic type representing proto map<> fields.
///
// -----------------------------------------------------------------------------

import Foundation

/// SwiftProtobuf Internal: Support for Encoding/Decoding.
public struct _ProtobufMap<KeyType: MapKeyType, ValueType: FieldType>
{
    public typealias Key = KeyType.BaseType
    public typealias Value = ValueType.BaseType
    public typealias BaseType = Dictionary<Key, Value>
}

/// SwiftProtobuf Internal: Support for Encoding/Decoding.
public struct _ProtobufMessageMap<KeyType: MapKeyType, ValueType: Message & Hashable>
{
    public typealias Key = KeyType.BaseType
    public typealias Value = ValueType
    public typealias BaseType = Dictionary<Key, Value>
}

/// SwiftProtobuf Internal: Support for Encoding/Decoding.
public struct _ProtobufEnumMap<KeyType: MapKeyType, ValueType: Enum>
{
    public typealias Key = KeyType.BaseType
    public typealias Value = ValueType
    public typealias BaseType = Dictionary<Key, Value>
}
