// Sources/SwiftProtobufPluginLibrary/Google_Protobuf_Compiler_CodeGeneratorResponse+Extensions.swift - CodeGeneratorResponse extensions
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `CodeGeneratorResponse` provide some simple helpers.
///
// -----------------------------------------------------------------------------

extension Google_Protobuf_Compiler_CodeGeneratorResponse {
  /// Helper to make a response with an error.
  public init(error: String) {
    self.init()
    self.error = error
  }

  /// Helper to make a response with a set of files
  public init(files: [Google_Protobuf_Compiler_CodeGeneratorResponse.File]) {
    self.init()
    self.file = files
  }
}

extension Google_Protobuf_Compiler_CodeGeneratorResponse.File {
  /// Helper to make a Response.File with specific content.
  public init(name: String, content: String) {
    self.init()
    self.name = name
    self.content = content
  }
}
