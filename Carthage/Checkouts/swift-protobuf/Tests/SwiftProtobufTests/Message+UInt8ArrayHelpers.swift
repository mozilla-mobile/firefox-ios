// Tests/SwiftProtobufTests/Message+UInt8ArrayHelpers.swift - UInt8 array message helpers
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Helper methods to serialize/parse messages via UInt8 arrays, to ease
/// test migration since the original methods have been removed from the
/// runtime.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf

extension SwiftProtobuf.Message {
    init(serializedBytes: [UInt8], extensions: SwiftProtobuf.SimpleExtensionMap? = nil) throws {
        try self.init(serializedData: Data(serializedBytes), extensions: extensions)
    }

    func serializedBytes() throws -> [UInt8] {
        return try [UInt8](serializedData())
    }
}
