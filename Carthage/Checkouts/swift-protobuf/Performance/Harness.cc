// Performance/Harness.cc - C++ performance harness definition
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Defines the class that runs the performance tests.
///
// -----------------------------------------------------------------------------

#include <chrono>
#include <cstdio>
#include <cmath>
#include <iostream>
#include <string>
#include <type_traits>
#include <vector>

#include "Harness.h"

using std::chrono::duration_cast;
using std::chrono::steady_clock;
using std::endl;
using std::function;
using std::ostream;
using std::result_of;
using std::sqrt;
using std::string;
using std::vector;

Harness::Harness(std::ostream* results_stream) :
    results_stream(results_stream),
    measurement_count(10),
    repeated_count(10) {}

void Harness::write_to_log(const string& name,
                           const vector<microseconds_d>& timings) const {
  if (results_stream == nullptr) {
    return;
  }

  (*results_stream) << "\"" << name << "\": [";
  for (const auto& duration : timings) {
    auto micros = duration_cast<microseconds_d>(duration);
    (*results_stream) << micros.count() / run_count() << ", ";
  }
  (*results_stream) << "]," << endl;
}

Harness::Statistics Harness::compute_statistics(
    const vector<steady_clock::duration>& timings) const {
  microseconds_d::rep sum = 0;
  microseconds_d::rep sqsum = 0;

  for (const auto& duration : timings) {
    auto micros = duration_cast<microseconds_d>(duration);
    auto count = micros.count();
    sum += count;
    sqsum += count * count;
  }

  auto n = timings.size();
  Statistics stats;
  stats.mean = sum / n;
  stats.stddev = sqrt(sqsum / n - stats.mean * stats.mean);
  return stats;
}
