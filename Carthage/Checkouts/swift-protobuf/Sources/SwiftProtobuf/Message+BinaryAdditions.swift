// Sources/SwiftProtobuf/Message+BinaryAdditions.swift - Per-type binary coding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Message` to provide binary coding and decoding.
///
// -----------------------------------------------------------------------------

import Foundation

/// Binary encoding and decoding methods for messages.
extension Message {
  /// Returns a `Data` value containing the Protocol Buffer binary format
  /// serialization of the message.
  ///
  /// - Parameters:
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  /// - Returns: A `Data` value containing the binary serialization of the
  ///   message.
  /// - Throws: `BinaryEncodingError` if encoding fails.
  public func serializedData(partial: Bool = false) throws -> Data {
    if !partial && !isInitialized {
      throw BinaryEncodingError.missingRequiredFields
    }
    let requiredSize = try serializedDataSize()
    var data = Data(count: requiredSize)
    try data.withUnsafeMutableBytes { (body: UnsafeMutableRawBufferPointer) in
      if let baseAddress = body.baseAddress, body.count > 0 {
        var visitor = BinaryEncodingVisitor(forWritingInto: baseAddress)
        try traverse(visitor: &visitor)
        // Currently not exposing this from the api because it really would be
        // an internal error in the library and should never happen.
        assert(requiredSize == visitor.encoder.distance(pointer: baseAddress))
      }
    }
    return data
  }

  /// Returns the size in bytes required to encode the message in binary format.
  /// This is used by `serializedData()` to precalculate the size of the buffer
  /// so that encoding can proceed without bounds checks or reallocation.
  internal func serializedDataSize() throws -> Int {
    // Note: since this api is internal, it doesn't currently worry about
    // needing a partial argument to handle proto2 syntax required fields.
    // If this become public, it will need that added.
    var visitor = BinaryEncodingSizeVisitor()
    try traverse(visitor: &visitor)
    return visitor.serializedSize
  }

  /// Creates a new message by decoding the given `Data` value containing a
  /// serialized message in Protocol Buffer binary format.
  ///
  /// - Parameters:
  ///   - serializedData: The binary-encoded message data to decode.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  ///   - options: The BinaryDecodingOptions to use.
  /// - Throws: `BinaryDecodingError` if decoding fails.
  @inlinable
  public init(
    serializedData data: Data,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
    self.init()
#if swift(>=5.0)
    try merge(contiguousBytes: data, extensions: extensions, partial: partial, options: options)
#else
    try merge(serializedData: data, extensions: extensions, partial: partial, options: options)
#endif
  }

#if swift(>=5.0)
  /// Creates a new message by decoding the given `ContiguousBytes` value
  /// containing a serialized message in Protocol Buffer binary format.
  ///
  /// - Parameters:
  ///   - contiguousBytes: The binary-encoded message data to decode.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  ///   - options: The BinaryDecodingOptions to use.
  /// - Throws: `BinaryDecodingError` if decoding fails.
  @inlinable
  public init<Bytes: ContiguousBytes>(
    contiguousBytes bytes: Bytes,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
    self.init()
    try merge(contiguousBytes: bytes, extensions: extensions, partial: partial, options: options)
  }
#endif // #if swift(>=5.0)

  /// Updates the message by decoding the given `Data` value containing a
  /// serialized message in Protocol Buffer binary format into the receiver.
  ///
  /// - Note: If this method throws an error, the message may still have been
  ///   partially mutated by the binary data that was decoded before the error
  ///   occurred.
  ///
  /// - Parameters:
  ///   - serializedData: The binary-encoded message data to decode.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  ///   - options: The BinaryDecodingOptions to use.
  /// - Throws: `BinaryDecodingError` if decoding fails.
  @inlinable
  public mutating func merge(
    serializedData data: Data,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
#if swift(>=5.0)
    try merge(contiguousBytes: data, extensions: extensions, partial: partial, options: options)
#else
    try data.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
      try _merge(rawBuffer: body, extensions: extensions, partial: partial, options: options)
    }
#endif  // swift(>=5.0)
  }

#if swift(>=5.0)
  /// Updates the message by decoding the given `ContiguousBytes` value
  /// containing a serialized message in Protocol Buffer binary format into the
  /// receiver.
  ///
  /// - Note: If this method throws an error, the message may still have been
  ///   partially mutated by the binary data that was decoded before the error
  ///   occurred.
  ///
  /// - Parameters:
  ///   - contiguousBytes: The binary-encoded message data to decode.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  ///   - options: The BinaryDecodingOptions to use.
  /// - Throws: `BinaryDecodingError` if decoding fails.
  @inlinable
  public mutating func merge<Bytes: ContiguousBytes>(
    contiguousBytes bytes: Bytes,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
    try bytes.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
      try _merge(rawBuffer: body, extensions: extensions, partial: partial, options: options)
    }
  }
#endif  // swift(>=5.0)

  // Helper for `merge()`s to keep the Decoder internal to SwiftProtobuf while
  // allowing the generic over ContiguousBytes to get better codegen from the
  // compiler by being `@inlinable`.
  @usableFromInline
  internal mutating func _merge(
    rawBuffer body: UnsafeRawBufferPointer,
    extensions: ExtensionMap?,
    partial: Bool,
    options: BinaryDecodingOptions
  ) throws {
    if let baseAddress = body.baseAddress, body.count > 0 {
      var decoder = BinaryDecoder(forReadingFrom: baseAddress,
                                  count: body.count,
                                  options: options,
                                  extensions: extensions)
      try decoder.decodeFullMessage(message: &self)
    }
    if !partial && !isInitialized {
      throw BinaryDecodingError.missingRequiredFields
    }
  }
}
