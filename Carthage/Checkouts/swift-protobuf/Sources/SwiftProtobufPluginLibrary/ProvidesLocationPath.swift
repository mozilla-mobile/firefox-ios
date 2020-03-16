// Sources/SwiftProtobufPluginLibrary/ProvidesLocationPath.swift - Proto Field numbers
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation

public protocol ProvidesLocationPath {
  func getLocationPath(path: inout IndexPath)
  var file: FileDescriptor! { get }
}
