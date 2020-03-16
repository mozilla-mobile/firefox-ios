// Tests/SwiftProtobufTests/Test_BinaryDecodingOptions.swift - Various Binary tests
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test for the use of BinaryDecodingOptions
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_BinaryDecodingOptions: XCTestCase {

    func testMessageDepthLimit() throws {

        let tests: [([UInt8], Message.Type, ExtensionMap?, [(Int, Bool)])] = [
            // Input, (Limit, success/failure)

            // Messages within messages:     // outer is msg 1
            //     child {                   // sub msg 2
            //       child {                 // sub msg 3
            //         payload {             // sub msg 4
            //           optional_int32: 99
            //         }
            //       }
            //     }
            ([10, 6, 10, 4, 18, 2, 8, 99],
             ProtobufUnittest_NestedTestAllTypes.self,
             nil,  // No Extensions
             [( 10, true ),
              ( 4, true ),
              ( 3, false ),
              ( 2, false )]),

            // Group within messages:        // outer is msg 1
            //     child {                   // sub msg 2
            //       child {                 // sub msg 3
            //         payload {             // sub msg 4
            //           OptionalGroup {     // sub msg 5
            //             a: 98
            //           }
            //         }
            //       }
            //     }
            ([10, 11, 10, 9, 18, 7, 131, 1, 136, 1, 98, 132, 1],
             ProtobufUnittest_NestedTestAllTypes.self,
             nil,  // No Extensions
             [( 10, true ),
              ( 5, true ),
              ( 4, false ),
              ( 3, false )]),

            // Nesting of unknown groups:    // outer is msg 1
            //     4 {                       // sub msg 2
            //       4 {                     // sub msg 3
            //         4 {                   // sub msg 4
            //           1: 1
            //         }
            //       }
            //     }
            // 35 = 0b100011 -> field 4/start group
            // 8, 1 -> field 1/varint, value of 1
            // 36 = 0b100100 -> field 4/end group
            ([35, 35, 35, 8, 1, 36, 36, 36],
             ProtobufUnittest_TestEmptyMessage.self,
             nil,  // No Extensions
             [( 10, true ),
              ( 4, true ),
              ( 3, false ),
              ( 2, false )]),

            // Nested message are on the wire as length delimited, so no depth comes into
            // play when they are unknown message fields.

            // Limit applies to message extension fields:                   // outer is msg 1
            //     [protobuf_unittest.optional_nested_message_extension] {  // sub msg 2
            //       bb: 1
            //     }
            ([146, 1, 2, 8, 1],
             ProtobufUnittest_TestAllExtensions.self,
             ProtobufUnittest_Unittest_Extensions,
             [( 10, true ),
              ( 2, true ),
              ( 1, false )]),

            // Limit applies to group extension fields:                     // outer is msg 1
            //     [protobuf_unittest.optionalgroup_extension] {            // sub msg 2
            //       a: 1
            //     }
            ([131, 1, 136, 1, 1, 132, 1],
             ProtobufUnittest_TestAllExtensions.self,
             ProtobufUnittest_Unittest_Extensions,
             [( 10, true ),
              ( 2, true ),
              ( 1, false )]),
        ]

        for (i, (binaryInput, messageType, extensions, testCases)) in tests.enumerated() {
            for (limit, expectSuccess) in testCases {
                do {
                    var options = BinaryDecodingOptions()
                    options.messageDepthLimit = limit
                    let _ =
                        try messageType.init(serializedData: Data(binaryInput),
                                             extensions: extensions,
                                             options: options)
                    if !expectSuccess {
                        XCTFail("Should not have succeed, pass: \(i), limit: \(limit)")
                    }
                } catch BinaryDecodingError.messageDepthLimit {
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

    func testDiscaringUnknownFields() throws {
        // All tests decode once confirming things show up in unknowns, then decode
        // a second time confirming they were dropped.

        var discardOptions = BinaryDecodingOptions()
        discardOptions.discardUnknownFields = true

        // Unknown fields at the root of a message:
        //   2: 1
        //   3: 0x0000000000000002
        //   4: "\003"
        //   5 {
        //     7: 4
        //   }
        //   6: 0x00000005
        let inputCurrentLevel: [UInt8] = [
            // Field 1, varint of 1
            16, 1,
            // Field 2, fixed64 of 2
            25, 2, 0, 0, 0, 0, 0, 0, 0,
            // Field 3, length delimted of 3
            34, 1, 3,
            // Field 4, group (start, field 6 varinit of 4, end)
            43, 56, 4, 44,
            // Field 5, fixed32 of 5
            53, 5, 0, 0, 0,
        ]
        let inputCurrentLevelData = Data(inputCurrentLevel)
        do {
            let msg1 = try ProtobufUnittest_TestEmptyMessage(serializedData: inputCurrentLevelData)
            XCTAssertEqual(msg1.unknownFields.data, inputCurrentLevelData)

            let msg2 = try ProtobufUnittest_TestEmptyMessage(serializedData: inputCurrentLevelData,
                                                          options: discardOptions)
            XCTAssertTrue(msg2.unknownFields.data.isEmpty)
        }

        // Unknown fields nested within a message field:
        //   optional_nested_message {
        //     2: 1
        //     3: 0x0000000000000002
        //     4: "\003"
        //     5 {
        //       7: 4
        //     }
        //     6: 0x00000005
        //   }
        let inputSubMessage: [UInt8] = [
            // Field 18, length of data, pluse the data
            146, 1, UInt8(inputCurrentLevel.count),
        ] + inputCurrentLevel
        let inputSubMessageData = Data(inputSubMessage)
        do {
            let msg1 = try ProtobufUnittest_TestAllTypes(serializedData: inputSubMessageData)
            XCTAssertTrue(msg1.unknownFields.data.isEmpty)
            XCTAssertEqual(msg1.optionalNestedMessage.unknownFields.data, inputCurrentLevelData)

            let msg2 = try ProtobufUnittest_TestAllTypes(serializedData: inputSubMessageData,
                                                          options: discardOptions)
            XCTAssertTrue(msg2.unknownFields.data.isEmpty)
            XCTAssertTrue(msg2.optionalNestedMessage.unknownFields.data.isEmpty)
        }

        // Unknown fields nested within a message extension field:
        //   [protobuf_unittest.optional_nested_message_extension] {
        //     2: 1
        //     3: 0x0000000000000002
        //     4: "\003"
        //     5 {
        //       7: 4
        //     }
        //     6: 0x00000005
        //   }
        do {
            let msg1 = try ProtobufUnittest_TestAllExtensions(
              serializedData: inputSubMessageData,
              extensions: ProtobufUnittest_Unittest_Extensions)
            XCTAssertTrue(msg1.unknownFields.data.isEmpty)
            XCTAssertEqual(msg1.ProtobufUnittest_optionalNestedMessageExtension.unknownFields.data,
                           inputCurrentLevelData)

            let msg2 = try ProtobufUnittest_TestAllExtensions(
              serializedData: inputSubMessageData,
              extensions: ProtobufUnittest_Unittest_Extensions,
              options: discardOptions)
            XCTAssertTrue(msg2.unknownFields.data.isEmpty)
            XCTAssertTrue(msg2.ProtobufUnittest_optionalNestedMessageExtension.unknownFields.data.isEmpty)
        }

        // Unknown fields nested within a group field:
        //   OptionalGroup {
        //     2: 1
        //     3: 0x0000000000000002
        //     4: "\003"
        //     5 {
        //       7: 4
        //     }
        //     6: 0x00000005
        //   }
        let inputGroup: [UInt8] = [
            // Field 16, start_group
            131, 1,
        ] + inputCurrentLevel + [
            // Field 16, end_group
            132, 1,
        ]
        let inputGroupData = Data(inputGroup)
        do {
            let msg1 = try ProtobufUnittest_TestAllExtensions(
              serializedData: inputGroupData,
              extensions: ProtobufUnittest_Unittest_Extensions)
            XCTAssertTrue(msg1.unknownFields.data.isEmpty)
            XCTAssertEqual(msg1.ProtobufUnittest_optionalGroupExtension.unknownFields.data,
                           inputCurrentLevelData)

            let msg2 = try ProtobufUnittest_TestAllExtensions(
              serializedData: inputGroupData,
              extensions: ProtobufUnittest_Unittest_Extensions,
              options: discardOptions)
            XCTAssertTrue(msg2.unknownFields.data.isEmpty)
            XCTAssertTrue(msg2.ProtobufUnittest_optionalGroupExtension.unknownFields.data.isEmpty)
        }

        // Unknown fields nested within a group extension field:
        //   [protobuf_unittest.optionalgroup_extension] {
        //     2: 1
        //     3: 0x0000000000000002
        //     4: "\003"
        //     5 {
        //       7: 4
        //     }
        //     6: 0x00000005
        //   }
        do {
            let msg1 = try ProtobufUnittest_TestAllTypes(serializedData: inputGroupData)
            XCTAssertTrue(msg1.unknownFields.data.isEmpty)
            XCTAssertEqual(msg1.optionalGroup.unknownFields.data, inputCurrentLevelData)

            let msg2 = try ProtobufUnittest_TestAllTypes(serializedData: inputGroupData,
                                                          options: discardOptions)
            XCTAssertTrue(msg2.unknownFields.data.isEmpty)
            XCTAssertTrue(msg2.optionalGroup.unknownFields.data.isEmpty)
        }

        // An unknown enum value. proto2 syntax unknown enums uses a different code
        // path to end up in unknown fiels, so ensure that is honoring the option.
        // Test data:
        //   optional_nested_enum: 13
        let inputUnknownEnum: [UInt8] = [
            // Field 21, varint
            168, 1, 13
        ]
        let inputUnknownEnumData = Data(inputUnknownEnum)
        do {
            let msg1 = try ProtobufUnittest_TestAllTypes(serializedData: inputUnknownEnumData)
            XCTAssertEqual(msg1.unknownFields.data, inputUnknownEnumData)

            let msg2 = try ProtobufUnittest_TestAllTypes(serializedData: inputUnknownEnumData,
                                                          options: discardOptions)
            XCTAssertTrue(msg2.unknownFields.data.isEmpty)
        }
    }
}
