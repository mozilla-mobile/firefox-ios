// Sources/SwiftProtobuf/TextFormatDecodingError.swift - Protobuf text format decoding errors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Protobuf text format decoding errors
///
// -----------------------------------------------------------------------------

public enum TextFormatDecodingError: Error {
    /// Text data could not be parsed
    case malformedText
    /// A number could not be parsed
    case malformedNumber
    /// Extraneous data remained after decoding should have been complete
    case trailingGarbage
    /// The data stopped before we expected
    case truncated
    /// A string was not valid UTF8
    case invalidUTF8
    /// The data being parsed does not match the type specified in the proto file
    case schemaMismatch
    /// Field names were not compiled into the binary
    case missingFieldNames
    /// A field identifier (name or number) was not found on the message
    case unknownField
    /// The enum value was not recognized
    case unrecognizedEnumValue
    /// Text format rejects conflicting values for the same oneof field
    case conflictingOneOf
    /// An internal error happened while decoding.  If this is ever encountered,
    /// please file an issue with SwiftProtobuf with as much details as possible
    /// for what happened (proto definitions, bytes being decoded (if possible)).
    case internalExtensionError
}
