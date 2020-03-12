// Sources/SwiftProtobuf/BinaryEncoder.swift - Binary encoding support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Core support for protobuf binary encoding.  Note that this is built
/// on the general traversal machinery.
///
// -----------------------------------------------------------------------------

import Foundation

/*
 * Encoder for Binary Protocol Buffer format
 */
internal struct BinaryEncoder {
    private var pointer: UnsafeMutableRawPointer

    init(forWritingInto pointer: UnsafeMutableRawPointer) {
        self.pointer = pointer
    }

    private mutating func append(_ byte: UInt8) {
        pointer.storeBytes(of: byte, as: UInt8.self)
        pointer = pointer.advanced(by: 1)
    }

    private mutating func append(contentsOf data: Data) {
        data.withUnsafeBytes { dataPointer in
            if let baseAddress = dataPointer.baseAddress, dataPointer.count > 0 {
                pointer.copyMemory(from: baseAddress, byteCount: dataPointer.count)
                pointer = pointer.advanced(by: dataPointer.count)
            }
        }
    }

    private mutating func append(contentsOf bufferPointer: UnsafeRawBufferPointer) {
        let count = bufferPointer.count
        if let baseAddress = bufferPointer.baseAddress, count > 0 {
            memcpy(pointer, baseAddress, count)
        }
        pointer = pointer.advanced(by: count)
    }

    func distance(pointer: UnsafeMutableRawPointer) -> Int {
        return pointer.distance(to: self.pointer)
    }

    mutating func appendUnknown(data: Data) {
        append(contentsOf: data)
    }

    mutating func startField(fieldNumber: Int, wireFormat: WireFormat) {
        startField(tag: FieldTag(fieldNumber: fieldNumber, wireFormat: wireFormat))
    }

    mutating func startField(tag: FieldTag) {
        putVarInt(value: UInt64(tag.rawValue))
    }

    mutating func putVarInt(value: UInt64) {
        var v = value
        while v > 127 {
            append(UInt8(v & 0x7f | 0x80))
            v >>= 7
        }
        append(UInt8(v))
    }

    mutating func putVarInt(value: Int64) {
        putVarInt(value: UInt64(bitPattern: value))
    }

    mutating func putVarInt(value: Int) {
        putVarInt(value: Int64(value))
    }

    mutating func putZigZagVarInt(value: Int64) {
        let coded = ZigZag.encoded(value)
        putVarInt(value: coded)
    }

    mutating func putBoolValue(value: Bool) {
        append(value ? 1 : 0)
    }

    mutating func putFixedUInt64(value: UInt64) {
        var v = value.littleEndian
        let n = MemoryLayout<UInt64>.size
        memcpy(pointer, &v, n)
        pointer = pointer.advanced(by: n)
    }

    mutating func putFixedUInt32(value: UInt32) {
        var v = value.littleEndian
        let n = MemoryLayout<UInt32>.size
        memcpy(pointer, &v, n)
        pointer = pointer.advanced(by: n)
    }

    mutating func putFloatValue(value: Float) {
        let n = MemoryLayout<Float>.size
        var v = value
        var nativeBytes: UInt32 = 0
        memcpy(&nativeBytes, &v, n)
        var littleEndianBytes = nativeBytes.littleEndian
        memcpy(pointer, &littleEndianBytes, n)
        pointer = pointer.advanced(by: n)
    }

    mutating func putDoubleValue(value: Double) {
        let n = MemoryLayout<Double>.size
        var v = value
        var nativeBytes: UInt64 = 0
        memcpy(&nativeBytes, &v, n)
        var littleEndianBytes = nativeBytes.littleEndian
        memcpy(pointer, &littleEndianBytes, n)
        pointer = pointer.advanced(by: n)
    }

    // Write a string field, including the leading index/tag value.
    mutating func putStringValue(value: String) {
        let count = value.utf8.count
        putVarInt(value: count)
        for b in value.utf8 {
            pointer.storeBytes(of: b, as: UInt8.self)
            pointer = pointer.advanced(by: 1)
        }
    }

    mutating func putBytesValue(value: Data) {
        putVarInt(value: value.count)
        append(contentsOf: value)
    }
}
