// Sources/SwiftProtobuf/TextFormatDecoder.swift - Text format decoding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test format decoding engine.
///
// -----------------------------------------------------------------------------

import Foundation

///
/// Provides a higher-level interface to the token stream coming
/// from a TextFormatScanner.  In particular, this provides
/// single-token pushback and convenience functions for iterating
/// over complex structures.
///
internal struct TextFormatDecoder: Decoder {
    internal var scanner: TextFormatScanner
    private var fieldCount = 0
    private var terminator: UInt8?
    private var fieldNameMap: _NameMap?
    private var messageType: Message.Type?

    internal var complete: Bool {
        mutating get {
            return scanner.complete
        }
    }

    internal init(messageType: Message.Type, utf8Pointer: UnsafeRawPointer, count: Int, extensions: ExtensionMap?) throws {
        scanner = TextFormatScanner(utf8Pointer: utf8Pointer, count: count, extensions: extensions)
        guard let nameProviding = (messageType as? _ProtoNameProviding.Type) else {
            throw TextFormatDecodingError.missingFieldNames
        }
        fieldNameMap = nameProviding._protobuf_nameMap
        self.messageType = messageType
    }

    internal init(messageType: Message.Type, scanner: TextFormatScanner, terminator: UInt8?) throws {
        self.scanner = scanner
        self.terminator = terminator
        guard let nameProviding = (messageType as? _ProtoNameProviding.Type) else {
            throw TextFormatDecodingError.missingFieldNames
        }
        fieldNameMap = nameProviding._protobuf_nameMap
        self.messageType = messageType
    }


    mutating func handleConflictingOneOf() throws {
        throw TextFormatDecodingError.conflictingOneOf
    }

    mutating func nextFieldNumber() throws -> Int? {
        if let terminator = terminator {
            if scanner.skipOptionalObjectEnd(terminator) {
                return nil
            }
        }
        if fieldCount > 0 {
            scanner.skipOptionalSeparator()
        }
        if let key = try scanner.nextOptionalExtensionKey() {
            // Extension key; look up in the extension registry
            if let fieldNumber = scanner.extensions?.fieldNumberForProto(messageType: messageType!, protoFieldName: key) {
                fieldCount += 1
                return fieldNumber
            } else {
                throw TextFormatDecodingError.unknownField
            }
        } else if let fieldNumber = try scanner.nextFieldNumber(names: fieldNameMap!) {
            fieldCount += 1
            return fieldNumber
        } else if terminator == nil {
            return nil
        } else {
            throw TextFormatDecodingError.truncated
        }

    }

