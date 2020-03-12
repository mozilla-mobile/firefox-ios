// Sources/SwiftProtobuf/Data+Extensions.swift - Extension exposing new Data API
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extension exposing new Data API to Swift versions < 5.0.
///
// -----------------------------------------------------------------------------

import Foundation

#if !swift(>=5.0)
internal extension Data {
    @usableFromInline
    func withUnsafeBytes<T>(_ body: (UnsafeRawBufferPointer) throws -> T) rethrows -> T {
        let c = count
        return try withUnsafeBytes { (p: UnsafePointer<UInt8>) throws -> T in
            try body(UnsafeRawBufferPointer(start: p, count: c))
        }
    }

    mutating func withUnsafeMutableBytes<T>(_ body: (UnsafeMutableRawBufferPointer) throws -> T) rethrows -> T {
        let c = count
        return try withUnsafeMutableBytes { (p: UnsafeMutablePointer<UInt8>) throws -> T in
            try body(UnsafeMutableRawBufferPointer(start: p, count: c))
        }
    }
}
#endif
