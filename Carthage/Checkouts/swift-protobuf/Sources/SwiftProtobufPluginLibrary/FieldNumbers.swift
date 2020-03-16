// Sources/SwiftProtobufPluginLibrary/FieldNumbers.swift - Proto Field numbers
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Field numbers needed by SwiftProtobufPluginLibrary since they currently aren't generated.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf

extension Google_Protobuf_FileDescriptorProto {
  struct FieldNumbers {
    static let messageType: Int = 4
    static let enumType: Int = 5
    static let service: Int = 6
    static let `extension`: Int = 7
  }
}

extension Google_Protobuf_DescriptorProto {
  struct FieldNumbers {
    static let field: Int = 2
    static let nestedType: Int = 3
    static let enumType: Int = 4
    static let `extension`: Int = 6
    static let oneofDecl: Int = 8
  }
}

extension Google_Protobuf_EnumDescriptorProto {
  struct FieldNumbers {
    static let value: Int = 2
  }
}

extension Google_Protobuf_ServiceDescriptorProto {
  struct FieldNumbers {
    static let method: Int = 2
  }
}
