// Sources/protoc-gen-swift/Version.swift - Protoc plugin version info
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A simple static object that provides information about the plugin.
///
// ----------------------------------------------------------------------------

import SwiftProtobuf

struct Version {
    // The "compatibility version" of the runtime library, which must be
    // incremented every time a breaking change (either behavioral or
    // API-changing) is introduced.
    //
    // We guarantee that generated protos that contain this version token will
    // be compatible with the runtime library containing the matching token.
    // Therefore, this number (and the corresponding one in the runtime
    // library) should not be updated for *every* version of Swift Protobuf,
    // but only for those that introduce breaking changes (either behavioral
    // or API-changing).
    static let compatibilityVersion = 2

    static let copyright = "Copyright (C) 2014-2017 Apple Inc. and the project authors"
}
