// Tests/SwiftProtobufTests/Test_ParsingMerge.swift - Exercise "parsing merge" behavior
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Protobuf decoding defines specific handling when
/// a singular message field appears more than once.
/// This can happen, for example, when partial messages
/// are concatenated.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

class Test_ParsingMerge: XCTestCase {

    func test_Merge() {
        // Repeated fields generator has field1
        var m = ProtobufUnittest_TestParsingMerge.RepeatedFieldsGenerator()

        // Populate 'field1'
        var t1 = ProtobufUnittest_TestAllTypes()
        t1.optionalInt32 = 1
        t1.optionalString = "abc"
        var t2 = ProtobufUnittest_TestAllTypes()
        t2.optionalInt32 = 2 // Should override t1.optionalInt32
        t2.optionalInt64 = 3
        m.field1 = [t1, t2]

        // Populate 'field2'
        m.field2 = [t1, t2]

        // Populate 'field3'
        m.field3 = [t1, t2]

        // Populate group1
        var g1a = ProtobufUnittest_TestParsingMerge.RepeatedFieldsGenerator.Group1()
        var g1b = g1a
        g1a.field1 = t1
        g1b.field1 = t2
        m.group1 = [g1a, g1b]

        // Populate group2
        var g2a = ProtobufUnittest_TestParsingMerge.RepeatedFieldsGenerator.Group2()
        var g2b = g2a
        g2a.field1 = t1
        g2b.field1 = t2
        m.group2 = [g2a, g2b]

        // Encode/decode should merge repeated fields into non-repeated
        do {
            let encoded = try m.serializedData()
            do {
                let decoded = try ProtobufUnittest_TestParsingMerge(serializedData: encoded)

                // requiredAllTypes <== merge of field1
                let field1 = decoded.requiredAllTypes
                XCTAssertEqual(field1.optionalInt32, 2)
                XCTAssertEqual(field1.optionalInt64, 3)
                XCTAssertEqual(field1.optionalString, "abc")

                // optionalAllTypes <== merge of field2
                let field2 = decoded.optionalAllTypes
                XCTAssertEqual(field2.optionalInt32, 2)
                XCTAssertEqual(field2.optionalInt64, 3)
                XCTAssertEqual(field2.optionalString, "abc")

                // repeatedAllTypes <== field3 without merging
                XCTAssertEqual(decoded.repeatedAllTypes, [t1, t2])
                
                // optionalGroup <== merge of repeated group1
                let group1 = decoded.optionalGroup
                XCTAssertEqual(group1.optionalGroupAllTypes.optionalInt32, 2)
                XCTAssertEqual(group1.optionalGroupAllTypes.optionalString, "abc")
                XCTAssertEqual(group1.optionalGroupAllTypes.optionalInt64, 3)

                // repeatedGroup <== no merge from repeated group2
                XCTAssertEqual(decoded.repeatedGroup.count, 2)
                XCTAssertEqual(decoded.repeatedGroup[0].repeatedGroupAllTypes, t1)
                XCTAssertEqual(decoded.repeatedGroup[1].repeatedGroupAllTypes, t2)
            } catch {
                XCTFail("Decoding failed \(encoded)")
            }
        } catch let e {
            XCTFail("Encoding failed for \(m) with error \(e)")
        }
    }

    func test_Merge_Oneof() {
        // This is like the above, but focuses on ensuring a message within a oneof gets
        // reused to merge the submessage.

        // Each time the oneof is changed to a different subfield, the previous state
        // is cleared.

        var m = SwiftUnittest_TestParsingMerge.RepeatedFieldsGenerator()

        var t1 = SwiftUnittest_TestMessage()
        t1.oneofNestedMessage.a = 1
        t1.oneofNestedMessage.b = 1
        var t2 = SwiftUnittest_TestMessage()
        t2.oneofString = "string"
        m.field1 = [t1, t2]
        m.field2 = [t1, t2]

        do {
            let encoded = try m.serializedData()
            do {
                let decoded = try SwiftUnittest_TestParsingMerge(serializedData: encoded)

                // optional_message <== merge of field1
                let field1 = decoded.optionalMessage
                XCTAssertFalse(field1.oneofNestedMessage.hasA)
                XCTAssertFalse(field1.oneofNestedMessage.hasB)
                XCTAssertEqual(field1.oneofString, "string")

                // repeated_message <== field2 without merging
                XCTAssertEqual(decoded.repeatedMessage, [t1, t2])
                            } catch {
                XCTFail("Decoding failed \(encoded)")
            }
        } catch let e {
            XCTFail("Encoding failed for \(m) with error \(e)")
        }

        // Second, including if it is changed back to a message, anything from the first
        // one is lost.

        m = SwiftUnittest_TestParsingMerge.RepeatedFieldsGenerator()

        var t3 = SwiftUnittest_TestMessage()
        t3.oneofNestedMessage.b = 3
        t3.oneofNestedMessage.c = 3
        m.field1 = [t1, t2, t3]
        m.field2 = [t1, t2, t3]

        do {
            let encoded = try m.serializedData()
            do {
                let decoded = try SwiftUnittest_TestParsingMerge(serializedData: encoded)

                // optional_message <== merge of field1
                let field1 = decoded.optionalMessage
                XCTAssertFalse(field1.oneofNestedMessage.hasA)
                XCTAssertEqual(field1.oneofNestedMessage.b, 3)
                XCTAssertEqual(field1.oneofNestedMessage.c, 3)
                XCTAssertEqual(field1.oneofString, "")

                // repeated_message <== field2 without merging
                XCTAssertEqual(decoded.repeatedMessage, [t1, t2, t3])
                            } catch {
                XCTFail("Decoding failed \(encoded)")
            }
        } catch let e {
            XCTFail("Encoding failed for \(m) with error \(e)")
        }


        // But, if the oneofs are set to the message field without chaning between, just like
        // a normal opitional/required message field, the data should be merged.

        m = SwiftUnittest_TestParsingMerge.RepeatedFieldsGenerator()

        m.field1 = [t1, t3]
        m.field2 = [t1, t3]

        // Encode/decode should merge repeated fields into non-repeated
        do {
            let encoded = try m.serializedData()
            do {
                let decoded = try SwiftUnittest_TestParsingMerge(serializedData: encoded)

                // optional_message <== merge of field1
                let field1 = decoded.optionalMessage
                XCTAssertEqual(field1.oneofNestedMessage.a, 1)
                XCTAssertEqual(field1.oneofNestedMessage.b, 3)  // t3 replaces the value in t1
                XCTAssertEqual(field1.oneofNestedMessage.c, 3)

                // repeated_message <== field2 without merging
                XCTAssertEqual(decoded.repeatedMessage, [t1, t3])
                            } catch {
                XCTFail("Decoding failed \(encoded)")
            }
        } catch let e {
            XCTFail("Encoding failed for \(m) with error \(e)")
        }

    }
}
