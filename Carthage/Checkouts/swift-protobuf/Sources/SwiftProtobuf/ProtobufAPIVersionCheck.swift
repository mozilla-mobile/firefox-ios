// Sources/SwiftProtobuf/ProtobufAPIVersionCheck.swift - Version checking
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A scheme that ensures that generated protos cannot be compiled or linked
/// against a version of the runtime with which they are not compatible.
///
/// In many cases, API changes themselves might introduce incompatibilities
/// between generated code and the runtime library, but we also want to protect
/// against cases where breaking behavioral changes (without affecting the API)
/// would cause generated code to be incompatible with a particular version of
/// the runtime.
///
// -----------------------------------------------------------------------------


/// An empty protocol that encodes the version of the runtime library.
///
/// This protocol will be replaced with one containing a different version
/// number any time that breaking changes are made to the Swift Protobuf API.
/// Combined with the protocol below, this lets us verify that generated code is
/// never compiled against a version of the API with which it is incompatible.
///
/// The version associated with a particular build of the compiler is defined as
/// `Version.compatibilityVersion` in `protoc-gen-swift`. That version and this
/// version must match for the generated protos to be compatible, so if you
/// update one, make sure to update it here and in the associated type below.
public protocol ProtobufAPIVersion_2 {}

/// This protocol is expected to be implemented by a `fileprivate` type in each
/// source file emitted by `protoc-gen-swift`. It effectively creates a binding
/// between the version of the generated code and the version of this library,
/// causing a compile-time error (with reasonable diagnostics) if they are
/// incompatible.
public protocol ProtobufAPIVersionCheck {
  associatedtype Version: ProtobufAPIVersion_2
}
