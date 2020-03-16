#!/usr/bin/awk -f

# ProtobufRuntime/Sources/Protobuf/ProtobufBinaryEncoding.swift - Binary encoding support
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
# The Linux version of XCTest cannot automatically
# discover tests at run-time.  So you can either manually
# maintain lists of tests or collect them at build time.
#
# This script is used by the Makefile to do the latter:
#  = Scans each XCTest source file for 'class Foo: XCTestCase'
#  = Looks for 'func test*' within those classes
#  = Emits a class extension with the necessary 'allTests' property
#  = Emits an XCTMain invocation to run all the classes
#
# The macOS version of XCTest has another mechanism for
# finding tests at run-time, so this is not needed there.
#
# -----------------------------------------------------------------------------

BEGIN {
    CLASS=""
    TESTCASES=""
    TESTCASE_separator=""
    printf("//\n")
    printf("// GENERATED FILE\n")
    printf("// DO NOT EDIT\n")
    printf("//\n")
    printf("\n")
    printf("import XCTest\n")
    printf("@testable import SwiftProtobufTests\n")
    printf("@testable import SwiftProtobufPluginLibraryTests\n")
    printf("\n")
}

/class .*:.* XCTestCase/ {
    if (CLASS != "") {
	printf("\n    ]\n")
	printf("}\n")
    }
    split($0, a, ":")
    split(a[1], words, " ")
    CLASS=words[2]
    TESTCASES = TESTCASES TESTCASE_separator "\n" "        testCase(" CLASS ".allTests)"
    TESTCASE_separator = ","
    printf("\n")
    printf("extension %s {\n", CLASS)
    printf("    static var allTests = [")
    FUNC_separator=""
}


/^ *func *test.*/ {
    split($0, a, "(")
    split(a[1], words, " ")
    FUNC=words[2]
    printf("")
    printf("%s\n        (\"%s\", %s)", FUNC_separator, FUNC, FUNC)
    FUNC_separator = ","
}

END {
    if (CLASS != "") {
	printf("\n    ]\n")
	printf("}\n")
    }
    printf("\n")

    printf("XCTMain(\n")
    printf("    [")
    printf(TESTCASES)
    printf("\n    ]\n)\n")
}
