// Sources/SwiftProtobufPluginLibrary/Descriptor+Extensions.swift - Additions to Descriptor
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf

extension FileDescriptor: ProvidesSourceCodeLocation {
  public var sourceCodeInfoLocation: Google_Protobuf_SourceCodeInfo.Location? {
    // google/protobuf's descriptor.cc says it should be an empty path.
    return sourceCodeInfoLocation(path: IndexPath())
  }
}

extension Descriptor: ProvidesLocationPath, ProvidesSourceCodeLocation {
  public func getLocationPath(path: inout IndexPath) {
    if let containingType = containingType {
      containingType.getLocationPath(path: &path)
      path.append(Google_Protobuf_DescriptorProto.FieldNumbers.nestedType)
    } else {
      path.append(Google_Protobuf_FileDescriptorProto.FieldNumbers.messageType)
    }
    path.append(index)
  }
}

extension EnumDescriptor: ProvidesLocationPath, ProvidesSourceCodeLocation {
  public func getLocationPath(path: inout IndexPath) {
    if let containingType = containingType {
      containingType.getLocationPath(path: &path)
      path.append(Google_Protobuf_DescriptorProto.FieldNumbers.enumType)
    } else {
      path.append(Google_Protobuf_FileDescriptorProto.FieldNumbers.enumType)
    }
    path.append(index)
  }
}

extension EnumValueDescriptor: ProvidesLocationPath, ProvidesSourceCodeLocation {
  public func getLocationPath(path: inout IndexPath) {
    enumType.getLocationPath(path: &path)
    path.append(Google_Protobuf_EnumDescriptorProto.FieldNumbers.value)
    path.append(index)
  }
}

extension OneofDescriptor: ProvidesLocationPath, ProvidesSourceCodeLocation {
  public func getLocationPath(path: inout IndexPath) {
    containingType.getLocationPath(path: &path)
    path.append(Google_Protobuf_DescriptorProto.FieldNumbers.oneofDecl)
    path.append(index)
  }
}

extension FieldDescriptor: ProvidesLocationPath, ProvidesSourceCodeLocation {
  public func getLocationPath(path: inout IndexPath) {
    if isExtension {
      if let extensionScope = extensionScope {
        extensionScope.getLocationPath(path: &path)
        path.append(Google_Protobuf_DescriptorProto.FieldNumbers.extension)
      } else {
        path.append(Google_Protobuf_FileDescriptorProto.FieldNumbers.extension)
      }
    } else {
      containingType.getLocationPath(path: &path)
      path.append(Google_Protobuf_DescriptorProto.FieldNumbers.field)
    }
    path.append(index)
  }

  /// Returns true if the type can be used for a Packed field.
  static func isPackable(type: Google_Protobuf_FieldDescriptorProto.TypeEnum) -> Bool {
    // This logic comes from the C++ FieldDescriptor::IsTypePackable() impl.
    switch type {
    case .string, .group, .message, .bytes:
      return false
    default:
      return true
    }
  }

  /// Is this field packable.
  var isPackable: Bool {
    // This logic comes from the C++ FieldDescriptor::is_packable() impl.
    return label == .repeated && FieldDescriptor.isPackable(type: type)
  }

  /// Helper to return the name to as the "base" for naming of generated fields.
  ///
  /// Groups use the underlying message's name. The way groups are declared in
  /// proto files, the filed names is derived by lowercasing the Group's name,
  /// so there are no underscores, etc. to rebuild a camel case name from.
  var namingBase: String {
    return type == .group ? messageType.name : name
  }
}

extension ServiceDescriptor: ProvidesLocationPath, ProvidesSourceCodeLocation {
  public func getLocationPath(path: inout IndexPath) {
    path.append(Google_Protobuf_FileDescriptorProto.FieldNumbers.service)
    path.append(index)
  }
}

extension MethodDescriptor: ProvidesLocationPath, ProvidesSourceCodeLocation {
  public func getLocationPath(path: inout IndexPath) {
    service.getLocationPath(path: &path)
    path.append(Google_Protobuf_ServiceDescriptorProto.FieldNumbers.method)
    path.append(index)
  }
}
