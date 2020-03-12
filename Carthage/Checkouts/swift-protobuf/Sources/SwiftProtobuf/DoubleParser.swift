// Sources/SwiftProtobuf/DoubleParser.swift - Generally useful mathematical functions
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Numeric parsing helper for float and double strings
///
// -----------------------------------------------------------------------------

import Foundation

/// Support parsing float/double values from UTF-8
internal class DoubleParser {
    // Temporary buffer so we can null-terminate the UTF-8 string
    // before calling the C standard libray to parse it.
    // In theory, JSON writers should be able to represent any IEEE Double
    // in at most 25 bytes, but many writers will emit more digits than
    // necessary, so we size this generously.
    private var work = 
      UnsafeMutableBufferPointer<Int8>.allocate(capacity: 128)

    deinit {
        work.deallocate()
    }

    func utf8ToDouble(bytes: UnsafeRawBufferPointer,
                      start: UnsafeRawBufferPointer.Index,
                      end: UnsafeRawBufferPointer.Index) -> Double? {
        return utf8ToDouble(bytes: UnsafeRawBufferPointer(rebasing: bytes[start..<end]))
    }

    func utf8ToDouble(bytes: UnsafeRawBufferPointer) -> Double? {
        // Reject unreasonably long or short UTF8 number
        if work.count <= bytes.count || bytes.count < 1 {
            return nil
        }

        #if swift(>=4.1)
          UnsafeMutableRawBufferPointer(work).copyMemory(from: bytes)
        #else
          UnsafeMutableRawBufferPointer(work).copyBytes(from: bytes)
        #endif
        work[bytes.count] = 0

        // Use C library strtod() to parse it
        var e: UnsafeMutablePointer<Int8>? = work.baseAddress
        let d = strtod(work.baseAddress!, &e)

        // Fail if strtod() did not consume everything we expected
        // or if strtod() thought the number was out of range.
        if e != work.baseAddress! + bytes.count || !d.isFinite {
            return nil
        }
        return d
    }
}
