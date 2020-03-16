// Performance/main.swift - Performance harness entry point
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Entry point that creates the performance harness and runs it.
///
// -----------------------------------------------------------------------------

import Foundation

let args = CommandLine.arguments
let resultsFile = args.count > 1 ?
    FileHandle(forWritingAtPath: args[1]) : nil
resultsFile?.seekToEndOfFile()

let harness = Harness(resultsFile: resultsFile)
harness.run()

resultsFile?.closeFile()
