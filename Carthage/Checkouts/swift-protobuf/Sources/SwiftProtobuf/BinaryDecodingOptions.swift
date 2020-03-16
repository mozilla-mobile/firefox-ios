// Sources/SwiftProtobuf/BinaryDecodingOptions.swift - Binary decoding options
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Binary decoding options
///
// -----------------------------------------------------------------------------

/// Options for JSONDecoding.
public struct BinaryDecodingOptions {
  /// The maximum nesting of message with messages.  The default is 100.
  ///
  /// To prevent corrupt or malicious messages from causing stack overflows,
  /// this controls how deep messages can be nested within other messages
  /// while parsing.
  public var messageDepthLimit: Int = 100

  /// Discard unknown fields while parsing.  The default is false, so parsering
  /// does not discard unknown fields.
  ///
  /// The Protobuf binary format allows unknown fields to be still parsed
  /// so the schema can be expanded without requiring all readers to be updated.
  /// This works in part by haivng any unknown fields preserved so they can
  /// be relayed on without loss. For a while the proto3 syntax definition
  /// called for unknown fields to be dropped, but that lead to problems in
  /// some case. The default is to follow the spec and keep them, but setting
  /// this option to `true` allows a developer to strip them during a parse
  /// in case they have a specific need to drop the unknown fields from the
  /// object graph being created.
  public var discardUnknownFields: Bool = false

  public init() {}
}
