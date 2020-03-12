// Sources/SwiftProtobuf/Enum.swift - Enum support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Generated enums conform to SwiftProtobuf.Enum
///
/// See ProtobufTypes and JSONTypes for extension
/// methods to support binary and JSON coding.
///
// -----------------------------------------------------------------------------

/// Generated enum types conform to this protocol.
public protocol Enum: RawRepresentable, Hashable {
  /// Creates a new instance of the enum initialized to its default value.
  init()

  /// Creates a new instance of the enum from the given raw integer value.
  ///
  /// For proto2 enums, this initializer will fail if the raw value does not
  /// correspond to a valid enum value. For proto3 enums, this initializer never
  /// fails; unknown values are created as instances of the `UNRECOGNIZED` case.
  ///
  /// - Parameter rawValue: The raw integer value from which to create the enum
  ///   value.
  init?(rawValue: Int)

  /// The raw integer value of the enum value.
  ///
  /// For a recognized enum case, this is the integer value of the case as
  /// defined in the .proto file. For `UNRECOGNIZED` cases in proto3, this is
  /// the value that was originally decoded.
  var rawValue: Int { get }
}

extension Enum {
#if swift(>=4.2)
  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
#else  // swift(>=4.2)
  public var hashValue: Int {
    return rawValue
  }
#endif  // swift(>=4.2)

  /// Internal convenience property representing the name of the enum value (or
  /// `nil` if it is an `UNRECOGNIZED` value or doesn't provide names).
  ///
  /// Since the text format and JSON names are always identical, we don't need
  /// to distinguish them.
  internal var name: _NameMap.Name? {
    guard let nameProviding = Self.self as? _ProtoNameProviding.Type else {
      return nil
    }
    return nameProviding._protobuf_nameMap.names(for: rawValue)?.proto
  }

  /// Internal convenience initializer that returns the enum value with the
  /// given name, if it provides names.
  ///
  /// Since the text format and JSON names are always identical, we don't need
  /// to distinguish them.
  ///
  /// - Parameter name: The name of the enum case.
  internal init?(name: String) {
    guard let nameProviding = Self.self as? _ProtoNameProviding.Type,
      let number = nameProviding._protobuf_nameMap.number(forJSONName: name) else {
      return nil
    }
    self.init(rawValue: number)
  }

  /// Internal convenience initializer that returns the enum value with the
  /// given name, if it provides names.
  ///
  /// Since the text format and JSON names are always identical, we don't need
  /// to distinguish them.
  ///
  /// - Parameter name: Buffer holding the UTF-8 bytes of the desired name.
  internal init?(rawUTF8: UnsafeRawBufferPointer) {
    guard let nameProviding = Self.self as? _ProtoNameProviding.Type,
      let number = nameProviding._protobuf_nameMap.number(forJSONName: rawUTF8) else {
      return nil
    }
    self.init(rawValue: number)
  }
}
