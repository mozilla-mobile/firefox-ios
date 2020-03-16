// Sources/SwiftProtobuf/JSONEncodingError.swift - Error constants
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Enum constants that identify the particular error.
///
// -----------------------------------------------------------------------------

public enum JSONEncodingError: Error {
    /// Any fields that were decoded from binary format cannot be
    /// re-encoded into JSON unless the object they hold is a
    /// well-known type or a type registered with via
    /// Google_Protobuf_Any.register()
    case anyTranscodeFailure
    /// Timestamp values can only be JSON encoded if they hold a value
    /// between 0001-01-01Z00:00:00 and 9999-12-31Z23:59:59.
    case timestampRange
    /// Duration values can only be JSON encoded if they hold a value
    /// less than +/- 100 years.
    case durationRange
    /// Field masks get edited when converting between JSON and protobuf
    case fieldMaskConversion
    /// Field names were not compiled into the binary
    case missingFieldNames
    /// Instances of `Google_Protobuf_Value` can only be encoded if they have a
    /// valid `kind` (that is, they represent a null value, number, boolean,
    /// string, struct, or list).
    case missingValue
}
