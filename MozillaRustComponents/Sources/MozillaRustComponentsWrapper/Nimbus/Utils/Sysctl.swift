// swiftlint:disable line_length
// REASON: URLs and doc strings
// Copyright © 2017 Matt Gallagher ( http://cocoawithlove.com ). All rights reserved.
//
// Original: https://github.com/mattgallagher/CwlUtils/blob/0e08b0194bf95861e5aac27e8857a972983315d7/Sources/CwlUtils/CwlSysctl.swift
// Modified:
//   * iOS only
//   * removed unused functions
//   * reformatted
//
// ISC License
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
// IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

import Foundation

// swiftlint:disable force_try
// REASON: Used on infallible operations

/// A "static"-only namespace around a series of functions that operate on buffers returned from the `Darwin.sysctl` function
struct Sysctl {
    /// Possible errors.
    enum Error: Swift.Error {
        case unknown
        case malformedUTF8
        case invalidSize
        case posixError(POSIXErrorCode)
    }

    /// Access the raw data for an array of sysctl identifiers.
    public static func data(for keys: [Int32]) throws -> [Int8] {
        return try keys.withUnsafeBufferPointer { keysPointer throws -> [Int8] in
            // Preflight the request to get the required data size
            var requiredSize = 0
            let preFlightResult = Darwin.sysctl(
                UnsafeMutablePointer<Int32>(mutating: keysPointer.baseAddress),
                UInt32(keys.count),
                nil,
                &requiredSize,
                nil,
                0
            )
            if preFlightResult != 0 {
                throw POSIXErrorCode(rawValue: errno).map {
                    print($0.rawValue)
                    return Error.posixError($0)
                } ?? Error.unknown
            }

            // Run the actual request with an appropriately sized array buffer
            let data = [Int8](repeating: 0, count: requiredSize)
            let result = data.withUnsafeBufferPointer { dataBuffer -> Int32 in
                Darwin.sysctl(
                    UnsafeMutablePointer<Int32>(mutating: keysPointer.baseAddress),
                    UInt32(keys.count),
                    UnsafeMutableRawPointer(mutating: dataBuffer.baseAddress),
                    &requiredSize,
                    nil,
                    0
                )
            }
            if result != 0 {
                throw POSIXErrorCode(rawValue: errno).map { Error.posixError($0) } ?? Error.unknown
            }

            return data
        }
    }

    /// Convert a sysctl name string like "hw.memsize" to the array of `sysctl` identifiers (e.g. [CTL_HW, HW_MEMSIZE])
    public static func keys(for name: String) throws -> [Int32] {
        var keysBufferSize = Int(CTL_MAXNAME)
        var keysBuffer = [Int32](repeating: 0, count: keysBufferSize)
        try keysBuffer.withUnsafeMutableBufferPointer { (lbp: inout UnsafeMutableBufferPointer<Int32>) throws in
            try name.withCString { (nbp: UnsafePointer<Int8>) throws in
                guard sysctlnametomib(nbp, lbp.baseAddress, &keysBufferSize) == 0 else {
                    throw POSIXErrorCode(rawValue: errno).map { Error.posixError($0) } ?? Error.unknown
                }
            }
        }
        if keysBuffer.count > keysBufferSize {
            keysBuffer.removeSubrange(keysBufferSize ..< keysBuffer.count)
        }
        return keysBuffer
    }

    /// Invoke `sysctl` with an array of identifiers, interpreting the returned buffer as the specified type.
    /// This function will throw `Error.invalidSize` if the size of buffer returned from `sysctl` fails to match the size of `T`.
    public static func value<T>(ofType _: T.Type, forKeys keys: [Int32]) throws -> T {
        let buffer = try data(for: keys)
        if buffer.count != MemoryLayout<T>.size {
            throw Error.invalidSize
        }
        return try buffer.withUnsafeBufferPointer { bufferPtr throws -> T in
            guard let baseAddress = bufferPtr.baseAddress else { throw Error.unknown }
            return baseAddress.withMemoryRebound(to: T.self, capacity: 1) { $0.pointee }
        }
    }

    /// Invoke `sysctl` with an array of identifiers, interpreting the returned buffer as the specified type.
    /// This function will throw `Error.invalidSize` if the size of buffer returned from `sysctl` fails to match the size of `T`.
    public static func value<T>(ofType type: T.Type, forKeys keys: Int32...) throws -> T {
        return try value(ofType: type, forKeys: keys)
    }

    /// Invoke `sysctl` with the specified name, interpreting the returned buffer as the specified type.
    /// This function will throw `Error.invalidSize` if the size of buffer returned from `sysctl` fails to match the size of `T`.
    public static func value<T>(ofType type: T.Type, forName name: String) throws -> T {
        return try value(ofType: type, forKeys: keys(for: name))
    }

    /// Invoke `sysctl` with an array of identifiers, interpreting the returned buffer as a `String`.
    /// This function will throw `Error.malformedUTF8` if the buffer returned from `sysctl` cannot be interpreted as a UTF8 buffer.
    public static func string(for keys: [Int32]) throws -> String {
        let optionalString = try data(for: keys).withUnsafeBufferPointer { dataPointer -> String? in
            dataPointer.baseAddress.flatMap { String(validatingUTF8: $0) }
        }
        guard let s = optionalString else {
            throw Error.malformedUTF8
        }
        return s
    }

    /// Invoke `sysctl` with an array of identifiers, interpreting the returned buffer as a `String`.
    /// This function will throw `Error.malformedUTF8` if the buffer returned from `sysctl` cannot be interpreted as a UTF8 buffer.
    public static func string(for keys: Int32...) throws -> String {
        return try string(for: keys)
    }

    /// Invoke `sysctl` with the specified name, interpreting the returned buffer as a `String`.
    /// This function will throw `Error.malformedUTF8` if the buffer returned from `sysctl` cannot be interpreted as a UTF8 buffer.
    public static func string(for name: String) throws -> String {
        return try string(for: keys(for: name))
    }

    /// Always the same on Apple hardware
    public static var manufacturer: String = "Apple"

    /// e.g. "N71mAP"
    public static var machine: String {
        return try! Sysctl.string(for: [CTL_HW, HW_MODEL])
    }

    /// e.g. "iPhone8,1"
    public static var model: String {
        return try! Sysctl.string(for: [CTL_HW, HW_MACHINE])
    }

    /// e.g. "15D21" or "13D20"
    public static var osVersion: String { return try! Sysctl.string(for: [CTL_KERN, KERN_OSVERSION]) }
}
// swiftlint:enable force_try
// swiftlint:enable line_length
