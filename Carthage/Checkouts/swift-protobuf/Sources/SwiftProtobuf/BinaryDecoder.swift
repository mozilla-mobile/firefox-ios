// Sources/SwiftProtobuf/BinaryDecoder.swift - Binary decoding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Protobuf binary format decoding engine.
///
/// This provides the Decoder interface that interacts directly
/// with the generated code.
///
// -----------------------------------------------------------------------------

import Foundation

internal struct BinaryDecoder: Decoder {
    // Current position
    private var p : UnsafeRawPointer
    // Remaining bytes in input.
    private var available : Int
    // Position of start of field currently being parsed
    private var fieldStartP : UnsafeRawPointer
    // Position of end of field currently being parsed, nil if we don't know.
    private var fieldEndP : UnsafeRawPointer?
    // Whether or not the field value  has actually been parsed
    private var consumed = true
    // Wire format for last-examined field
    internal var fieldWireFormat = WireFormat.varint
    // Field number for last-parsed field tag
    private var fieldNumber: Int = 0
    // Collection of extension fields for this decode
    private var extensions: ExtensionMap?
    // The current group number. See decodeFullGroup(group:fieldNumber:) for how
    // this is used.
    private var groupFieldNumber: Int?
    // The options for decoding.
    private var options: BinaryDecodingOptions

    private var recursionBudget: Int

    // Collects the unknown data found while decoding a message.
    private var unknownData: Data?
    // Custom data to use as the unknown data while parsing a field. Used only by
    // packed repeated enums; see below
    private var unknownOverride: Data?

    private var complete: Bool {return available == 0}

    internal init(
      forReadingFrom pointer: UnsafeRawPointer,
      count: Int,
      options: BinaryDecodingOptions,
      extensions: ExtensionMap? = nil
    ) {
        // Assuming baseAddress is not nil.
        p = pointer
        available = count
        fieldStartP = p
        self.extensions = extensions
        self.options = options
        recursionBudget = options.messageDepthLimit
    }

    internal init(
      forReadingFrom pointer: UnsafeRawPointer,
      count: Int,
      parent: BinaryDecoder
    ) {
      self.init(forReadingFrom: pointer,
                count: count,
                options: parent.options,
                extensions: parent.extensions)
      recursionBudget = parent.recursionBudget
    }

    private mutating func incrementRecursionDepth() throws {
        recursionBudget -= 1
        if recursionBudget < 0 {
            throw BinaryDecodingError.messageDepthLimit
        }
    }

    private mutating func decrementRecursionDepth() {
        recursionBudget += 1
        // This should never happen, if it does, something is probably corrupting memory, and
        // simply throwing doesn't make much sense.
        if recursionBudget > options.messageDepthLimit {
            fatalError("Somehow BinaryDecoding unwound more objects than it started")
        }
    }

    internal mutating func handleConflictingOneOf() throws {
        /// Protobuf simply allows conflicting oneof values to overwrite
    }

    /// Return the next field number or nil if there are no more fields.
    internal mutating func nextFieldNumber() throws -> Int? {
        // Since this is called for every field, I've taken some pains
        // to optimize it, including unrolling a tweaked version of
        // the varint parser.
        if fieldNumber > 0 {
            if let override = unknownOverride {
                assert(!options.discardUnknownFields)
                assert(fieldWireFormat != .startGroup && fieldWireFormat != .endGroup)
                if unknownData == nil {
                    unknownData = override
                } else {
                    unknownData!.append(override)
                }
                unknownOverride = nil
            } else if !consumed {
                if options.discardUnknownFields {
                    try skip()
                } else {
                    let u = try getRawField()
                    if unknownData == nil {
                        unknownData = u
                    } else {
                        unknownData!.append(u)
                    }
                }
            }
        }

        // Quit if end of input
        if available == 0 {
            return nil
        }

        // Get the next field number
        fieldStartP = p
        fieldEndP = nil
        let start = p
        let c0 = start[0]
        if let wireFormat = WireFormat(rawValue: c0 & 7) {
            fieldWireFormat = wireFormat
        } else {
            throw BinaryDecodingError.malformedProtobuf
        }
        if (c0 & 0x80) == 0 {
            p += 1
            available -= 1
            fieldNumber = Int(c0) >> 3
        } else {
            fieldNumber = Int(c0 & 0x7f) >> 3
            if available < 2 {
                throw BinaryDecodingError.malformedProtobuf
            }
            let c1 = start[1]
            if (c1 & 0x80) == 0 {
                p += 2
                available -= 2
                fieldNumber |= Int(c1) << 4
            } else {
                fieldNumber |= Int(c1 & 0x7f) << 4
                if available < 3 {
                    throw BinaryDecodingError.malformedProtobuf
                }
                let c2 = start[2]
                fieldNumber |= Int(c2 & 0x7f) << 11
                if (c2 & 0x80) == 0 {
                    p += 3
                    available -= 3
                } else {
                    if available < 4 {
                        throw BinaryDecodingError.malformedProtobuf
                    }
                    let c3 = start[3]
                    fieldNumber |= Int(c3 & 0x7f) << 18
                    if (c3 & 0x80) == 0 {
                        p += 4
                        available -= 4
                    } else {
                        if available < 5 {
                            throw BinaryDecodingError.malformedProtobuf
                        }
                        let c4 = start[4]
                        if c4 > 15 {
                            throw BinaryDecodingError.malformedProtobuf
                        }
                        fieldNumber |= Int(c4 & 0x7f) << 25
                        p += 5
                        available -= 5
                    }
                }
            }
        }
        if fieldNumber != 0 {
            consumed = false

            if fieldWireFormat == .endGroup {
                if groupFieldNumber == fieldNumber {
                    // Reached the end of the current group, single the
                    // end of the message.
                    return nil
                } else {
                    // .endGroup when not in a group or for a different
                    // group is an invalid binary.
                    throw BinaryDecodingError.malformedProtobuf
                }
            }
            return fieldNumber
        }
        throw BinaryDecodingError.malformedProtobuf
    }

