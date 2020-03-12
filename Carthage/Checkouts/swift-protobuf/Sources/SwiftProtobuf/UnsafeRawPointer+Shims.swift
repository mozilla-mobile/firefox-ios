// Sources/SwiftProtobuf/UnsafeRawPointer+Shims.swift - Shims for UnsafeRawPointer and friends
//
// Copyright (c) 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Shims for UnsafeRawPointer and friends.
///
// -----------------------------------------------------------------------------


extension UnsafeRawPointer {
    /// A shim subscript for UnsafeRawPointer aiming to maintain code consistency.
    ///
    /// We can remove this shim when we rewrite the code to use buffer pointers.
    internal subscript(_ offset: Int) -> UInt8 {
        get {
            return self.load(fromByteOffset: offset, as: UInt8.self)
        }
    }
}

extension UnsafeMutableRawPointer {
    /// A shim subscript for UnsafeMutableRawPointer aiming to maintain code consistency.
    ///
    /// We can remove this shim when we rewrite the code to use buffer pointers.
    internal subscript(_ offset: Int) -> UInt8 {
        get {
            return self.load(fromByteOffset: offset, as: UInt8.self)
        }
        set {
            self.storeBytes(of: newValue, toByteOffset: offset, as: UInt8.self)
        }
    }

    #if !swift(>=4.1)
    internal mutating func copyMemory(from source: UnsafeRawPointer, byteCount: Int) {
        self.copyBytes(from: source, count: byteCount)
    }
    #endif
}
