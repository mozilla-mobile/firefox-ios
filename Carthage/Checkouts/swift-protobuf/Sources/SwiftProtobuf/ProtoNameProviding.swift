// Sources/SwiftProtobuf/ProtoNameProviding.swift - Support for accessing proto names
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------


/// SwiftProtobuf Internal: Common support looking up field names.
///
/// Messages conform to this protocol to provide the proto/text and JSON field
/// names for their fields. This allows these names to be pulled out into
/// extensions in separate files so that users can omit them in release builds
/// (reducing bloat and minimizing leaks of field names).
public protocol _ProtoNameProviding {

  /// The mapping between field numbers and proto/JSON field names defined in
  /// the conforming message type.
  static var _protobuf_nameMap: _NameMap { get }
}