    internal mutating func decodeSingularFloatField(value: inout Float) throws {
        guard fieldWireFormat == WireFormat.fixed32 else {
            return
        }
        try decodeFourByteNumber(value: &value)
        consumed = true
    }

    internal mutating func decodeSingularFloatField(value: inout Float?) throws {
        guard fieldWireFormat == WireFormat.fixed32 else {
            return
        }
        value = try decodeFloat()
        consumed = true
    }

    internal mutating func decodeRepeatedFloatField(value: inout [Float]) throws {
        switch fieldWireFormat {
        case WireFormat.fixed32:
            let i = try decodeFloat()
            value.append(i)
            consumed = true
        case WireFormat.lengthDelimited:
            let bodyBytes = try decodeVarint()
            if bodyBytes > 0 {
                let itemSize = UInt64(MemoryLayout<Float>.size)
                let itemCount = bodyBytes / itemSize
                if bodyBytes % itemSize != 0 || itemCount > UInt64(Int.max) {
                    throw BinaryDecodingError.truncated
                }
                value.reserveCapacity(value.count + Int(truncatingIfNeeded: itemCount))
                for _ in 1...itemCount {
                    value.append(try decodeFloat())
                }
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularDoubleField(value: inout Double) throws {
        guard fieldWireFormat == WireFormat.fixed64 else {
            return
        }
        value = try decodeDouble()
        consumed = true
    }

    internal mutating func decodeSingularDoubleField(value: inout Double?) throws {
        guard fieldWireFormat == WireFormat.fixed64 else {
            return
        }
        value = try decodeDouble()
        consumed = true
    }

    internal mutating func decodeRepeatedDoubleField(value: inout [Double]) throws {
        switch fieldWireFormat {
        case WireFormat.fixed64:
            let i = try decodeDouble()
            value.append(i)
            consumed = true
        case WireFormat.lengthDelimited:
            let bodyBytes = try decodeVarint()
            if bodyBytes > 0 {
                let itemSize = UInt64(MemoryLayout<Double>.size)
                let itemCount = bodyBytes / itemSize
                if bodyBytes % itemSize != 0 || itemCount > UInt64(Int.max) {
                    throw BinaryDecodingError.truncated
                }
                value.reserveCapacity(value.count + Int(truncatingIfNeeded: itemCount))
                for _ in 1...itemCount {
                    let i = try decodeDouble()
                    value.append(i)
                }
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularInt32Field(value: inout Int32) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        value = Int32(truncatingIfNeeded: varint)
        consumed = true
    }

    internal mutating func decodeSingularInt32Field(value: inout Int32?) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        value = Int32(truncatingIfNeeded: varint)
        consumed = true
    }

    internal mutating func decodeRepeatedInt32Field(value: inout [Int32]) throws {
        switch fieldWireFormat {
        case WireFormat.varint:
            let varint = try decodeVarint()
            value.append(Int32(truncatingIfNeeded: varint))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            let ints = Varint.countVarintsInBuffer(start: p, count: n)
            value.reserveCapacity(value.count + ints)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            while !decoder.complete {
                let varint = try decoder.decodeVarint()
                value.append(Int32(truncatingIfNeeded: varint))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularInt64Field(value: inout Int64) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let v = try decodeVarint()
        value = Int64(bitPattern: v)
        consumed = true
    }

    internal mutating func decodeSingularInt64Field(value: inout Int64?) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        value = Int64(bitPattern: varint)
        consumed = true
    }

    internal mutating func decodeRepeatedInt64Field(value: inout [Int64]) throws {
        switch fieldWireFormat {
        case WireFormat.varint:
            let varint = try decodeVarint()
            value.append(Int64(bitPattern: varint))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            let ints = Varint.countVarintsInBuffer(start: p, count: n)
            value.reserveCapacity(value.count + ints)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            while !decoder.complete {
                let varint = try decoder.decodeVarint()
                value.append(Int64(bitPattern: varint))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularUInt32Field(value: inout UInt32) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        value = UInt32(truncatingIfNeeded: varint)
        consumed = true
    }

    internal mutating func decodeSingularUInt32Field(value: inout UInt32?) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        value = UInt32(truncatingIfNeeded: varint)
        consumed = true
    }

    internal mutating func decodeRepeatedUInt32Field(value: inout [UInt32]) throws {
        switch fieldWireFormat {
        case WireFormat.varint:
            let varint = try decodeVarint()
            value.append(UInt32(truncatingIfNeeded: varint))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            let ints = Varint.countVarintsInBuffer(start: p, count: n)
            value.reserveCapacity(value.count + ints)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            while !decoder.complete {
                let t = try decoder.decodeVarint()
                value.append(UInt32(truncatingIfNeeded: t))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularUInt64Field(value: inout UInt64) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        value = try decodeVarint()
        consumed = true
    }

    internal mutating func decodeSingularUInt64Field(value: inout UInt64?) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        value = try decodeVarint()
        consumed = true
    }

    internal mutating func decodeRepeatedUInt64Field(value: inout [UInt64]) throws {
        switch fieldWireFormat {
        case WireFormat.varint:
            let varint = try decodeVarint()
            value.append(varint)
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            let ints = Varint.countVarintsInBuffer(start: p, count: n)
            value.reserveCapacity(value.count + ints)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            while !decoder.complete {
                let t = try decoder.decodeVarint()
                value.append(t)
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularSInt32Field(value: inout Int32) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        let t = UInt32(truncatingIfNeeded: varint)
        value = ZigZag.decoded(t)
        consumed = true
    }

    internal mutating func decodeSingularSInt32Field(value: inout Int32?) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        let t = UInt32(truncatingIfNeeded: varint)
        value = ZigZag.decoded(t)
        consumed = true
    }

    internal mutating func decodeRepeatedSInt32Field(value: inout [Int32]) throws {
        switch fieldWireFormat {
        case WireFormat.varint:
            let varint = try decodeVarint()
            let t = UInt32(truncatingIfNeeded: varint)
            value.append(ZigZag.decoded(t))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            let ints = Varint.countVarintsInBuffer(start: p, count: n)
            value.reserveCapacity(value.count + ints)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            while !decoder.complete {
                let varint = try decoder.decodeVarint()
                let t = UInt32(truncatingIfNeeded: varint)
                value.append(ZigZag.decoded(t))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularSInt64Field(value: inout Int64) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        value = ZigZag.decoded(varint)
        consumed = true
    }

    internal mutating func decodeSingularSInt64Field(value: inout Int64?) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        value = ZigZag.decoded(varint)
        consumed = true
    }

    internal mutating func decodeRepeatedSInt64Field(value: inout [Int64]) throws {
        switch fieldWireFormat {
        case WireFormat.varint:
            let varint = try decodeVarint()
            value.append(ZigZag.decoded(varint))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            let ints = Varint.countVarintsInBuffer(start: p, count: n)
            value.reserveCapacity(value.count + ints)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            while !decoder.complete {
                let varint = try decoder.decodeVarint()
                value.append(ZigZag.decoded(varint))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularFixed32Field(value: inout UInt32) throws {
        guard fieldWireFormat == WireFormat.fixed32 else {
            return
        }
        var i: UInt32 = 0
        try decodeFourByteNumber(value: &i)
        value = UInt32(littleEndian: i)
        consumed = true
    }

    internal mutating func decodeSingularFixed32Field(value: inout UInt32?) throws {
        guard fieldWireFormat == WireFormat.fixed32 else {
            return
        }
        var i: UInt32 = 0
        try decodeFourByteNumber(value: &i)
        value = UInt32(littleEndian: i)
        consumed = true
    }

    internal mutating func decodeRepeatedFixed32Field(value: inout [UInt32]) throws {
        switch fieldWireFormat {
        case WireFormat.fixed32:
            var i: UInt32 = 0
            try decodeFourByteNumber(value: &i)
            value.append(UInt32(littleEndian: i))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<UInt32>.size)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            var i: UInt32 = 0
            while !decoder.complete {
                try decoder.decodeFourByteNumber(value: &i)
                value.append(UInt32(littleEndian: i))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularFixed64Field(value: inout UInt64) throws {
        guard fieldWireFormat == WireFormat.fixed64 else {
            return
        }
        var i: UInt64 = 0
        try decodeEightByteNumber(value: &i)
        value = UInt64(littleEndian: i)
        consumed = true
    }

    internal mutating func decodeSingularFixed64Field(value: inout UInt64?) throws {
        guard fieldWireFormat == WireFormat.fixed64 else {
            return
        }
        var i: UInt64 = 0
        try decodeEightByteNumber(value: &i)
        value = UInt64(littleEndian: i)
        consumed = true
    }

    internal mutating func decodeRepeatedFixed64Field(value: inout [UInt64]) throws {
        switch fieldWireFormat {
        case WireFormat.fixed64:
            var i: UInt64 = 0
            try decodeEightByteNumber(value: &i)
            value.append(UInt64(littleEndian: i))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<UInt64>.size)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            var i: UInt64 = 0
            while !decoder.complete {
                try decoder.decodeEightByteNumber(value: &i)
                value.append(UInt64(littleEndian: i))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularSFixed32Field(value: inout Int32) throws {
        guard fieldWireFormat == WireFormat.fixed32 else {
            return
        }
        var i: Int32 = 0
        try decodeFourByteNumber(value: &i)
        value = Int32(littleEndian: i)
        consumed = true
    }

    internal mutating func decodeSingularSFixed32Field(value: inout Int32?) throws {
        guard fieldWireFormat == WireFormat.fixed32 else {
            return
        }
        var i: Int32 = 0
        try decodeFourByteNumber(value: &i)
        value = Int32(littleEndian: i)
        consumed = true
    }

    internal mutating func decodeRepeatedSFixed32Field(value: inout [Int32]) throws {
        switch fieldWireFormat {
        case WireFormat.fixed32:
            var i: Int32 = 0
            try decodeFourByteNumber(value: &i)
            value.append(Int32(littleEndian: i))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<Int32>.size)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            var i: Int32 = 0
            while !decoder.complete {
                try decoder.decodeFourByteNumber(value: &i)
                value.append(Int32(littleEndian: i))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularSFixed64Field(value: inout Int64) throws {
        guard fieldWireFormat == WireFormat.fixed64 else {
            return
        }
        var i: Int64 = 0
        try decodeEightByteNumber(value: &i)
        value = Int64(littleEndian: i)
        consumed = true
    }

    internal mutating func decodeSingularSFixed64Field(value: inout Int64?) throws {
        guard fieldWireFormat == WireFormat.fixed64 else {
            return
        }
        var i: Int64 = 0
        try decodeEightByteNumber(value: &i)
        value = Int64(littleEndian: i)
        consumed = true
    }

    internal mutating func decodeRepeatedSFixed64Field(value: inout [Int64]) throws {
        switch fieldWireFormat {
        case WireFormat.fixed64:
            var i: Int64 = 0
            try decodeEightByteNumber(value: &i)
            value.append(Int64(littleEndian: i))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<Int64>.size)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            var i: Int64 = 0
            while !decoder.complete {
                try decoder.decodeEightByteNumber(value: &i)
                value.append(Int64(littleEndian: i))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularBoolField(value: inout Bool) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        value = try decodeVarint() != 0
        consumed = true
    }

    internal mutating func decodeSingularBoolField(value: inout Bool?) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        value = try decodeVarint() != 0
        consumed = true
    }

    internal mutating func decodeRepeatedBoolField(value: inout [Bool]) throws {
        switch fieldWireFormat {
        case WireFormat.varint:
            let varint = try decodeVarint()
            value.append(varint != 0)
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            let ints = Varint.countVarintsInBuffer(start: p, count: n)
            value.reserveCapacity(value.count + ints)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            while !decoder.complete {
                let t = try decoder.decodeVarint()
                value.append(t != 0)
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularStringField(value: inout String) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var n: Int = 0
        let p = try getFieldBodyBytes(count: &n)
        if let s = utf8ToString(bytes: p, count: n) {
            value = s
            consumed = true
        } else {
            throw BinaryDecodingError.invalidUTF8
        }
    }

    internal mutating func decodeSingularStringField(value: inout String?) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var n: Int = 0
        let p = try getFieldBodyBytes(count: &n)
        if let s = utf8ToString(bytes: p, count: n) {
            value = s
            consumed = true
        } else {
            throw BinaryDecodingError.invalidUTF8
        }
    }

    internal mutating func decodeRepeatedStringField(value: inout [String]) throws {
        switch fieldWireFormat {
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            if let s = utf8ToString(bytes: p, count: n) {
                value.append(s)
                consumed = true
            } else {
                throw BinaryDecodingError.invalidUTF8
            }
        default:
            return
        }
    }

    internal mutating func decodeSingularBytesField(value: inout Data) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var n: Int = 0
        let p = try getFieldBodyBytes(count: &n)
        value = Data(bytes: p, count: n)
        consumed = true
    }

    internal mutating func decodeSingularBytesField(value: inout Data?) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var n: Int = 0
        let p = try getFieldBodyBytes(count: &n)
        value = Data(bytes: p, count: n)
        consumed = true
    }

    internal mutating func decodeRepeatedBytesField(value: inout [Data]) throws {
        switch fieldWireFormat {
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            value.append(Data(bytes: p, count: n))
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularEnumField<E: Enum>(value: inout E?) throws where E.RawValue == Int {
        guard fieldWireFormat == WireFormat.varint else {
             return
         }
        let varint = try decodeVarint()
        if let v = E(rawValue: Int(Int32(truncatingIfNeeded: varint))) {
            value = v
            consumed = true
        }
     }

    internal mutating func decodeSingularEnumField<E: Enum>(value: inout E) throws where E.RawValue == Int {
        guard fieldWireFormat == WireFormat.varint else {
             return
        }
        let varint = try decodeVarint()
        if let v = E(rawValue: Int(Int32(truncatingIfNeeded: varint))) {
            value = v
            consumed = true
        }
    }

    internal mutating func decodeRepeatedEnumField<E: Enum>(value: inout [E]) throws where E.RawValue == Int {
        switch fieldWireFormat {
        case WireFormat.varint:
            let varint = try decodeVarint()
            if let v = E(rawValue: Int(Int32(truncatingIfNeeded: varint))) {
                value.append(v)
                consumed = true
            }
        case WireFormat.lengthDelimited:
            var n: Int = 0
            var extras: [Int32]?
            let p = try getFieldBodyBytes(count: &n)
            let ints = Varint.countVarintsInBuffer(start: p, count: n)
            value.reserveCapacity(value.count + ints)
            var subdecoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            while !subdecoder.complete {
                let u64 = try subdecoder.decodeVarint()
                let i32 = Int32(truncatingIfNeeded: u64)
                if let v = E(rawValue: Int(i32)) {
                    value.append(v)
                } else if !options.discardUnknownFields {
                    if extras == nil {
                        extras = []
                    }
                    extras!.append(i32)
                }
            }
            if let extras = extras {
                let fieldTag = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
                var bodySize = 0
                for v in extras {
                    bodySize += Varint.encodedSize(of: Int64(v))
                }
                let fieldSize = Varint.encodedSize(of: fieldTag.rawValue) + Varint.encodedSize(of: Int64(bodySize)) + bodySize
                var field = Data(count: fieldSize)
                field.withUnsafeMutableBytes { (body: UnsafeMutableRawBufferPointer) in
                  if let baseAddress = body.baseAddress, body.count > 0 {
                    var encoder = BinaryEncoder(forWritingInto: baseAddress)
                    encoder.startField(tag: fieldTag)
                    encoder.putVarInt(value: Int64(bodySize))
                    for v in extras {
                        encoder.putVarInt(value: Int64(v))
                    }
                  }
                }
                unknownOverride = field
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularMessageField<M: Message>(value: inout M?) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var count: Int = 0
        let p = try getFieldBodyBytes(count: &count)
        if value == nil {
            value = M()
        }
        var subDecoder = BinaryDecoder(forReadingFrom: p, count: count, parent: self)
        try subDecoder.decodeFullMessage(message: &value!)
        consumed = true
    }

    internal mutating func decodeRepeatedMessageField<M: Message>(value: inout [M]) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var count: Int = 0
        let p = try getFieldBodyBytes(count: &count)
        var newValue = M()
        var subDecoder = BinaryDecoder(forReadingFrom: p, count: count, parent: self)
        try subDecoder.decodeFullMessage(message: &newValue)
        value.append(newValue)
        consumed = true
    }

    internal mutating func decodeFullMessage<M: Message>(message: inout M) throws {
      try incrementRecursionDepth()
      try message.decodeMessage(decoder: &self)
      decrementRecursionDepth()
      guard complete else {
        throw BinaryDecodingError.trailingGarbage
      }
      if let unknownData = unknownData {
        message.unknownFields.append(protobufData: unknownData)
      }
    }

    internal mutating func decodeSingularGroupField<G: Message>(value: inout G?) throws {
        var group = value ?? G()
        if try decodeFullGroup(group: &group, fieldNumber: fieldNumber) {
            value = group
            consumed = true
        }
    }

    internal mutating func decodeRepeatedGroupField<G: Message>(value: inout [G]) throws {
        var group = G()
        if try decodeFullGroup(group: &group, fieldNumber: fieldNumber) {
            value.append(group)
            consumed = true
        }
    }

    private mutating func decodeFullGroup<G: Message>(group: inout G, fieldNumber: Int) throws -> Bool {
        guard fieldWireFormat == WireFormat.startGroup else {
            return false
        }
        assert(unknownData == nil)

        try incrementRecursionDepth()

        // This works by making a clone of the current decoder state and
        // setting `groupFieldNumber` to signal `nextFieldNumber()` to watch
        // for that as a marker for having reached the end of a group/message.
        // Groups within groups works because this effectively makes a stack
        // of decoders, each one looking for their ending tag.

        var subDecoder = self
        subDecoder.groupFieldNumber = fieldNumber
        // startGroup was read, so current tag/data is done (otherwise the
        // startTag will end up in the unknowns of the first thing decoded).
        subDecoder.consumed = true
        try group.decodeMessage(decoder: &subDecoder)
        guard subDecoder.fieldNumber == fieldNumber && subDecoder.fieldWireFormat == .endGroup else {
            throw BinaryDecodingError.truncated
        }
        if let groupUnknowns = subDecoder.unknownData {
            group.unknownFields.append(protobufData: groupUnknowns)
        }
        // Advance over what was parsed.
        consume(length: available - subDecoder.available)
        assert(recursionBudget == subDecoder.recursionBudget)
        decrementRecursionDepth()
        return true
    }

    internal mutating func decodeMapField<KeyType, ValueType: MapValueType>(fieldType: _ProtobufMap<KeyType, ValueType>.Type, value: inout _ProtobufMap<KeyType, ValueType>.BaseType) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var k: KeyType.BaseType?
        var v: ValueType.BaseType?
        var count: Int = 0
        let p = try getFieldBodyBytes(count: &count)
        var subdecoder = BinaryDecoder(forReadingFrom: p, count: count, parent: self)
        while let tag = try subdecoder.getTag() {
            if tag.wireFormat == .endGroup {
                throw BinaryDecodingError.malformedProtobuf
            }
            let fieldNumber = tag.fieldNumber
            switch fieldNumber {
            case 1:
                try KeyType.decodeSingular(value: &k, from: &subdecoder)
            case 2:
                try ValueType.decodeSingular(value: &v, from: &subdecoder)
            default: // Skip any other fields within the map entry object
                try subdecoder.skip()
            }
        }
        if !subdecoder.complete {
            throw BinaryDecodingError.trailingGarbage
        }
        // A map<> definition can't provide a default value for the keys/values,
        // so it is safe to use the proto3 default to get the right
        // integer/string/bytes. The one catch is a proto2 enum (which can be the
        // value) can have a non zero value, but that case is the next
        // custom decodeMapField<>() method and handles it.
        value[k ?? KeyType.proto3DefaultValue] = v ?? ValueType.proto3DefaultValue
        consumed = true
    }

    internal mutating func decodeMapField<KeyType, ValueType>(fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type, value: inout _ProtobufEnumMap<KeyType, ValueType>.BaseType) throws where ValueType.RawValue == Int {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var k: KeyType.BaseType?
        var v: ValueType?
        var count: Int = 0
        let p = try getFieldBodyBytes(count: &count)
        var subdecoder = BinaryDecoder(forReadingFrom: p, count: count, parent: self)
        while let tag = try subdecoder.getTag() {
            if tag.wireFormat == .endGroup {
                throw BinaryDecodingError.malformedProtobuf
            }
            let fieldNumber = tag.fieldNumber
            switch fieldNumber {
            case 1: // Keys are basic types
                try KeyType.decodeSingular(value: &k, from: &subdecoder)
            case 2: // Value is an Enum type
                try subdecoder.decodeSingularEnumField(value: &v)
                if v == nil && tag.wireFormat == .varint {
                    // Enum decode fail and wire format was varint, so this had to
                    // have been a proto2 unknown enum value. This whole map entry
                    // into the parent message's unknown fields. If the wire format
                    // was wrong, treat it like an unknown field and drop it with
                    // the map entry.
                    return
                }
            default: // Skip any other fields within the map entry object
                try subdecoder.skip()
            }
        }
        if !subdecoder.complete {
            throw BinaryDecodingError.trailingGarbage
        }
        // A map<> definition can't provide a default value for the keys, so it
        // is safe to use the proto3 default to get the right integer/string/bytes.
        value[k ?? KeyType.proto3DefaultValue] = v ?? ValueType()
        consumed = true
    }

    internal mutating func decodeMapField<KeyType, ValueType>(fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type, value: inout _ProtobufMessageMap<KeyType, ValueType>.BaseType) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var k: KeyType.BaseType?
        var v: ValueType?
        var count: Int = 0
        let p = try getFieldBodyBytes(count: &count)
        var subdecoder = BinaryDecoder(forReadingFrom: p, count: count, parent: self)
        while let tag = try subdecoder.getTag() {
            if tag.wireFormat == .endGroup {
                throw BinaryDecodingError.malformedProtobuf
            }
            let fieldNumber = tag.fieldNumber
            switch fieldNumber {
            case 1: // Keys are basic types
                try KeyType.decodeSingular(value: &k, from: &subdecoder)
            case 2: // Value is a message type
                try subdecoder.decodeSingularMessageField(value: &v)
            default: // Skip any other fields within the map entry object
                try subdecoder.skip()
            }
        }
        if !subdecoder.complete {
            throw BinaryDecodingError.trailingGarbage
        }
        // A map<> definition can't provide a default value for the keys, so it
        // is safe to use the proto3 default to get the right integer/string/bytes.
        value[k ?? KeyType.proto3DefaultValue] = v ?? ValueType()
        consumed = true
    }

    internal mutating func decodeExtensionField(
      values: inout ExtensionFieldValueSet,
      messageType: Message.Type,
      fieldNumber: Int
    ) throws {
        if let ext = extensions?[messageType, fieldNumber] {
            try decodeExtensionField(values: &values,
                                     messageType: messageType,
                                     fieldNumber: fieldNumber,
                                     messageExtension: ext)
        }
    }

    /// Helper to reuse between Extension decoding and MessageSet Extension decoding.
    private mutating func decodeExtensionField(
      values: inout ExtensionFieldValueSet,
      messageType: Message.Type,
      fieldNumber: Int,
      messageExtension ext: AnyMessageExtension
    ) throws {
        assert(!consumed)
        assert(fieldNumber == ext.fieldNumber)
        var fieldValue = values[fieldNumber]
        // Message/Group extensions both will call back into the matching
        // decode methods, so the recursion depth will be tracked there.
        if fieldValue != nil {
            try fieldValue!.decodeExtensionField(decoder: &self)
        } else {
            fieldValue = try ext._protobuf_newField(decoder: &self)
        }
        if consumed {
            if fieldValue != nil {
                values[fieldNumber] = fieldValue
            } else {
                // Really things should never get here, if the decoder says
                // the bytes were consumed, then there should have been a
                // field that consumed them (existing or created). This
                // specific error result is to allow this to be more detectable.
                throw BinaryDecodingError.internalExtensionError
            }
        }
    }

    internal mutating func decodeExtensionFieldsAsMessageSet(
      values: inout ExtensionFieldValueSet,
      messageType: Message.Type
    ) throws {
        // Spin looking for the Item group, everything else will end up in unknown fields.
        while let fieldNumber = try self.nextFieldNumber() {
            guard fieldNumber == WireFormat.MessageSet.FieldNumbers.item &&
              fieldWireFormat == WireFormat.startGroup else {
                continue
            }

            // This is similiar to decodeFullGroup

            try incrementRecursionDepth()
            var subDecoder = self
            subDecoder.groupFieldNumber = fieldNumber
            subDecoder.consumed = true

            let itemResult = try subDecoder.decodeMessageSetItem(values: &values,
                                                                 messageType: messageType)
            switch itemResult {
            case .success:
              // Advance over what was parsed.
              consume(length: available - subDecoder.available)
              consumed = true
            case .handleAsUnknown:
              // Nothing to do.
              break

            case .malformed:
              throw BinaryDecodingError.malformedProtobuf
            }

            assert(recursionBudget == subDecoder.recursionBudget)
            decrementRecursionDepth()
        }
    }

    private enum DecodeMessageSetItemResult {
      case success
      case handleAsUnknown
      case malformed
    }

    private mutating func decodeMessageSetItem(
      values: inout ExtensionFieldValueSet,
      messageType: Message.Type
    ) throws -> DecodeMessageSetItemResult {
        // This is loosely based on the C++:
        //   ExtensionSet::ParseMessageSetItem()
        //   WireFormat::ParseAndMergeMessageSetItem()
        // (yes, there have two versions that are almost the same)

        var msgExtension: AnyMessageExtension?
        var fieldData: Data?

        // In this loop, if wire types are wrong, things don't decode,
        // just bail instead of letting things go into unknown fields.
        // Wrongly formed MessageSets don't seem don't have real
        // spelled out behaviors.
        while let fieldNumber = try self.nextFieldNumber() {
            switch fieldNumber {
            case WireFormat.MessageSet.FieldNumbers.typeId:
                var extensionFieldNumber: Int32 = 0
                try decodeSingularInt32Field(value: &extensionFieldNumber)
                if extensionFieldNumber == 0 { return .malformed }
                guard let ext = extensions?[messageType, Int(extensionFieldNumber)] else {
                    return .handleAsUnknown  // Unknown extension.
                }
                msgExtension = ext

                // If there already was fieldData, decode it.
                if let data = fieldData {
                    var wasDecoded = false
                    try data.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
                      if let baseAddress = body.baseAddress, body.count > 0 {
                        var extDecoder = BinaryDecoder(forReadingFrom: baseAddress,
                                                       count: body.count,
                                                       parent: self)
                        // Prime the decode to be correct.
                        extDecoder.consumed = false
                        extDecoder.fieldWireFormat = .lengthDelimited
                        try extDecoder.decodeExtensionField(values: &values,
                                                            messageType: messageType,
                                                            fieldNumber: fieldNumber,
                                                            messageExtension: ext)
                        wasDecoded = extDecoder.consumed
                      }
                    }
                    if !wasDecoded {
                        return .malformed
                    }
                    fieldData = nil
                }

            case WireFormat.MessageSet.FieldNumbers.message:
                if let ext = msgExtension {
                    assert(consumed == false)
                    try decodeExtensionField(values: &values,
                                             messageType: messageType,
                                             fieldNumber: ext.fieldNumber,
                                             messageExtension: ext)
                    if !consumed {
                        return .malformed
                    }
                } else {
                    // The C++ references ends up appending the blocks together as length
                    // delimited blocks, but the parsing will only use the first block.
                    // So just capture a block, and then skip any others that happen to
                    // be found.
                    if fieldData == nil {
                        var d: Data?
                        try decodeSingularBytesField(value: &d)
                        guard let data = d else { return .malformed }
                        // Save it as length delimited
                        let payloadSize = Varint.encodedSize(of: Int64(data.count)) + data.count
                        var payload = Data(count: payloadSize)
                        payload.withUnsafeMutableBytes { (body: UnsafeMutableRawBufferPointer) in
                          if let baseAddress = body.baseAddress, body.count > 0 {
                            var encoder = BinaryEncoder(forWritingInto: baseAddress)
                            encoder.putBytesValue(value: data)
                          }
                        }
                        fieldData = payload
                    } else {
                        guard fieldWireFormat == .lengthDelimited else { return .malformed }
                        try skip()
                        consumed = true
                    }
                }

            default:
                // Skip everything else
                try skip()
                consumed = true
            }
        }

        return .success
    }

    //
    // Private building blocks for the parsing above.
    //
    // Having these be private gives the compiler maximum latitude for
    // inlining.
    //

    /// Private:  Advance the current position.
    private mutating func consume(length: Int) {
        available -= length
        p += length
    }

    /// Private: Skip the body for the given tag.  If the given tag is
    /// a group, it parses up through the corresponding group end.
    private mutating func skipOver(tag: FieldTag) throws {
        switch tag.wireFormat {
        case .varint:
            if available < 1 {
                throw BinaryDecodingError.truncated
            }
            var c = p.load(fromByteOffset: 0, as: UInt8.self)
            while (c & 0x80) != 0 {
                p += 1
                available -= 1
                if available < 1 {
                    throw BinaryDecodingError.truncated
                }
                c = p.load(fromByteOffset: 0, as: UInt8.self)
            }
            p += 1
            available -= 1
        case .fixed64:
            if available < 8 {
                throw BinaryDecodingError.truncated
            }
            p += 8
            available -= 8
        case .lengthDelimited:
            let n = try decodeVarint()
            if n <= UInt64(available) {
                p += Int(n)
                available -= Int(n)
            } else {
                throw BinaryDecodingError.truncated
            }
        case .startGroup:
            try incrementRecursionDepth()
            while true {
                if let innerTag = try getTagWithoutUpdatingFieldStart() {
                    if innerTag.wireFormat == .endGroup {
                        if innerTag.fieldNumber == tag.fieldNumber {
                            decrementRecursionDepth()
                            break
                        } else {
                            // .endGroup for a something other than the current
                            // group is an invalid binary.
                            throw BinaryDecodingError.malformedProtobuf
                        }
                    } else {
                        try skipOver(tag: innerTag)
                    }
                } else {
                    throw BinaryDecodingError.truncated
                }
            }
        case .endGroup:
            throw BinaryDecodingError.malformedProtobuf
        case .fixed32:
            if available < 4 {
                throw BinaryDecodingError.truncated
            }
            p += 4
            available -= 4
        }
    }

    /// Private: Skip to the end of the current field.
    ///
    /// Assumes that fieldStartP was bookmarked by a previous
    /// call to getTagType().
    ///
    /// On exit, fieldStartP points to the first byte of the tag, fieldEndP points
    /// to the first byte after the field contents, and p == fieldEndP.
    private mutating func skip() throws {
        if let end = fieldEndP {
            p = end
        } else {
            // Rewind to start of current field.
            available += p - fieldStartP
            p = fieldStartP
            guard let tag = try getTagWithoutUpdatingFieldStart() else {
                throw BinaryDecodingError.truncated
            }
            try skipOver(tag: tag)
            fieldEndP = p
        }
    }

    /// Private: Parse the next raw varint from the input.
    private mutating func decodeVarint() throws -> UInt64 {
        if available < 1 {
            throw BinaryDecodingError.truncated
        }
        var start = p
        var length = available
        var c = start.load(fromByteOffset: 0, as: UInt8.self)
        start += 1
        length -= 1
        if c & 0x80 == 0 {
            p = start
            available = length
            return UInt64(c)
        }
        var value = UInt64(c & 0x7f)
        var shift = UInt64(7)
        while true {
            if length < 1 || shift > 63 {
                throw BinaryDecodingError.malformedProtobuf
            }
            c = start.load(fromByteOffset: 0, as: UInt8.self)
            start += 1
            length -= 1
            value |= UInt64(c & 0x7f) << shift
            if c & 0x80 == 0 {
                p = start
                available = length
                return value
            }
            shift += 7
        }
    }

    /// Private: Get the tag that starts a new field.
    /// This also bookmarks the start of field for a possible skip().
    internal mutating func getTag() throws -> FieldTag? {
        fieldStartP = p
        fieldEndP = nil
        return try getTagWithoutUpdatingFieldStart()
    }

    /// Private: Parse and validate the next tag without
    /// bookmarking the start of the field.  This is used within
    /// skip() to skip over fields within a group.
    private mutating func getTagWithoutUpdatingFieldStart() throws -> FieldTag? {
        if available < 1 {
            return nil
        }
        let t = try decodeVarint()
        if t < UInt64(UInt32.max) {
            guard let tag = FieldTag(rawValue: UInt32(truncatingIfNeeded: t)) else {
                throw BinaryDecodingError.malformedProtobuf
            }
            fieldWireFormat = tag.wireFormat
            fieldNumber = tag.fieldNumber
            return tag
        } else {
            throw BinaryDecodingError.malformedProtobuf
        }
    }

    /// Private: Return a Data containing the entirety of
    /// the current field, including tag.
    private mutating func getRawField() throws -> Data {
        try skip()
        return Data(bytes: fieldStartP, count: fieldEndP! - fieldStartP)
    }

    /// Private: decode a fixed-length four-byte number.  This generic
    /// helper handles all four-byte number types.
    private mutating func decodeFourByteNumber<T>(value: inout T) throws {
        guard available >= 4 else {throw BinaryDecodingError.truncated}
        withUnsafeMutableBytes(of: &value) { dest -> Void in
            dest.copyMemory(from: UnsafeRawBufferPointer(start: p, count: 4))
        }
        consume(length: 4)
    }

    /// Private: decode a fixed-length eight-byte number.  This generic
    /// helper handles all eight-byte number types.
    private mutating func decodeEightByteNumber<T>(value: inout T) throws {
        guard available >= 8 else {throw BinaryDecodingError.truncated}
        withUnsafeMutableBytes(of: &value) { dest -> Void in
            dest.copyMemory(from: UnsafeRawBufferPointer(start: p, count: 8))
        }
        consume(length: 8)
    }

    private mutating func decodeFloat() throws -> Float {
        var littleEndianBytes: UInt32 = 0
        try decodeFourByteNumber(value: &littleEndianBytes)
        var nativeEndianBytes = UInt32(littleEndian: littleEndianBytes)
        var float: Float = 0
        let n = MemoryLayout<Float>.size
        memcpy(&float, &nativeEndianBytes, n)
        return float
    }

    private mutating func decodeDouble() throws -> Double {
        var littleEndianBytes: UInt64 = 0
        try decodeEightByteNumber(value: &littleEndianBytes)
        var nativeEndianBytes = UInt64(littleEndian: littleEndianBytes)
        var double: Double = 0
        let n = MemoryLayout<Double>.size
        memcpy(&double, &nativeEndianBytes, n)
        return double
    }

    /// Private: Get the start and length for the body of
    // a length-delimited field.
    private mutating func getFieldBodyBytes(count: inout Int) throws -> UnsafeRawPointer {
        let length = try decodeVarint()
        if length <= UInt64(available) {
            count = Int(length)
            let body = p
            consume(length: count)
            return body
        }
        throw BinaryDecodingError.truncated
    }
}
