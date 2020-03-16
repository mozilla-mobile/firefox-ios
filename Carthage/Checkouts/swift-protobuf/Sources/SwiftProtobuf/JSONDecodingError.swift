// Sources/SwiftProtobuf/JSONDecodingError.swift - JSON decoding errors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON decoding errors
///
// -----------------------------------------------------------------------------

public enum JSONDecodingError: Error {
    /// Something was wrong
    case failure
    /// A number could not be parsed
    case malformedNumber
    /// Numeric value was out of range or was not an integer value when expected
    case numberRange
    /// A map could not be parsed
    case malformedMap
    /// A bool could not be parsed
    case malformedBool
    /// We expected a quoted string, or a quoted string has a malformed backslash sequence
    case malformedString
    /// We encountered malformed UTF8
    case invalidUTF8
    /// The message does not have fieldName information
    case missingFieldNames
    /// The data type does not match the schema description
    case schemaMismatch
    /// A value (text or numeric) for an enum was not found on the enum
    case unrecognizedEnumValue
    /// A 'null' token appeared in an illegal location.
    /// For example, Protobuf JSON does not allow 'null' tokens to appear
    /// in lists.
    case illegalNull
    /// A map key was not quoted
    case unquotedMapKey
    /// JSON RFC 7519 does not allow numbers to have extra leading zeros
    case leadingZero
    /// We hit the end of the JSON string and expected something more...
    case truncated
    /// A JSON Duration could not be parsed
    case malformedDuration
    /// A JSON Timestamp could not be parsed
    case malformedTimestamp
    /// A FieldMask could not be parsed
    case malformedFieldMask
    /// Extraneous data remained after decoding should have been complete
    case trailingGarbage
    /// More than one value was specified for the same oneof field
    case conflictingOneOf
    /// Reached the nesting limit for messages within messages while decoding.
    case messageDepthLimit
    /// Encountered an unknown field with the given name. When parsing JSON, you
    /// can instead instruct the library to ignore this via
    /// JSONDecodingOptions.ignoreUnknownFields.
    case unknownField(String)
}
