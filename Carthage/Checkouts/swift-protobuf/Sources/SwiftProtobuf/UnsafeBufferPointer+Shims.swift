// Sources/SwiftProtobuf/UnsafeBufferPointer+Shims.swift - Shims for UnsafeBufferPointer
//
// Copyright (c) 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Shims for UnsafeBufferPointer
///
// -----------------------------------------------------------------------------


extension UnsafeMutableBufferPointer {
    #if !swift(>=4.2)
    internal static func allocate(capacity: Int) -> UnsafeMutableBufferPointer<Element> {
        let pointer = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
        return UnsafeMutableBufferPointer(start: pointer, count: capacity)
    }
    #endif

    #if !swift(>=4.1)
    internal func deallocate() {
        self.baseAddress?.deallocate(capacity: self.count)
    }
    #endif
}

extension UnsafeMutableRawBufferPointer {
    #if !swift(>=4.1)
    internal func copyMemory<C: Collection>(from source: C) where C.Element == UInt8 {
        self.copyBytes(from: source)
    }
    #endif
}
