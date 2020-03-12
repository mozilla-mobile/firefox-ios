// Sources/protoc-gen-swift/CommandLine+Extensions - Additions to CommandLine
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation

extension CommandLine {
  static var programName: String {
    guard let base = arguments.first else {
      return "protoc-gen-swift"
    }
    // Strip it down to just the leaf if it was a path.
    let parts = splitPath(pathname: base)
    return parts.base + parts.suffix
  }
}
