// Sources/protoc-gen-swift/FileIo.swift - File I/O utilities
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Some basic utilities to handle writing to Stderr, Stdout, and reading/writing
/// blocks of data from/to a file on disk.
///
// -----------------------------------------------------------------------------
import Foundation

class Stderr {
  static func print(_ s: String) {
    let out = "\(CommandLine.programName): \(s)\n"
    if let data = out.data(using: .utf8) {
      FileHandle.standardError.write(data)
    }
  }
}

func readFileData(filename: String) throws -> Data {
    let url = URL(fileURLWithPath: filename)
    return try Data(contentsOf: url)
}
