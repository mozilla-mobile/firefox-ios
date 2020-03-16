#!/bin/bash

# SwiftProtobuf/Performance/runners/cpp.sh - C++ test harness runner
#
# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
#
# -----------------------------------------------------------------------------
#
# Functions for running the C++ harness.
#
# -----------------------------------------------------------------------------

function run_cpp_harness() {
  (
    harness="$1"

    source "$script_dir/generators/cpp.sh"

    echo "Generating C++ harness source..."
    gen_harness_path="$script_dir/_generated/Harness+Generated.cc"
    generate_cpp_harness

    echo "Building C++ test harness..."
    time ( g++ --std=c++11 -O \
        -o "$harness" \
        -I "$script_dir" \
        -I "$GOOGLE_PROTOBUF_CHECKOUT/src" \
        -L "$GOOGLE_PROTOBUF_CHECKOUT/src/.libs" \
        -lprotobuf \
        "$gen_harness_path" \
        "$script_dir/Harness.cc" \
        "$script_dir/_generated/message.pb.cc" \
        "$script_dir/main.cc" \
    )
    echo

    # Make sure the dylib is loadable from the harness if the user hasn't
    # actually installed them.
    cp "$GOOGLE_PROTOBUF_CHECKOUT"/src/.libs/libprotobuf.*.dylib \
        "$script_dir/_generated"

    run_harness_and_concatenate_results "C++" "$harness" "$partial_results"
  )
}
