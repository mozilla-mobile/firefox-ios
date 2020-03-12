// Tests/SwiftProtobufTests/Test_JSONDecodingOptions.swift - Various JSON tests
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test for the use of JSONDecodingOptions
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_JSONDecodingOptions: XCTestCase {

    func testMessageDepthLimit() {
        let jsonInputs: [String] = [
            // Proper field names.
            "{ \"a\": { \"a\": { \"i\": 1 } } }",
            // Wrong names, causes the skipping of values to be trigger, which also should
            // honor depth limits.
            "{ \"x\": { \"x\": { \"z\": 1 } } }",
        ]

        let tests: [(Int, Bool)] = [
            // Limit, success/failure
            ( 10, true ),
            ( 4, true ),
            ( 3, true ),
            ( 2, false ),
            ( 1, false ),
        ]

        for (i, jsonInput) in jsonInputs.enumerated() {
            for (limit, expectSuccess) in tests {
                do {
                    var options = JSONDecodingOptions()
                    options.messageDepthLimit = limit
                    options.ignoreUnknownFields = true
                    let _ = try ProtobufUnittest_TestRecursiveMessage(jsonString: jsonInput, options: options)
                    if !expectSuccess {
                        XCTFail("Should not have succeed, pass: \(i), limit: \(limit)")
                    }
                } catch JSONDecodingError.messageDepthLimit {
                    if expectSuccess {
                        XCTFail("Decode failed because of limit, but should *NOT* have, pass: \(i), limit: \(limit)")
                    } else {
                        // Nothing, this is what was expected.
                    }
                } catch let e  {
                    XCTFail("Decode failed (pass: \(i), limit: \(limit) with unexpected error: \(e)")
                }
            }
        }
    }

    func testIgnoreUnknownFields() {
        // (isValidJSON, jsonInput)
        //   isValidJSON - if the input is otherwise valid protobuf JSON, and
        //                 hence should parse when ignoring unknown fields.
        //   jsonInput - The JSON string to parse.
        let jsonInputs: [(Bool, String)] = [
            // Try all the data types.
            (true, "{\"unknown\":7}"),
            (true, "{\"unknown\":null}"),
            (true, "{\"unknown\":false}"),
            (true, "{\"unknown\":true}"),
            (true, "{\"unknown\":  7.0}"),
            (true, "{\"unknown\": -3.04}"),
            (true, "{\"unknown\":  -7.0e-55}"),
            (true, "{\"unknown\":  7.308e+8}"),
            (true, "{\"unknown\": \"hi!\"}"),
            (true, "{\"unknown\": []}"),
            (true, "{\"unknown\": [3, 4, 5]}"),
            (true, "{\"unknown\": [[3], [4], [5, [6, [7], 8, null, \"no\"]]]}"),
            (true, "{\"unknown\": [3, {}, \"5\"]}"),
            (true, "{\"unknown\": {}}"),
            (true, "{\"unknown\": {\"foo\": 1}}"),
            // multiple fields, fails on first.
            (true, "{\"unknown\": 7, \"also_unknown\": 8}"),
            (true, "{\"unknown\": 7, \"zz_unknown\": 8}"),
            // Malformed fields, fails on the field, without trying to parse the value.
            (false, "{\"unknown\":  1e999}"),
            (false, "{\"unknown\": \"hi!\""),
            (false, "{\"unknown\": \"hi!}"),
            (false, "{\"unknown\": qqq }"),
            (false, "{\"unknown\": [ }"),
            (false, "{\"unknown\": { ]}"),
            (false, "{\"unknown\": ]}"),
            (false, "{\"unknown\": nulll }"),
            (false, "{\"unknown\": nul }"),
            (false, "{\"unknown\": Null }"),
            (false, "{\"unknown\": NULL }"),
            (false, "{\"unknown\": True }"),
            (false, "{\"unknown\": False }"),
            (false, "{\"unknown\": nan }"),
            (false, "{\"unknown\": NaN }"),
            (false, "{\"unknown\": Infinity }"),
            (false, "{\"unknown\": infinity }"),
            (false, "{\"unknown\": Inf }"),
            (false, "{\"unknown\": inf }"),
            (false, "{\"unknown\": {1, 2}}"),
            (false, "{\"unknown\": 1.2.3.4.5}"),
            (false, "{\"unknown\": -.04}"),
            (false, "{\"unknown\": -19.}"),
            (false, "{\"unknown\": -9.3e+}"),
            (false, "{\"unknown\": 1 2 3}"),
            (false, "{\"unknown\": { true false }}"),
            // Generally malformed JSON still errors on the field name
            (false, "{\"unknown\": }"),
            (false, "{\"unknown\": null true}"),
            (false, "{\"unknown\": 1}}"),
            (false, "{\"unknown\": { }"),
        ]

        var options = JSONDecodingOptions()
        options.ignoreUnknownFields = true

        for (i, (isValidJSON, jsonInput)) in jsonInputs.enumerated() {
            // Default options (error on unknown fields)
            do {
                let _ = try ProtobufUnittest_TestEmptyMessage(jsonString: jsonInput)
                XCTFail("Input \(i): Should not have gotten here! Input: \(jsonInput)")
            } catch JSONDecodingError.unknownField(let field) {
                XCTAssertEqual(field, "unknown", "Input \(i): got field \(field)")
            } catch let e {
                XCTFail("Input \(i): Error \(e) decoding into an empty message \(jsonInput)")
            }

            // Ignoring unknown fields
            do {
                let _ = try ProtobufUnittest_TestEmptyMessage(jsonString: jsonInput,
                                                              options:options)
                XCTAssertTrue(isValidJSON,
                              "Input \(i): Should not have been able to parse: \(jsonInput)")
            } catch JSONDecodingError.unknownField(let field) {
                XCTFail("Input \(i): should not have gotten unknown field \(field), input \(jsonInput)")
            } catch let e {
                XCTAssertFalse(isValidJSON,
                               "Input \(i): Error \(e): Should have been able to parse: \(jsonInput)")
            }
        }
    }

}
