// Performance/main.cc - C++ performance harness entry point
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Entry point for the C++ performance harness.
///
// -----------------------------------------------------------------------------

#include <fstream>

#include "Harness.h"

using std::ios_base;
using std::ofstream;

int main(int argc, char **argv) {
  ofstream* results_stream = (argc > 1) ?
      new ofstream(argv[1], ios_base::app) : nullptr;

  Harness harness(results_stream);
  harness.run();

  if (results_stream) {
    results_stream->close();
    delete results_stream;
  }

  return 0;
}