    mutating func decodeSingularFloatField(value: inout Float) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextFloat()
    }
    mutating func decodeSingularFloatField(value: inout Float?) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextFloat()
    }
    mutating func decodeRepeatedFloatField(value: inout [Float]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextFloat()
                value.append(n)
            }
        } else {
            let n = try scanner.nextFloat()
            value.append(n)
        }
    }
    mutating func decodeSingularDoubleField(value: inout Double) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextDouble()
    }
    mutating func decodeSingularDoubleField(value: inout Double?) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextDouble()
    }
    mutating func decodeRepeatedDoubleField(value: inout [Double]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextDouble()
                value.append(n)
            }
        } else {
            let n = try scanner.nextDouble()
            value.append(n)
        }
    }
    mutating func decodeSingularInt32Field(value: inout Int32) throws {
        try scanner.skipRequiredColon()
        let n = try scanner.nextSInt()
        if n > Int64(Int32.max) || n < Int64(Int32.min) {
            throw TextFormatDecodingError.malformedNumber
        }
        value = Int32(truncatingIfNeeded: n)
    }
    mutating func decodeSingularInt32Field(value: inout Int32?) throws {
        try scanner.skipRequiredColon()
        let n = try scanner.nextSInt()
        if n > Int64(Int32.max) || n < Int64(Int32.min) {
            throw TextFormatDecodingError.malformedNumber
        }
        value = Int32(truncatingIfNeeded: n)
    }
    mutating func decodeRepeatedInt32Field(value: inout [Int32]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextSInt()
                if n > Int64(Int32.max) || n < Int64(Int32.min) {
                    throw TextFormatDecodingError.malformedNumber
                }
                value.append(Int32(truncatingIfNeeded: n))
            }
        } else {
            let n = try scanner.nextSInt()
            if n > Int64(Int32.max) || n < Int64(Int32.min) {
                throw TextFormatDecodingError.malformedNumber
            }
            value.append(Int32(truncatingIfNeeded: n))
        }
    }
    mutating func decodeSingularInt64Field(value: inout Int64) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextSInt()
    }
    mutating func decodeSingularInt64Field(value: inout Int64?) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextSInt()
    }
    mutating func decodeRepeatedInt64Field(value: inout [Int64]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextSInt()
                value.append(n)
            }
        } else {
            let n = try scanner.nextSInt()
            value.append(n)
        }
    }
    mutating func decodeSingularUInt32Field(value: inout UInt32) throws {
        try scanner.skipRequiredColon()
        let n = try scanner.nextUInt()
        if n > UInt64(UInt32.max) {
            throw TextFormatDecodingError.malformedNumber
        }
        value = UInt32(truncatingIfNeeded: n)
    }
    mutating func decodeSingularUInt32Field(value: inout UInt32?) throws {
        try scanner.skipRequiredColon()
        let n = try scanner.nextUInt()
        if n > UInt64(UInt32.max) {
            throw TextFormatDecodingError.malformedNumber
        }
        value = UInt32(truncatingIfNeeded: n)
    }
    mutating func decodeRepeatedUInt32Field(value: inout [UInt32]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextUInt()
                if n > UInt64(UInt32.max) {
                    throw TextFormatDecodingError.malformedNumber
                }
                value.append(UInt32(truncatingIfNeeded: n))
            }
        } else {
            let n = try scanner.nextUInt()
            if n > UInt64(UInt32.max) {
                throw TextFormatDecodingError.malformedNumber
            }
            value.append(UInt32(truncatingIfNeeded: n))
        }
    }
    mutating func decodeSingularUInt64Field(value: inout UInt64) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextUInt()
    }
    mutating func decodeSingularUInt64Field(value: inout UInt64?) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextUInt()
    }
    mutating func decodeRepeatedUInt64Field(value: inout [UInt64]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextUInt()
                value.append(n)
            }
        } else {
            let n = try scanner.nextUInt()
            value.append(n)
        }
    }
    mutating func decodeSingularSInt32Field(value: inout Int32) throws {
        try decodeSingularInt32Field(value: &value)
    }
    mutating func decodeSingularSInt32Field(value: inout Int32?) throws {
        try decodeSingularInt32Field(value: &value)
    }
    mutating func decodeRepeatedSInt32Field(value: inout [Int32]) throws {
        try decodeRepeatedInt32Field(value: &value)
    }
    mutating func decodeSingularSInt64Field(value: inout Int64) throws {
        try decodeSingularInt64Field(value: &value)
    }
    mutating func decodeSingularSInt64Field(value: inout Int64?) throws {
        try decodeSingularInt64Field(value: &value)
    }
    mutating func decodeRepeatedSInt64Field(value: inout [Int64]) throws {
        try decodeRepeatedInt64Field(value: &value)
    }
    mutating func decodeSingularFixed32Field(value: inout UInt32) throws {
        try decodeSingularUInt32Field(value: &value)
    }
    mutating func decodeSingularFixed32Field(value: inout UInt32?) throws {
        try decodeSingularUInt32Field(value: &value)
    }
    mutating func decodeRepeatedFixed32Field(value: inout [UInt32]) throws {
        try decodeRepeatedUInt32Field(value: &value)
    }
    mutating func decodeSingularFixed64Field(value: inout UInt64) throws {
        try decodeSingularUInt64Field(value: &value)
    }
    mutating func decodeSingularFixed64Field(value: inout UInt64?) throws {
        try decodeSingularUInt64Field(value: &value)
    }
    mutating func decodeRepeatedFixed64Field(value: inout [UInt64]) throws {
        try decodeRepeatedUInt64Field(value: &value)
    }
    mutating func decodeSingularSFixed32Field(value: inout Int32) throws {
        try decodeSingularInt32Field(value: &value)
    }
    mutating func decodeSingularSFixed32Field(value: inout Int32?) throws {
        try decodeSingularInt32Field(value: &value)
    }
    mutating func decodeRepeatedSFixed32Field(value: inout [Int32]) throws {
        try decodeRepeatedInt32Field(value: &value)
    }
    mutating func decodeSingularSFixed64Field(value: inout Int64) throws {
        try decodeSingularInt64Field(value: &value)
    }
    mutating func decodeSingularSFixed64Field(value: inout Int64?) throws {
        try decodeSingularInt64Field(value: &value)
    }
    mutating func decodeRepeatedSFixed64Field(value: inout [Int64]) throws {
        try decodeRepeatedInt64Field(value: &value)
    }
    mutating func decodeSingularBoolField(value: inout Bool) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextBool()
    }
    mutating func decodeSingularBoolField(value: inout Bool?) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextBool()
    }
    mutating func decodeRepeatedBoolField(value: inout [Bool]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextBool()
                value.append(n)
            }
        } else {
            let n = try scanner.nextBool()
            value.append(n)
        }
    }
    mutating func decodeSingularStringField(value: inout String) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextStringValue()
    }
    mutating func decodeSingularStringField(value: inout String?) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextStringValue()
    }
    mutating func decodeRepeatedStringField(value: inout [String]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextStringValue()
                value.append(n)
            }
        } else {
            let n = try scanner.nextStringValue()
            value.append(n)
        }
    }
    mutating func decodeSingularBytesField(value: inout Data) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextBytesValue()
    }
    mutating func decodeSingularBytesField(value: inout Data?) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextBytesValue()
    }
    mutating func decodeRepeatedBytesField(value: inout [Data]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextBytesValue()
                value.append(n)
            }
        } else {
            let n = try scanner.nextBytesValue()
            value.append(n)
        }
    }

    private mutating func decodeEnum<E: Enum>() throws -> E where E.RawValue == Int {
        if let name = try scanner.nextOptionalEnumName() {
            if let b = E(rawUTF8: name) {
                return b
            } else {
                throw TextFormatDecodingError.unrecognizedEnumValue
            }
        }
        let number = try scanner.nextSInt()
        if number >= Int64(Int32.min) && number <= Int64(Int32.max) {
            let n = Int32(truncatingIfNeeded: number)
            if let e = E(rawValue: Int(n)) {
                return e
            } else {
                throw TextFormatDecodingError.unrecognizedEnumValue
            }
        }
        throw TextFormatDecodingError.malformedText

    }

    mutating func decodeSingularEnumField<E: Enum>(value: inout E?) throws where E.RawValue == Int {
        try scanner.skipRequiredColon()
        let e: E = try decodeEnum()
        value = e
    }

    mutating func decodeSingularEnumField<E: Enum>(value: inout E) throws where E.RawValue == Int {
        try scanner.skipRequiredColon()
        let e: E = try decodeEnum()
        value = e
    }

    mutating func decodeRepeatedEnumField<E: Enum>(value: inout [E]) throws where E.RawValue == Int {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let e: E = try decodeEnum()
                value.append(e)
            }
        } else {
            let e: E = try decodeEnum()
            value.append(e)
        }
    }

    mutating func decodeSingularMessageField<M: Message>(value: inout M?) throws {
        _ = scanner.skipOptionalColon()
        if value == nil {
            value = M()
        }
        let terminator = try scanner.skipObjectStart()
        var subDecoder = try TextFormatDecoder(messageType: M.self,scanner: scanner, terminator: terminator)
        if M.self == Google_Protobuf_Any.self {
            var any = value as! Google_Protobuf_Any?
            try any!.decodeTextFormat(decoder: &subDecoder)
            value = any as! M?
        } else {
            try value!.decodeMessage(decoder: &subDecoder)
        }
        scanner = subDecoder.scanner
    }

    mutating func decodeRepeatedMessageField<M: Message>(value: inout [M]) throws {
        _ = scanner.skipOptionalColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let terminator = try scanner.skipObjectStart()
                var subDecoder = try TextFormatDecoder(messageType: M.self,scanner: scanner, terminator: terminator)
                if M.self == Google_Protobuf_Any.self {
                    var message = Google_Protobuf_Any()
                    try message.decodeTextFormat(decoder: &subDecoder)
                    value.append(message as! M)
                } else {
                    var message = M()
                    try message.decodeMessage(decoder: &subDecoder)
                    value.append(message)
                }
                scanner = subDecoder.scanner
            }
        } else {
            let terminator = try scanner.skipObjectStart()
            var subDecoder = try TextFormatDecoder(messageType: M.self,scanner: scanner, terminator: terminator)
            if M.self == Google_Protobuf_Any.self {
                var message = Google_Protobuf_Any()
                try message.decodeTextFormat(decoder: &subDecoder)
                value.append(message as! M)
            } else {
                var message = M()
                try message.decodeMessage(decoder: &subDecoder)
                value.append(message)
            }
            scanner = subDecoder.scanner
        }
    }

    mutating func decodeSingularGroupField<G: Message>(value: inout G?) throws {
        try decodeSingularMessageField(value: &value)
    }

    mutating func decodeRepeatedGroupField<G: Message>(value: inout [G]) throws {
        try decodeRepeatedMessageField(value: &value)
    }

    private mutating func decodeMapEntry<KeyType, ValueType: MapValueType>(mapType: _ProtobufMap<KeyType, ValueType>.Type, value: inout _ProtobufMap<KeyType, ValueType>.BaseType) throws {
        var keyField: KeyType.BaseType?
        var valueField: ValueType.BaseType?
        let terminator = try scanner.skipObjectStart()
        while true {
            if scanner.skipOptionalObjectEnd(terminator) {
                if let keyField = keyField, let valueField = valueField {
                    value[keyField] = valueField
                    return
                } else {
                    throw TextFormatDecodingError.malformedText
                }
            }
            if let key = try scanner.nextKey() {
                switch key {
                case "key", "1":
                    try KeyType.decodeSingular(value: &keyField, from: &self)
                case "value", "2":
                    try ValueType.decodeSingular(value: &valueField, from: &self)
                default:
                    throw TextFormatDecodingError.unknownField
                }
                scanner.skipOptionalSeparator()
            }
        }
    }

    mutating func decodeMapField<KeyType, ValueType: MapValueType>(fieldType: _ProtobufMap<KeyType, ValueType>.Type, value: inout _ProtobufMap<KeyType, ValueType>.BaseType) throws {
        _ = scanner.skipOptionalColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                try decodeMapEntry(mapType: fieldType, value: &value)
            }
        } else {
            try decodeMapEntry(mapType: fieldType, value: &value)
        }
    }

    private mutating func decodeMapEntry<KeyType, ValueType>(mapType: _ProtobufEnumMap<KeyType, ValueType>.Type, value: inout _ProtobufEnumMap<KeyType, ValueType>.BaseType) throws where ValueType.RawValue == Int {
        var keyField: KeyType.BaseType?
        var valueField: ValueType?
        let terminator = try scanner.skipObjectStart()
        while true {
            if scanner.skipOptionalObjectEnd(terminator) {
                if let keyField = keyField, let valueField = valueField {
                    value[keyField] = valueField
                    return
                } else {
                    throw TextFormatDecodingError.malformedText
                }
            }
            if let key = try scanner.nextKey() {
                switch key {
                case "key", "1":
                    try KeyType.decodeSingular(value: &keyField, from: &self)
                case "value", "2":
                    try decodeSingularEnumField(value: &valueField)
                default:
                    throw TextFormatDecodingError.unknownField
                }
                scanner.skipOptionalSeparator()
            }
        }
    }

    mutating func decodeMapField<KeyType, ValueType>(fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type, value: inout _ProtobufEnumMap<KeyType, ValueType>.BaseType) throws where ValueType.RawValue == Int {
        _ = scanner.skipOptionalColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                try decodeMapEntry(mapType: fieldType, value: &value)
            }
        } else {
            try decodeMapEntry(mapType: fieldType, value: &value)
        }
    }

    private mutating func decodeMapEntry<KeyType, ValueType>(mapType: _ProtobufMessageMap<KeyType, ValueType>.Type, value: inout _ProtobufMessageMap<KeyType, ValueType>.BaseType) throws {
        var keyField: KeyType.BaseType?
        var valueField: ValueType?
        let terminator = try scanner.skipObjectStart()
        while true {
            if scanner.skipOptionalObjectEnd(terminator) {
                if let keyField = keyField, let valueField = valueField {
                    value[keyField] = valueField
                    return
                } else {
                    throw TextFormatDecodingError.malformedText
                }
            }
            if let key = try scanner.nextKey() {
                switch key {
                case "key", "1":
                    try KeyType.decodeSingular(value: &keyField, from: &self)
                case "value", "2":
                    try decodeSingularMessageField(value: &valueField)
                default:
                    throw TextFormatDecodingError.unknownField
                }
                scanner.skipOptionalSeparator()
            }
        }
    }

    mutating func decodeMapField<KeyType, ValueType>(fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type, value: inout _ProtobufMessageMap<KeyType, ValueType>.BaseType) throws {
        _ = scanner.skipOptionalColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                try decodeMapEntry(mapType: fieldType, value: &value)
            }
        } else {
            try decodeMapEntry(mapType: fieldType, value: &value)
        }
    }

    mutating func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, fieldNumber: Int) throws {
        if let ext = scanner.extensions?[messageType, fieldNumber] {
            var fieldValue = values[fieldNumber]
            if fieldValue != nil {
                try fieldValue!.decodeExtensionField(decoder: &self)
            } else {
                fieldValue = try ext._protobuf_newField(decoder: &self)
            }
            if fieldValue != nil {
                values[fieldNumber] = fieldValue
            } else {
                // Really things should never get here, for TextFormat, decoding
                // the value should always work or throw an error.  This specific
                // error result is to allow this to be more detectable.
                throw TextFormatDecodingError.internalExtensionError
            }
        }
    }
}
