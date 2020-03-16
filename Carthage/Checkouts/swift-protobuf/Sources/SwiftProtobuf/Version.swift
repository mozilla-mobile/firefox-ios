// Sources/SwiftProtobuf/Version.swift - Runtime Version info
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A interface for exposing the version of the runtime.
///
// -----------------------------------------------------------------------------

import Foundation

// Expose version information about the library.
public struct Version {
  /// Major version.
  public static let major = 1
  /// Minor version.
  public static let minor = 8
  /// Revision number.
  public static let revision = 0

  /// String form of the version number.
  public static let versionString = "\(major).\(minor).\(revision)"
}
