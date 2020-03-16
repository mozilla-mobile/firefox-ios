// Sources/SwiftProtobuf/TextFormatEncodingOptions.swift - Text format encoding options
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Text format encoding options
///
// -----------------------------------------------------------------------------

/// Options for TextFormatEncoding.
public struct TextFormatEncodingOptions {

  /// Default: Do print unknown fields using numeric notation
  public var printUnknownFields: Bool = true

  public init() {}
}
