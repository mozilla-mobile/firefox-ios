// Sources/SwiftProtobuf/JSONEncodingOptions.swift - JSON encoding options
//
// Copyright (c) 2014 - 2018 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON encoding options
///
// -----------------------------------------------------------------------------

/// Options for JSONEncoding.
public struct JSONEncodingOptions {

  /// Always print enums as ints. By default they are printed as strings.
  public var alwaysPrintEnumsAsInts: Bool = false

  /// Whether to preserve proto field names.
  /// By default they are converted to JSON(lowerCamelCase) names.
  public var preserveProtoFieldNames: Bool = false

  public init() {}
}
