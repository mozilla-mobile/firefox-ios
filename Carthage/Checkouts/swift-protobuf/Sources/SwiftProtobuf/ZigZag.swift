// Sources/SwiftProtobuf/ZigZag.swift - ZigZag encoding/decoding helpers
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Helper functions to ZigZag encode and decode signed integers.
///
// -----------------------------------------------------------------------------


/// Contains helper methods to ZigZag encode and decode signed integers.
internal enum ZigZag {

    /// Return a 32-bit ZigZag-encoded value.
    ///
    /// ZigZag encodes signed integers into values that can be efficiently encoded with varint.
    /// (Otherwise, negative values must be sign-extended to 64 bits to be varint encoded, always
    /// taking 10 bytes on the wire.)
    ///
    /// - Parameter value: A signed 32-bit integer.
    /// - Returns: An unsigned 32-bit integer representing the ZigZag-encoded value.
    static func encoded(_ value: Int32) -> UInt32 {
        return UInt32(bitPattern: (value << 1) ^ (value >> 31))
    }

    /// Return a 64-bit ZigZag-encoded value.
    ///
    /// ZigZag encodes signed integers into values that can be efficiently encoded with varint.
    /// (Otherwise, negative values must be sign-extended to 64 bits to be varint encoded, always
    /// taking 10 bytes on the wire.)
    ///
    /// - Parameter value: A signed 64-bit integer.
    /// - Returns: An unsigned 64-bit integer representing the ZigZag-encoded value.
    static func encoded(_ value: Int64) -> UInt64 {
        return UInt64(bitPattern: (value << 1) ^ (value >> 63))
    }

    /// Return a 32-bit ZigZag-decoded value.
    ///
    /// ZigZag enocdes signed integers into values that can be efficiently encoded with varint.
    /// (Otherwise, negative values must be sign-extended to 64 bits to be varint encoded, always
    /// taking 10 bytes on the wire.)
    ///
    /// - Parameter value: An unsigned 32-bit ZagZag-encoded integer.
    /// - Returns: The signed 32-bit decoded value.
    static func decoded(_ value: UInt32) -> Int32 {
        return Int32(value >> 1) ^ -Int32(value & 1)
    }

    /// Return a 64-bit ZigZag-decoded value.
    ///
    /// ZigZag enocdes signed integers into values that can be efficiently encoded with varint.
    /// (Otherwise, negative values must be sign-extended to 64 bits to be varint encoded, always
    /// taking 10 bytes on the wire.)
    ///
    /// - Parameter value: An unsigned 64-bit ZigZag-encoded integer.
    /// - Returns: The signed 64-bit decoded value.
    static func decoded(_ value: UInt64) -> Int64 {
        return Int64(value >> 1) ^ -Int64(value & 1)
    }
}
