// Sources/SwiftProtobuf/JSONDecodingOptions.swift - JSON decoding options
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON decoding options
///
// -----------------------------------------------------------------------------

/// Options for JSONDecoding.
public struct JSONDecodingOptions {
  /// The maximum nesting of message with messages.  The default is 100.
  ///
  /// To prevent corrupt or malicious messages from causing stack overflows,
  /// this controls how deep messages can be nested within other messages
  /// while parsing.
  public var messageDepthLimit: Int = 100

  /// If unknown fields in the JSON should be ignored. If they aren't
  /// ignored, an error will be raised if one is encountered.
  public var ignoreUnknownFields: Bool = false

  public init() {}
}
