// Sources/protoc-gen-swift/Google_Protobuf_FileDescriptorProto+Extensions.swift - Descriptor extensions
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `FileDescriptorProto` that provide Swift-generation-specific
/// functionality.
///
// -----------------------------------------------------------------------------

import SwiftProtobufPluginLibrary
import SwiftProtobuf

extension Google_Protobuf_FileDescriptorProto {
  // Field numbers used to collect .proto file comments.
  struct FieldNumbers {
    static let syntax: Int = 12
  }
}
