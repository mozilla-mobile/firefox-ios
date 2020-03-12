// Sources/SwiftProtobuf/BinaryDelimited.swift - Delimited support
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Helpers to read/write message with a length prefix.
///
// -----------------------------------------------------------------------------

import Foundation

/// Helper methods for reading/writing messages with a length prefix.
public enum BinaryDelimited {
  /// Additional errors for delimited message handing.
  public enum Error: Swift.Error {
    /// If a read/write to the stream fails, but the stream's `streamError` is nil,
    /// this error will be throw instead since the stream didn't provide anything
    /// more specific. A common cause for this can be failing to open the stream
    /// before trying to read/write to it.
    case unknownStreamError

    /// While reading/writing to the stream, less than the expected bytes was
    /// read/written.
    case truncated
  }

  /// Serialize a single size-delimited message from the given stream. Delimited
  /// format allows a single file or stream to contain multiple messages,
  /// whereas normally writing multiple non-delimited messages to the same
  /// stream would cause them to be merged. A delimited message is a varint
  /// encoding the message size followed by a message of exactly that size.
  ///
  /// - Parameters:
  ///   - message: The message to be written.
  ///   - to: The `OutputStream` to write the message to.  The stream is
  ///     is assumed to be ready to be written to.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  /// - Throws: `BinaryEncodingError` if encoding fails, throws
  ///           `BinaryDelimited.Error` for some writing errors, or the
  ///           underlying `OutputStream.streamError` for a stream error.
  public static func serialize(
    message: Message,
    to stream: OutputStream,
    partial: Bool = false
  ) throws {
    // TODO: Revisit to avoid the extra buffering when encoding is streamed in general.
    let serialized = try message.serializedData(partial: partial)
    let totalSize = Varint.encodedSize(of: UInt64(serialized.count)) + serialized.count
    var data = Data(count: totalSize)
    data.withUnsafeMutableBytes { (body: UnsafeMutableRawBufferPointer) in
      if let baseAddress = body.baseAddress, body.count > 0 {
        var encoder = BinaryEncoder(forWritingInto: baseAddress)
        encoder.putBytesValue(value: serialized)
      }
    }

    var written: Int = 0
    data.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
      if let baseAddress = body.baseAddress, body.count > 0 {
        // This assumingMemoryBound is technically unsafe, but without SR-11078
        // (https://bugs.swift.org/browse/SR-11087) we don't have another option.
        // It should be "safe enough".
        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
        written = stream.write(pointer, maxLength: totalSize)
      }
    }

    if written != totalSize {
      if written == -1 {
        if let streamError = stream.streamError {
          throw streamError
        }
        throw BinaryDelimited.Error.unknownStreamError
      }
      throw BinaryDelimited.Error.truncated
    }
  }

  /// Reads a single size-delimited message from the given stream. Delimited
  /// format allows a single file or stream to contain multiple messages,
  /// whereas normally parsing consumes the entire input. A delimited message
  /// is a varint encoding the message size followed by a message of exactly
  /// exactly that size.
  ///
  /// - Parameters:
  ///   - messageType: The type of message to read.
  ///   - from: The `InputStream` to read the data from.  The stream is assumed
  ///     to be ready to read from.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  ///   - options: The BinaryDecodingOptions to use.
  /// - Returns: The message read.
  /// - Throws: `BinaryDecodingError` if decoding fails, throws
  ///           `BinaryDelimited.Error` for some reading errors, and the
  ///           underlying InputStream.streamError for a stream error.
  public static func parse<M: Message>(
    messageType: M.Type,
    from stream: InputStream,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws -> M {
    var message = M()
    try merge(into: &message,
              from: stream,
              extensions: extensions,
              partial: partial,
              options: options)
    return message
  }

  /// Updates the message by reading a single size-delimited message from
  /// the given stream. Delimited format allows a single file or stream to
  /// contain multiple messages, whereas normally parsing consumes the entire
  /// input. A delimited message is a varint encoding the message size
  /// followed by a message of exactly that size.
  ///
  /// - Note: If this method throws an error, the message may still have been
  ///   partially mutated by the binary data that was decoded before the error
  ///   occurred.
  ///
  /// - Parameters:
  ///   - mergingTo: The message to merge the data into.
  ///   - from: The `InputStream` to read the data from.  The stream is assumed
  ///     to be ready to read from.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  ///   - options: The BinaryDecodingOptions to use.
  /// - Throws: `BinaryDecodingError` if decoding fails, throws
  ///           `BinaryDelimited.Error` for some reading errors, and the
  ///           underlying InputStream.streamError for a stream error.
  public static func merge<M: Message>(
    into message: inout M,
    from stream: InputStream,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
    let length = try Int(decodeVarint(stream))
    if length == 0 {
      // The message was all defaults, nothing to actually read.
      return
    }

    var data = Data(count: length)
    var bytesRead: Int = 0
    data.withUnsafeMutableBytes { (body: UnsafeMutableRawBufferPointer) in
      if let baseAddress = body.baseAddress, body.count > 0 {
        // This assumingMemoryBound is technically unsafe, but without SR-11078
        // (https://bugs.swift.org/browse/SR-11087) we don't have another option.
        // It should be "safe enough".
        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
        bytesRead = stream.read(pointer, maxLength: length)
      }
    }

    if bytesRead != length {
      if bytesRead == -1 {
        if let streamError = stream.streamError {
          throw streamError
        }
        throw BinaryDelimited.Error.unknownStreamError
      }
      throw BinaryDelimited.Error.truncated
    }

    try message.merge(serializedData: data,
                      extensions: extensions,
                      partial: partial,
                      options: options)
  }
}

// TODO: This should go away when encoding/decoding are more stream based
// as that should provide a more direct way to do this. This is basically
// a rewrite of BinaryDecoder.decodeVarint().
internal func decodeVarint(_ stream: InputStream) throws -> UInt64 {

  // Buffer to reuse within nextByte.
  var readBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
  #if swift(>=4.1)
    defer { readBuffer.deallocate() }
  #else
    defer { readBuffer.deallocate(capacity: 1) }
  #endif

  func nextByte() throws -> UInt8 {
    let bytesRead = stream.read(readBuffer, maxLength: 1)
    if bytesRead != 1 {
      if bytesRead == -1 {
        if let streamError = stream.streamError {
          throw streamError
        }
        throw BinaryDelimited.Error.unknownStreamError
      }
      throw BinaryDelimited.Error.truncated
    }
    return readBuffer[0]
  }

  var value: UInt64 = 0
  var shift: UInt64 = 0
  while true {
    let c = try nextByte()
    value |= UInt64(c & 0x7f) << shift
    if c & 0x80 == 0 {
      return value
    }
    shift += 7
    if shift > 63 {
      throw BinaryDecodingError.malformedProtobuf
    }
  }
}
