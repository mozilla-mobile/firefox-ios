// Sources/SwiftProtobuf/ExtensionMap.swift - Extension support
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A set of extensions that can be passed into deserializers
/// to provide details of the particular extensions that should
/// be recognized.
///
// -----------------------------------------------------------------------------

/// A collection of extension objects.
///
/// An `ExtensionMap` is used during decoding to look up
/// extension objects corresponding to the serialized data.
///
/// This is a protocol so that developers can build their own
/// extension handling if they need something more complex than the
/// standard `SimpleExtensionMap` implementation.
public protocol ExtensionMap {
    /// Returns the extension object describing an extension or nil
    subscript(messageType: Message.Type, fieldNumber: Int) -> AnyMessageExtension? { get }

    /// Returns the field number for a message with a specific field name
    ///
    /// The field name here matches the format used by the protobuf
    /// Text serialization: it typically looks like
    /// `package.message.field_name`, where `package` is the package
    /// for the proto file and `message` is the name of the message in
    /// which the extension was defined. (This is different from the
    /// message that is being extended!)
    func fieldNumberForProto(messageType: Message.Type, protoFieldName: String) -> Int?
}
