// Tests/SwiftProtobufTests/Test_JSON.swift - Exercise JSON coding
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON is a major new feature for Proto3.  This test suite exercises
/// the JSON coding for all primitive types, including boundary and error
/// cases.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_JSON: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Proto3Unittest_TestAllTypes

    private func configureLargeObject(_ o: inout MessageTestType) {
        o.optionalInt32 = 1
        o.optionalInt64 = 2
        o.optionalUint32 = 3
        o.optionalUint64 = 4
        o.optionalSint32 = 5
        o.optionalSint64 = 6
        o.optionalFixed32 = 7
        o.optionalFixed64 = 8
        o.optionalSfixed32 = 9
        o.optionalSfixed64 = 10
        o.optionalFloat = 11
        o.optionalDouble = 12
        o.optionalBool = true
        o.optionalString = "abc"
        o.optionalBytes = Data([65, 66])
        var nested = MessageTestType.NestedMessage()
        nested.bb = 7
        o.optionalNestedMessage = nested
        var foreign = Proto3Unittest_ForeignMessage()
        foreign.c = 88
        o.optionalForeignMessage = foreign
        var importMessage = ProtobufUnittestImport_ImportMessage()
        importMessage.d = -9
        o.optionalImportMessage = importMessage
        o.optionalNestedEnum = .baz
        o.optionalForeignEnum = .foreignBaz
        var publicImportMessage = ProtobufUnittestImport_PublicImportMessage()
        publicImportMessage.e = -999999
        o.optionalPublicImportMessage = publicImportMessage
        o.repeatedInt32 = [1, 2]
        o.repeatedInt64 = [3, 4]
        o.repeatedUint32 = [5, 6]
        o.repeatedUint64 = [7, 8]
        o.repeatedSint32 = [9, 10]
        o.repeatedSint64 = [11, 12]
        o.repeatedFixed32 = [13, 14]
        o.repeatedFixed64 = [15, 16]
        o.repeatedSfixed32 = [17, 18]
        o.repeatedSfixed64 = [19, 20]
        o.repeatedFloat = [21, 22]
        o.repeatedDouble = [23, 24]
        o.repeatedBool = [true, false]
        o.repeatedString = ["abc", "def"]
        o.repeatedBytes = [Data(), Data([65, 66])]
        var nested2 = nested
        nested2.bb = -7
        o.repeatedNestedMessage = [nested, nested2]
        var foreign2 = foreign
        foreign2.c = -88
        o.repeatedForeignMessage = [foreign, foreign2]
        var importMessage2 = importMessage
        importMessage2.d = 999999
        o.repeatedImportMessage = [importMessage, importMessage2]
        o.repeatedNestedEnum = [.bar, .baz]
        o.repeatedForeignEnum = [.foreignBar, .foreignBaz]
        var publicImportMessage2 = publicImportMessage
        publicImportMessage2.e = 999999
        o.oneofUint32 = 99
    }

    func testMultipleFields() {
        let expected: String = ("{"
            + "\"optionalInt32\":1,"
            + "\"optionalInt64\":\"2\","
            + "\"optionalUint32\":3,"
            + "\"optionalUint64\":\"4\","
            + "\"optionalSint32\":5,"
            + "\"optionalSint64\":\"6\","
            + "\"optionalFixed32\":7,"
            + "\"optionalFixed64\":\"8\","
            + "\"optionalSfixed32\":9,"
            + "\"optionalSfixed64\":\"10\","
            + "\"optionalFloat\":11.0,"
            + "\"optionalDouble\":12.0,"
            + "\"optionalBool\":true,"
            + "\"optionalString\":\"abc\","
            + "\"optionalBytes\":\"QUI=\","
            + "\"optionalNestedMessage\":{\"bb\":7},"
            + "\"optionalForeignMessage\":{\"c\":88},"
            + "\"optionalImportMessage\":{\"d\":-9},"
            + "\"optionalNestedEnum\":\"BAZ\","
            + "\"optionalForeignEnum\":\"FOREIGN_BAZ\","
            + "\"optionalPublicImportMessage\":{\"e\":-999999},"
            + "\"repeatedInt32\":[1,2],"
            + "\"repeatedInt64\":[\"3\",\"4\"],"
            + "\"repeatedUint32\":[5,6],"
            + "\"repeatedUint64\":[\"7\",\"8\"],"
            + "\"repeatedSint32\":[9,10],"
            + "\"repeatedSint64\":[\"11\",\"12\"],"
            + "\"repeatedFixed32\":[13,14],"
            + "\"repeatedFixed64\":[\"15\",\"16\"],"
            + "\"repeatedSfixed32\":[17,18],"
            + "\"repeatedSfixed64\":[\"19\",\"20\"],"
            + "\"repeatedFloat\":[21.0,22.0],"
            + "\"repeatedDouble\":[23.0,24.0],"
            + "\"repeatedBool\":[true,false],"
            + "\"repeatedString\":[\"abc\",\"def\"],"
            + "\"repeatedBytes\":[\"\",\"QUI=\"],"
            + "\"repeatedNestedMessage\":[{\"bb\":7},{\"bb\":-7}],"
            + "\"repeatedForeignMessage\":[{\"c\":88},{\"c\":-88}],"
            + "\"repeatedImportMessage\":[{\"d\":-9},{\"d\":999999}],"
            + "\"repeatedNestedEnum\":[\"BAR\",\"BAZ\"],"
            + "\"repeatedForeignEnum\":[\"FOREIGN_BAR\",\"FOREIGN_BAZ\"],"
            + "\"oneofUint32\":99"
            + "}")
        assertJSONEncode(expected, configure: configureLargeObject)
    }


    // See if we can crash the JSON parser by trying every possible
    // truncation of the large message above.
    func testTruncation() throws {
        var m = MessageTestType()
        configureLargeObject(&m)
        let s = try m.jsonString()
        var truncated = ""
        for c in s {
            truncated.append(c)
            do {
                _ = try MessageTestType(jsonString: truncated)
            } catch _ {
                continue
            }
        }
    }

    func testOptionalInt32() {
        assertJSONEncode("{\"optionalInt32\":1}") {(o: inout MessageTestType) in
            o.optionalInt32 = 1
        }
        assertJSONEncode("{\"optionalInt32\":2147483647}") {(o: inout MessageTestType) in
            o.optionalInt32 = Int32.max
        }
        assertJSONEncode("{\"optionalInt32\":-2147483648}") {(o: inout MessageTestType) in
            o.optionalInt32 = Int32.min
        }
        // 32-bit overflow
        assertJSONDecodeFails("{\"optionalInt32\":2147483648}")
        // Explicit 'null' is permitted, proto3 decodes it to default value
        assertJSONDecodeSucceeds("{\"optionalInt32\":null}") {(o:MessageTestType) in
            o.optionalInt32 == 0}
        // Quoted or unquoted numbers, positive, negative, or zero
        assertJSONDecodeSucceeds("{\"optionalInt32\":1}") {(o:MessageTestType) in
            o.optionalInt32 == 1}
        assertJSONDecodeSucceeds("{\"optionalInt32\":\"1\"}") {(o:MessageTestType) in
            o.optionalInt32 == 1}
        assertJSONDecodeSucceeds("{\"optionalInt32\":\"\\u0030\"}") {(o:MessageTestType) in
            o.optionalInt32 == 0}
        assertJSONDecodeSucceeds("{\"optionalInt32\":\"\\u0031\"}") {(o:MessageTestType) in
            o.optionalInt32 == 1}
        assertJSONDecodeSucceeds("{\"optionalInt32\":\"\\u00310\"}") {(o:MessageTestType) in
            o.optionalInt32 == 10}
        assertJSONDecodeSucceeds("{\"optionalInt32\":0}") {(o:MessageTestType) in
            o.optionalInt32 == 0}
        assertJSONDecodeSucceeds("{\"optionalInt32\":\"0\"}") {(o:MessageTestType) in
            o.optionalInt32 == 0}
        assertJSONDecodeSucceeds("{\"optionalInt32\":-0}") {(o:MessageTestType) in
            o.optionalInt32 == 0}
        assertJSONDecodeSucceeds("{\"optionalInt32\":\"-0\"}") {(o:MessageTestType) in
            o.optionalInt32 == 0}
        assertJSONDecodeSucceeds("{\"optionalInt32\":-1}") {(o:MessageTestType) in
            o.optionalInt32 == -1}
        assertJSONDecodeSucceeds("{\"optionalInt32\":\"-1\"}") {(o:MessageTestType) in
            o.optionalInt32 == -1}
        // JSON RFC does not accept leading zeros
        assertJSONDecodeFails("{\"optionalInt32\":00000000000000000000001}")
        assertJSONDecodeFails("{\"optionalInt32\":\"01\"}")
        assertJSONDecodeFails("{\"optionalInt32\":-01}")
        assertJSONDecodeFails("{\"optionalInt32\":\"-00000000000000000000001\"}")
        // Exponents are okay, as long as result is integer
        assertJSONDecodeSucceeds("{\"optionalInt32\":2.147483647e9}") {(o:MessageTestType) in
            o.optionalInt32 == Int32.max}
        assertJSONDecodeSucceeds("{\"optionalInt32\":-2.147483648e9}") {(o:MessageTestType) in
            o.optionalInt32 == Int32.min}
        assertJSONDecodeSucceeds("{\"optionalInt32\":1e3}") {(o:MessageTestType) in
            o.optionalInt32 == 1000}
        assertJSONDecodeSucceeds("{\"optionalInt32\":100e-2}") {(o:MessageTestType) in
            o.optionalInt32 == 1}
        assertJSONDecodeFails("{\"optionalInt32\":1e-1}")
        // Reject malformed input
        assertJSONDecodeFails("{\"optionalInt32\":\\u0031}")
        assertJSONDecodeFails("{\"optionalInt32\":\"\\u0030\\u0030\"}")
        assertJSONDecodeFails("{\"optionalInt32\":\" 1\"}")
        assertJSONDecodeFails("{\"optionalInt32\":\"1 \"}")
        assertJSONDecodeFails("{\"optionalInt32\":\"01\"}")
        assertJSONDecodeFails("{\"optionalInt32\":true}")
        assertJSONDecodeFails("{\"optionalInt32\":0x102}")
        assertJSONDecodeFails("{\"optionalInt32\":{}}")
        assertJSONDecodeFails("{\"optionalInt32\":[]}")
        // Try to get the library to access past the end of the string...
        assertJSONDecodeFails("{\"optionalInt32\":0")
        assertJSONDecodeFails("{\"optionalInt32\":-0")
        assertJSONDecodeFails("{\"optionalInt32\":0.1")
        assertJSONDecodeFails("{\"optionalInt32\":0.")
        assertJSONDecodeFails("{\"optionalInt32\":1")
        assertJSONDecodeFails("{\"optionalInt32\":\"")
        assertJSONDecodeFails("{\"optionalInt32\":\"1")
        assertJSONDecodeFails("{\"optionalInt32\":\"1\"")
        assertJSONDecodeFails("{\"optionalInt32\":1.")
        assertJSONDecodeFails("{\"optionalInt32\":1e")
        assertJSONDecodeFails("{\"optionalInt32\":1e1")
        assertJSONDecodeFails("{\"optionalInt32\":-1")
        assertJSONDecodeFails("{\"optionalInt32\":123e")
        assertJSONDecodeFails("{\"optionalInt32\":123.")
        assertJSONDecodeFails("{\"optionalInt32\":123")
    }

    func testOptionalUInt32() {
        assertJSONEncode("{\"optionalUint32\":1}") {(o: inout MessageTestType) in
            o.optionalUint32 = 1
        }
        assertJSONEncode("{\"optionalUint32\":4294967295}") {(o: inout MessageTestType) in
            o.optionalUint32 = UInt32.max
        }
        assertJSONDecodeFails("{\"optionalUint32\":4294967296}")
        // Explicit 'null' is permitted, decodes to default
        assertJSONDecodeSucceeds("{\"optionalUint32\":null}") {$0.optionalUint32 == 0}
        // Quoted or unquoted numbers, positive, negative, or zero
        assertJSONDecodeSucceeds("{\"optionalUint32\":1}") {$0.optionalUint32 == 1}
        assertJSONDecodeSucceeds("{\"optionalUint32\":\"1\"}") {$0.optionalUint32 == 1}
        assertJSONDecodeSucceeds("{\"optionalUint32\":0}") {$0.optionalUint32 == 0}
        assertJSONDecodeSucceeds("{\"optionalUint32\":\"0\"}") {$0.optionalUint32 == 0}
        // Protobuf JSON does not accept leading zeros
        assertJSONDecodeFails("{\"optionalUint32\":01}")
        assertJSONDecodeFails("{\"optionalUint32\":\"01\"}")
        // But it does accept exponential (as long as result is integral)
        assertJSONDecodeSucceeds("{\"optionalUint32\":4.294967295e9}") {$0.optionalUint32 == UInt32.max}
        assertJSONDecodeSucceeds("{\"optionalUint32\":1e3}") {$0.optionalUint32 == 1000}
        assertJSONDecodeSucceeds("{\"optionalUint32\":1.2e3}") {$0.optionalUint32 == 1200}
        assertJSONDecodeSucceeds("{\"optionalUint32\":1000e-2}") {$0.optionalUint32 == 10}
        assertJSONDecodeSucceeds("{\"optionalUint32\":1.0}") {$0.optionalUint32 == 1}
        assertJSONDecodeSucceeds("{\"optionalUint32\":1.000000e2}") {$0.optionalUint32 == 100}
        assertJSONDecodeFails("{\"optionalUint32\":1e-3}")
        assertJSONDecodeFails("{\"optionalUint32\":1")
        assertJSONDecodeFails("{\"optionalUint32\":\"")
        assertJSONDecodeFails("{\"optionalUint32\":\"1")
        assertJSONDecodeFails("{\"optionalUint32\":\"1\"")
        assertJSONDecodeFails("{\"optionalUint32\":1.11e1}")
        // Reject malformed input
        assertJSONDecodeFails("{\"optionalUint32\":true}")
        assertJSONDecodeFails("{\"optionalUint32\":-1}")
        assertJSONDecodeFails("{\"optionalUint32\":\"-1\"}")
        assertJSONDecodeFails("{\"optionalUint32\":0x102}")
        assertJSONDecodeFails("{\"optionalUint32\":{}}")
        assertJSONDecodeFails("{\"optionalUint32\":[]}")
    }

    func testOptionalInt64() throws {
        // Protoc JSON always quotes Int64 values
        assertJSONEncode("{\"optionalInt64\":\"9007199254740992\"}") {(o: inout MessageTestType) in
            o.optionalInt64 = 0x20000000000000
        }
        assertJSONEncode("{\"optionalInt64\":\"9007199254740991\"}") {(o: inout MessageTestType) in
            o.optionalInt64 = 0x1fffffffffffff
        }
        assertJSONEncode("{\"optionalInt64\":\"-9007199254740992\"}") {(o: inout MessageTestType) in
            o.optionalInt64 = -0x20000000000000
        }
        assertJSONEncode("{\"optionalInt64\":\"-9007199254740991\"}") {(o: inout MessageTestType) in
            o.optionalInt64 = -0x1fffffffffffff
        }
        assertJSONEncode("{\"optionalInt64\":\"9223372036854775807\"}") {(o: inout MessageTestType) in
            o.optionalInt64 = Int64.max
        }
        assertJSONEncode("{\"optionalInt64\":\"-9223372036854775808\"}") {(o: inout MessageTestType) in
            o.optionalInt64 = Int64.min
        }
        assertJSONEncode("{\"optionalInt64\":\"1\"}") {(o: inout MessageTestType) in
            o.optionalInt64 = 1
        }
        assertJSONEncode("{\"optionalInt64\":\"-1\"}") {(o: inout MessageTestType) in
            o.optionalInt64 = -1
        }

        // 0 is default, so proto3 omits it
        var a = MessageTestType()
        a.optionalInt64 = 0
        XCTAssertEqual(try a.jsonString(), "{}")

        // Decode should work even with unquoted large numbers
        assertJSONDecodeSucceeds("{\"optionalInt64\":9223372036854775807}") {$0.optionalInt64 == Int64.max}
        assertJSONDecodeFails("{\"optionalInt64\":9223372036854775808}")
        assertJSONDecodeSucceeds("{\"optionalInt64\":-9223372036854775808}") {$0.optionalInt64 == Int64.min}
        assertJSONDecodeFails("{\"optionalInt64\":-9223372036854775809}")
        // Protobuf JSON does not accept leading zeros
        assertJSONDecodeFails("{\"optionalInt64\": \"01\" }")
        assertJSONDecodeSucceeds("{\"optionalInt64\": \"1\" }") {$0.optionalInt64 == 1}
        assertJSONDecodeFails("{\"optionalInt64\": \"-01\" }")
        assertJSONDecodeSucceeds("{\"optionalInt64\": \"-1\" }") {$0.optionalInt64 == -1}
        assertJSONDecodeSucceeds("{\"optionalInt64\": \"0\" }") {$0.optionalInt64 == 0}
        // Protobuf JSON does accept exponential format for integer fields
        assertJSONDecodeSucceeds("{\"optionalInt64\":1e3}") {$0.optionalInt64 == 1000}
        assertJSONDecodeSucceeds("{\"optionalInt64\":\"9223372036854775807\"}") {$0.optionalInt64 == Int64.max}
        assertJSONDecodeSucceeds("{\"optionalInt64\":-9.223372036854775808e18}") {$0.optionalInt64 == Int64.min}
        assertJSONDecodeFails("{\"optionalInt64\":9.223372036854775808e18}") // Out of range
        // Explicit 'null' is permitted, decodes to default (in proto3)
        assertJSONDecodeSucceeds("{\"optionalInt64\":null}") {$0.optionalInt64 == 0}
        assertJSONDecodeSucceeds("{\"optionalInt64\":2147483648}") {$0.optionalInt64 == 2147483648}
        assertJSONDecodeSucceeds("{\"optionalInt64\":2147483648}") {$0.optionalInt64 == 2147483648}

        assertJSONDecodeFails("{\"optionalInt64\":1")
        assertJSONDecodeFails("{\"optionalInt64\":\"")
        assertJSONDecodeFails("{\"optionalInt64\":\"1")
        assertJSONDecodeFails("{\"optionalInt64\":\"1\"")
    }

    func testOptionalUInt64() {
        assertJSONEncode("{\"optionalUint64\":\"1\"}") {(o: inout MessageTestType) in
            o.optionalUint64 = 1
        }
        assertJSONEncode("{\"optionalUint64\":\"4294967295\"}") {(o: inout MessageTestType) in
            o.optionalUint64 = UInt64(UInt32.max)
        }
        assertJSONEncode("{\"optionalUint64\":\"18446744073709551615\"}") {(o: inout MessageTestType) in
            o.optionalUint64 = UInt64.max
        }
        // Parse unquoted 64-bit integers
        assertJSONDecodeSucceeds("{\"optionalUint64\":18446744073709551615}") {$0.optionalUint64 == UInt64.max}
        // Accept quoted 64-bit integers with backslash escapes in them
        assertJSONDecodeSucceeds("{\"optionalUint64\":\"184467\\u00344073709551615\"}") {$0.optionalUint64 == UInt64.max}
        // Reject unquoted 64-bit integers with backslash escapes
        assertJSONDecodeFails("{\"optionalUint64\":184467\\u00344073709551615}")
        // Reject out-of-range integers, whether or not quoted
        assertJSONDecodeFails("{\"optionalUint64\":\"18446744073709551616\"}")
        assertJSONDecodeFails("{\"optionalUint64\":18446744073709551616}")
        assertJSONDecodeFails("{\"optionalUint64\":\"184467440737095516109\"}")
        assertJSONDecodeFails("{\"optionalUint64\":184467440737095516109}")

        // Explicit 'null' is permitted, decodes to default
        assertJSONDecodeSucceeds("{\"optionalUint64\":null}") {$0.optionalUint64 == 0}
        // Quoted or unquoted numbers, positive or zero
        assertJSONDecodeSucceeds("{\"optionalUint64\":1}") {$0.optionalUint64 == 1}
        assertJSONDecodeSucceeds("{\"optionalUint64\":\"1\"}") {$0.optionalUint64 == 1}
        assertJSONDecodeSucceeds("{\"optionalUint64\":0}") {$0.optionalUint64 == 0}
        assertJSONDecodeSucceeds("{\"optionalUint64\":\"0\"}") {$0.optionalUint64 == 0}
        // Protobuf JSON does not accept leading zeros
        assertJSONDecodeFails("{\"optionalUint64\":01}")
        assertJSONDecodeFails("{\"optionalUint64\":\"01\"}")
        // But it does accept exponential (as long as result is integral)
        assertJSONDecodeSucceeds("{\"optionalUint64\":4.294967295e9}") {$0.optionalUint64 == UInt64(UInt32.max)}
        assertJSONDecodeSucceeds("{\"optionalUint64\":1e3}") {$0.optionalUint64 == 1000}
        assertJSONDecodeSucceeds("{\"optionalUint64\":1.2e3}") {$0.optionalUint64 == 1200}
        assertJSONDecodeSucceeds("{\"optionalUint64\":1000e-2}") {$0.optionalUint64 == 10}
        assertJSONDecodeSucceeds("{\"optionalUint64\":1.0}") {$0.optionalUint64 == 1}
        assertJSONDecodeSucceeds("{\"optionalUint64\":1.000000e2}") {$0.optionalUint64 == 100}
        assertJSONDecodeFails("{\"optionalUint64\":1e-3}")
        assertJSONDecodeFails("{\"optionalUint64\":1.11e1}")
        // Reject truncated JSON (ending at the beginning, end, or middle of the number
        assertJSONDecodeFails("{\"optionalUint64\":")
        assertJSONDecodeFails("{\"optionalUint64\":1")
        assertJSONDecodeFails("{\"optionalUint64\":\"")
        assertJSONDecodeFails("{\"optionalUint64\":\"1")
        assertJSONDecodeFails("{\"optionalUint64\":\"1\"")
        // Reject malformed input
        assertJSONDecodeFails("{\"optionalUint64\":true}")
        assertJSONDecodeFails("{\"optionalUint64\":-1}")
        assertJSONDecodeFails("{\"optionalUint64\":\"-1\"}")
        assertJSONDecodeFails("{\"optionalUint64\":0x102}")
        assertJSONDecodeFails("{\"optionalUint64\":{}}")
        assertJSONDecodeFails("{\"optionalUint64\":[]}")
    }

    private func assertRoundTripJSON(file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> Void) {
        var original = MessageTestType()
        configure(&original)
        do {
            let json = try original.jsonString()
            do {
                let decoded = try MessageTestType(jsonString: json)
                XCTAssertEqual(original, decoded, file: file, line: line)
            } catch let e {
                XCTFail("Failed to decode \(e): \(json)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Failed to encode \(e)", file: file, line: line)
        }
    }

    func testOptionalDouble() throws {
        assertJSONEncode("{\"optionalDouble\":1.0}") {(o: inout MessageTestType) in
            o.optionalDouble = 1.0
        }
        assertJSONEncode("{\"optionalDouble\":\"Infinity\"}") {(o: inout MessageTestType) in
            o.optionalDouble = Double.infinity
        }
        assertJSONEncode("{\"optionalDouble\":\"-Infinity\"}") {(o: inout MessageTestType) in
            o.optionalDouble = -Double.infinity
        }
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"Inf\"}") {$0.optionalDouble == Double.infinity}
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"-Inf\"}") {$0.optionalDouble == -Double.infinity}
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1\"}") {$0.optionalDouble == 1}
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.0\"}") {$0.optionalDouble == 1.0}
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.5\"}") {$0.optionalDouble == 1.5}
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.5e1\"}") {$0.optionalDouble == 15}
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.5E1\"}") {$0.optionalDouble == 15}
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1\\u002e5e1\"}") {$0.optionalDouble == 15}
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.\\u0035e1\"}") {$0.optionalDouble == 15}
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.5\\u00651\"}") {$0.optionalDouble == 15}
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.5e\\u002b1\"}") {$0.optionalDouble == 15}
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.5e+\\u0031\"}") {$0.optionalDouble == 15}
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.5e+1\"}") {$0.optionalDouble == 15}
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"15e-1\"}") {$0.optionalDouble == 1.5}
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.0e0\"}") {$0.optionalDouble == 1.0}
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"0\"}") {$0.optionalDouble == 0.0}
        assertJSONDecodeSucceeds("{\"optionalDouble\":0}") {$0.optionalDouble == 0.0}
        // We preserve signed zero when decoding
        let d1 = try MessageTestType(jsonString: "{\"optionalDouble\":\"-0\"}")
        XCTAssertEqual(d1.optionalDouble, 0.0)
        XCTAssertEqual(d1.optionalDouble.sign, .minus)
        let d2 = try MessageTestType(jsonString: "{\"optionalDouble\":-0}")
        XCTAssertEqual(d2.optionalDouble, 0.0)
        XCTAssertEqual(d2.optionalDouble.sign, .minus)
        // But re-encoding treats the field as defaulted, so the sign gets lost
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"-0\"}") {$0.optionalDouble == 0.0}
        assertJSONDecodeSucceeds("{\"optionalDouble\":-0}") {$0.optionalDouble == 0.0}

        // Malformed numbers should fail
        assertJSONDecodeFails("{\"optionalDouble\":Infinity}")
        assertJSONDecodeFails("{\"optionalDouble\":-Infinity}") // Must be quoted
        assertJSONDecodeFails("{\"optionalDouble\":\"inf\"}")
        assertJSONDecodeFails("{\"optionalDouble\":\"-inf\"}")
        assertJSONDecodeFails("{\"optionalDouble\":NaN}")
        assertJSONDecodeFails("{\"optionalDouble\":\"nan\"}")
        assertJSONDecodeFails("{\"optionalDouble\":\"1.0.0\"}")
        assertJSONDecodeFails("{\"optionalDouble\":00.1}")
        assertJSONDecodeFails("{\"optionalDouble\":\"00.1\"}")
        assertJSONDecodeFails("{\"optionalDouble\":.1}")
        assertJSONDecodeFails("{\"optionalDouble\":\".1\"}")
        assertJSONDecodeFails("{\"optionalDouble\":1.}")
        assertJSONDecodeFails("{\"optionalDouble\":\"1.\"}")
        assertJSONDecodeFails("{\"optionalDouble\":1e}")
        assertJSONDecodeFails("{\"optionalDouble\":\"1e\"}")
        assertJSONDecodeFails("{\"optionalDouble\":1e+}")
        assertJSONDecodeFails("{\"optionalDouble\":\"1e+\"}")
        assertJSONDecodeFails("{\"optionalDouble\":1e3.2}")
        assertJSONDecodeFails("{\"optionalDouble\":\"1e3.2\"}")
        assertJSONDecodeFails("{\"optionalDouble\":1.0.0}")

        // A wide range of numbers should exactly round-trip
        assertRoundTripJSON {$0.optionalDouble = 0.1}
        assertRoundTripJSON {$0.optionalDouble = 0.01}
        assertRoundTripJSON {$0.optionalDouble = 0.001}
        assertRoundTripJSON {$0.optionalDouble = 0.0001}
        assertRoundTripJSON {$0.optionalDouble = 0.00001}
        assertRoundTripJSON {$0.optionalDouble = 0.000001}
        assertRoundTripJSON {$0.optionalDouble = 1e-10}
        assertRoundTripJSON {$0.optionalDouble = 1e-20}
        assertRoundTripJSON {$0.optionalDouble = 1e-30}
        assertRoundTripJSON {$0.optionalDouble = 1e-40}
        assertRoundTripJSON {$0.optionalDouble = 1e-50}
        assertRoundTripJSON {$0.optionalDouble = 1e-60}
        assertRoundTripJSON {$0.optionalDouble = 1e-100}
        assertRoundTripJSON {$0.optionalDouble = 1e-200}
        assertRoundTripJSON {$0.optionalDouble = Double.pi}
        assertRoundTripJSON {$0.optionalDouble = 123456.789123456789123}
        assertRoundTripJSON {$0.optionalDouble = 1.7976931348623157e+308}
        assertRoundTripJSON {$0.optionalDouble = 2.22507385850720138309e-308}
    }

    func testOptionalFloat() throws {
        assertJSONEncode("{\"optionalFloat\":1.0}") {(o: inout MessageTestType) in
            o.optionalFloat = 1.0
        }
        assertJSONEncode("{\"optionalFloat\":-1.0}") {(o: inout MessageTestType) in
            o.optionalFloat = -1.0
        }
        assertJSONEncode("{\"optionalFloat\":\"Infinity\"}") {(o: inout MessageTestType) in
            o.optionalFloat = Float.infinity
        }
        assertJSONEncode("{\"optionalFloat\":\"-Infinity\"}") {(o: inout MessageTestType) in
            o.optionalFloat = -Float.infinity
        }
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"Inf\"}") {$0.optionalFloat == Float.infinity}
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"-Inf\"}") {$0.optionalFloat == -Float.infinity}
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1\"}") {$0.optionalFloat == 1}
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"-1\"}") {$0.optionalFloat == -1}
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.0\"}") {$0.optionalFloat == 1.0}
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.5\"}") {$0.optionalFloat == 1.5}
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.5e1\"}") {$0.optionalFloat == 15}
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1\\u002e5e1\"}") {$0.optionalFloat == 15}
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.\\u0035e1\"}") {$0.optionalFloat == 15}
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.5\\u00651\"}") {$0.optionalFloat == 15}
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.5e\\u002b1\"}") {$0.optionalFloat == 15}
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.5e+\\u0031\"}") {$0.optionalFloat == 15}
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.5e+1\"}") {$0.optionalFloat == 15}
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"15e-1\"}") {$0.optionalFloat == 1.5}
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.0e0\"}") {$0.optionalFloat == 1.0}
        assertJSONDecodeSucceeds("{\"optionalFloat\":1.0e0}") {$0.optionalFloat == 1.0}
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"0\"}") {$0.optionalFloat == 0.0}
        assertJSONDecodeSucceeds("{\"optionalFloat\":0}") {$0.optionalFloat == 0.0}
        // We preserve signed zero when decoding
        let d1 = try MessageTestType(jsonString: "{\"optionalFloat\":\"-0\"}")
        XCTAssertEqual(d1.optionalFloat, 0.0)
        XCTAssertEqual(d1.optionalFloat.sign, .minus)
        let d2 = try MessageTestType(jsonString: "{\"optionalFloat\":-0}")
        XCTAssertEqual(d2.optionalFloat, 0.0)
        XCTAssertEqual(d2.optionalFloat.sign, .minus)
        // But re-encoding treats the field as defaulted, so the sign gets lost
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"-0\"}") {$0.optionalFloat == 0.0}
        assertJSONDecodeSucceeds("{\"optionalFloat\":-0}") {$0.optionalFloat == 0.0}
        // Malformed numbers should fail
        assertJSONDecodeFails("{\"optionalFloat\":Infinity}")
        assertJSONDecodeFails("{\"optionalFloat\":-Infinity}") // Must be quoted
        assertJSONDecodeFails("{\"optionalFloat\":NaN}")
        assertJSONDecodeFails("{\"optionalFloat\":\"nan\"}")
        assertJSONDecodeFails("{\"optionalFloat\":\"1.0.0\"}")
        assertJSONDecodeFails("{\"optionalFloat\":1.0.0}")
        assertJSONDecodeFails("{\"optionalFloat\":00.1}")
        assertJSONDecodeFails("{\"optionalFloat\":\"00.1\"}")
        assertJSONDecodeFails("{\"optionalFloat\":.1}")
        assertJSONDecodeFails("{\"optionalFloat\":\".1\"}")
        assertJSONDecodeFails("{\"optionalFloat\":\"1")
        assertJSONDecodeFails("{\"optionalFloat\":\"")
        assertJSONDecodeFails("{\"optionalFloat\":1")
        assertJSONDecodeFails("{\"optionalFloat\":1.")
        assertJSONDecodeFails("{\"optionalFloat\":1.}")
        assertJSONDecodeFails("{\"optionalFloat\":\"1.\"}")
        assertJSONDecodeFails("{\"optionalFloat\":1e}")
        assertJSONDecodeFails("{\"optionalFloat\":\"1e\"}")
        assertJSONDecodeFails("{\"optionalFloat\":1e+}")
        assertJSONDecodeFails("{\"optionalFloat\":\"1e+\"}")
        assertJSONDecodeFails("{\"optionalFloat\":1e3.2}")
        assertJSONDecodeFails("{\"optionalFloat\":\"1e3.2\"}")
        // Out-of-range numbers should fail
        assertJSONDecodeFails("{\"optionalFloat\":1e39}")

        // A wide range of numbers should exactly round-trip
        assertRoundTripJSON {$0.optionalFloat = 0.1}
        assertRoundTripJSON {$0.optionalFloat = 0.01}
        assertRoundTripJSON {$0.optionalFloat = 0.001}
        assertRoundTripJSON {$0.optionalFloat = 0.0001}
        assertRoundTripJSON {$0.optionalFloat = 0.00001}
        assertRoundTripJSON {$0.optionalFloat = 0.000001}
        assertRoundTripJSON {$0.optionalFloat = 1.00000075e-36}
        assertRoundTripJSON {$0.optionalFloat = 1e-10}
        assertRoundTripJSON {$0.optionalFloat = 1e-20}
        assertRoundTripJSON {$0.optionalFloat = 1e-30}
        assertRoundTripJSON {$0.optionalFloat = Float(1e-40)}
        assertRoundTripJSON {$0.optionalFloat = Float(1e-50)}
        assertRoundTripJSON {$0.optionalFloat = Float(1e-60)}
        assertRoundTripJSON {$0.optionalFloat = Float(1e-100)}
        assertRoundTripJSON {$0.optionalFloat = Float(1e-200)}
        assertRoundTripJSON {$0.optionalFloat = Float.pi}
        assertRoundTripJSON {$0.optionalFloat = 123456.789123456789123}
        assertRoundTripJSON {$0.optionalFloat = 1999.9999999999}
        assertRoundTripJSON {$0.optionalFloat = 1999.9}
        assertRoundTripJSON {$0.optionalFloat = 1999.99}
        assertRoundTripJSON {$0.optionalFloat = 1999.99}
        assertRoundTripJSON {$0.optionalFloat = 3.402823567e+38}
        assertRoundTripJSON {$0.optionalFloat = 1.1754944e-38}
    }

    func testOptionalDouble_NaN() throws {
        // The helper functions don't work with NaN because NaN != NaN
        var o = Proto3Unittest_TestAllTypes()
        o.optionalDouble = Double.nan
        let encoded = try o.jsonString()
        XCTAssertEqual(encoded, "{\"optionalDouble\":\"NaN\"}")
        let o2 = try Proto3Unittest_TestAllTypes(jsonString: encoded)
        XCTAssert(o2.optionalDouble.isNaN == .some(true))
    }

    func testOptionalFloat_NaN() throws {
        // The helper functions don't work with NaN because NaN != NaN
        var o = Proto3Unittest_TestAllTypes()
        o.optionalFloat = Float.nan
        let encoded = try o.jsonString()
        XCTAssertEqual(encoded, "{\"optionalFloat\":\"NaN\"}")
        do {
            let o2 = try Proto3Unittest_TestAllTypes(jsonString: encoded)
            XCTAssert(o2.optionalFloat.isNaN == .some(true))
        } catch let e {
            XCTFail("Couldn't decode: \(e) -- \(encoded)")
        }
    }

    func testOptionalDouble_roundtrip() throws {
        for _ in 0..<10000 {
            let d = drand48()
            assertRoundTripJSON {$0.optionalDouble = d}
        }
    }

    func testOptionalFloat_roundtrip() throws {
        for _ in 0..<10000 {
            let f = Float(drand48())
            assertRoundTripJSON {$0.optionalFloat = f}
        }
    }

    func testOptionalBool() throws {
        assertJSONEncode("{\"optionalBool\":true}") {(o: inout MessageTestType) in
            o.optionalBool = true
        }

        // False is default, so should not serialize in proto3
        var o = MessageTestType()
        o.optionalBool = false
        XCTAssertEqual(try o.jsonString(), "{}")
    }

    func testOptionalString() {
        assertJSONEncode("{\"optionalString\":\"hello\"}") {(o: inout MessageTestType) in
            o.optionalString = "hello"
        }
        // Start of the C1 range
        assertJSONEncode("{\"optionalString\":\"~\\u007F\\u0080\\u0081\"}") {(o: inout MessageTestType) in
            o.optionalString = "\u{7e}\u{7f}\u{80}\u{81}"
        }
        // End of the C1 range
        assertJSONEncode("{\"optionalString\":\"\\u009E\\u009F ¡¢£\"}") {(o: inout MessageTestType) in
            o.optionalString = "\u{9e}\u{9f}\u{a0}\u{a1}\u{a2}\u{a3}"
        }

        // Empty string is default, so proto3 omits it
        var a = MessageTestType()
        a.optionalString = ""
        XCTAssertEqual(try a.jsonString(), "{}")

        // Example from RFC 7159:  G clef coded as escaped surrogate pair
        assertJSONDecodeSucceeds("{\"optionalString\":\"\\uD834\\uDD1E\"}") {$0.optionalString == "𝄞"}
        // Ditto, with lowercase hex
        assertJSONDecodeSucceeds("{\"optionalString\":\"\\ud834\\udd1e\"}") {$0.optionalString == "𝄞"}
        // Same character represented directly
        assertJSONDecodeSucceeds("{\"optionalString\":\"𝄞\"}") {$0.optionalString == "𝄞"}
        // Various broken surrogate forms
        assertJSONDecodeFails("{\"optionalString\":\"\\uDD1E\\uD834\"}")
        assertJSONDecodeFails("{\"optionalString\":\"\\uDD1E\"}")
        assertJSONDecodeFails("{\"optionalString\":\"\\uD834\"}")
        assertJSONDecodeFails("{\"optionalString\":\"\\uDD1E\\u1234\"}")
    }

    func testOptionalString_controlCharacters() {
        // This is known to fail on Swift Linux 4.1 and earlier,
        // so skip it there.
        // See https://bugs.swift.org/browse/SR-4218 for details.
#if !os(Linux) || swift(>=4.2)
        // Verify that all C0 controls are correctly escaped
        assertJSONEncode("{\"optionalString\":\"\\u0000\\u0001\\u0002\\u0003\\u0004\\u0005\\u0006\\u0007\"}") {(o: inout MessageTestType) in
            o.optionalString = "\u{00}\u{01}\u{02}\u{03}\u{04}\u{05}\u{06}\u{07}"
        }
        assertJSONEncode("{\"optionalString\":\"\\b\\t\\n\\u000B\\f\\r\\u000E\\u000F\"}") {(o: inout MessageTestType) in
            o.optionalString = "\u{08}\u{09}\u{0a}\u{0b}\u{0c}\u{0d}\u{0e}\u{0f}"
        }
        assertJSONEncode("{\"optionalString\":\"\\u0010\\u0011\\u0012\\u0013\\u0014\\u0015\\u0016\\u0017\"}") {(o: inout MessageTestType) in
            o.optionalString = "\u{10}\u{11}\u{12}\u{13}\u{14}\u{15}\u{16}\u{17}"
        }
        assertJSONEncode("{\"optionalString\":\"\\u0018\\u0019\\u001A\\u001B\\u001C\\u001D\\u001E\\u001F\"}") {(o: inout MessageTestType) in
            o.optionalString = "\u{18}\u{19}\u{1a}\u{1b}\u{1c}\u{1d}\u{1e}\u{1f}"
        }
#endif
    }

    func testOptionalBytes() throws {
        // Empty bytes is default, so proto3 omits it
        var a = MessageTestType()
        a.optionalBytes = Data()
        XCTAssertEqual(try a.jsonString(), "{}")

        assertJSONEncode("{\"optionalBytes\":\"AA==\"}") {(o: inout MessageTestType) in
            o.optionalBytes = Data([0])
        }
        assertJSONEncode("{\"optionalBytes\":\"AAA=\"}") {(o: inout MessageTestType) in
            o.optionalBytes = Data([0, 0])
        }
        assertJSONEncode("{\"optionalBytes\":\"AAAA\"}") {(o: inout MessageTestType) in
            o.optionalBytes = Data([0, 0, 0])
        }
        assertJSONEncode("{\"optionalBytes\":\"/w==\"}") {(o: inout MessageTestType) in
            o.optionalBytes = Data([255])
        }
        assertJSONEncode("{\"optionalBytes\":\"//8=\"}") {(o: inout MessageTestType) in
            o.optionalBytes = Data([255, 255])
        }
        assertJSONEncode("{\"optionalBytes\":\"////\"}") {(o: inout MessageTestType) in
            o.optionalBytes = Data([255, 255, 255])
        }
        assertJSONEncode("{\"optionalBytes\":\"QQ==\"}") {(o: inout MessageTestType) in
            o.optionalBytes = Data([65])
        }
        assertJSONDecodeFails("{\"optionalBytes\":\"QQ=\"}")
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"QQ\"}") {
            $0.optionalBytes == Data([65])
        }
        assertJSONEncode("{\"optionalBytes\":\"QUI=\"}") {(o: inout MessageTestType) in
            o.optionalBytes = Data([65, 66])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"QUI\"}") {
            $0.optionalBytes == Data([65, 66])
        }
        assertJSONEncode("{\"optionalBytes\":\"QUJD\"}") {(o: inout MessageTestType) in
            o.optionalBytes = Data([65, 66, 67])
        }
        assertJSONEncode("{\"optionalBytes\":\"QUJDRA==\"}") {(o: inout MessageTestType) in
            o.optionalBytes = Data([65, 66, 67, 68])
        }
        assertJSONDecodeFails("{\"optionalBytes\":\"QUJDRA===\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"QUJDRA=\"}")
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"QUJDRA\"}") {
            $0.optionalBytes == Data([65, 66, 67, 68])
        }
        assertJSONEncode("{\"optionalBytes\":\"QUJDREU=\"}") {(o: inout MessageTestType) in
            o.optionalBytes = Data([65, 66, 67, 68, 69])
        }
        assertJSONDecodeFails("{\"optionalBytes\":\"QUJDREU==\"}")
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"QUJDREU\"}") {
            $0.optionalBytes == Data([65, 66, 67, 68, 69])
        }
        assertJSONEncode("{\"optionalBytes\":\"QUJDREVG\"}") {(o: inout MessageTestType) in
            o.optionalBytes = Data([65, 66, 67, 68, 69, 70])
        }
        assertJSONDecodeFails("{\"optionalBytes\":\"QUJDREVG=\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"QUJDREVG==\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"QUJDREVG===\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"QUJDREVG====\"}")
        // Google's parser accepts and ignores spaces:
        assertJSONDecodeSucceeds("{\"optionalBytes\":\" Q U J D R E U \"}") {
            $0.optionalBytes == Data([65, 66, 67, 68, 69])
        }
        // Accept both RFC4648 Section 4 "base64" and Section 5
        // "URL-safe base64" variants, but reject mixed coding:
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"-_-_\"}") {
            $0.optionalBytes == Data([251, 255, 191])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"+/+/\"}") {
            $0.optionalBytes == Data([251, 255, 191])
        }
        assertJSONDecodeFails("{\"optionalBytes\":\"-_+/\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"-_+\\/\"}")
    }

    func testOptionalBytes_escapes() {
        // Many JSON encoders escape "/":
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"\\/w==\"}") {
            $0.optionalBytes == Data([255])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"\\/w\"}") {
            $0.optionalBytes == Data([255])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"\\/\\/\"}") {
            $0.optionalBytes == Data([255])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"a\\/\"}") {
            $0.optionalBytes == Data([107])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"ab\\/\"}") {
            $0.optionalBytes == Data([105, 191])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"abc\\/\"}") {
            $0.optionalBytes == Data([105, 183, 63])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"\\/a\"}") {
            $0.optionalBytes == Data([253])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"\\/\\/\\/\\/\"}") {
            $0.optionalBytes == Data([255, 255, 255])
        }
        // Most backslash escapes decode to values that are
        // not legal in base-64 encoded strings
        assertJSONDecodeFails("{\"optionalBytes\":\"a\\b\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"a\\f\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"a\\n\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"a\\r\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"a\\t\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"a\\\"\"}")

        // TODO: For completeness, we should support \u1234 escapes
        // assertJSONDecodeSucceeds("{\"optionalBytes\":\"\u0061\u0062\"}")
        // assertJSONDecodeFails("{\"optionalBytes\":\"\u1234\u5678\"}")
    }

    func testOptionalBytes_roundtrip() throws {
        for i in UInt8(0)...UInt8(255) {
            let d = Data([i])
            let message = Proto3Unittest_TestAllTypes.with { $0.optionalBytes = d }
            let text = try message.jsonString()
            let decoded = try Proto3Unittest_TestAllTypes(jsonString: text)
            XCTAssertEqual(decoded, message)
            XCTAssertEqual(message.optionalBytes[0], i)
        }
    }

    func testOptionalNestedMessage() {
        assertJSONEncode("{\"optionalNestedMessage\":{\"bb\":1}}") {(o: inout MessageTestType) in
            var sub = Proto3Unittest_TestAllTypes.NestedMessage()
            sub.bb = 1
            o.optionalNestedMessage = sub
        }
    }

    func testOptionalNestedEnum() {
        assertJSONEncode("{\"optionalNestedEnum\":\"FOO\"}") {(o: inout MessageTestType) in
            o.optionalNestedEnum = Proto3Unittest_TestAllTypes.NestedEnum.foo
        }
        assertJSONDecodeSucceeds("{\"optionalNestedEnum\":1}") {$0.optionalNestedEnum == .foo}
        // Out-of-range values should be serialized to an int
        assertJSONEncode("{\"optionalNestedEnum\":123}") {(o: inout MessageTestType) in
            o.optionalNestedEnum = .UNRECOGNIZED(123)
        }
        // TODO: Check whether Google's spec agrees that unknown Enum tags
        // should fail to parse
        assertJSONDecodeFails("{\"optionalNestedEnum\":\"UNKNOWN\"}")
    }

    func testRepeatedInt32() {
        assertJSONEncode("{\"repeatedInt32\":[1]}") {(o: inout MessageTestType) in
            o.repeatedInt32 = [1]
        }
        assertJSONEncode("{\"repeatedInt32\":[1,2]}") {(o: inout MessageTestType) in
            o.repeatedInt32 = [1, 2]
        }
        assertEncode([250, 1, 2, 1, 2]) {(o: inout MessageTestType) in
            // Proto3 seems to default to packed for repeated int fields
            o.repeatedInt32 = [1, 2]
        }

        assertJSONDecodeSucceeds("{\"repeatedInt32\":null}") {$0.repeatedInt32 == []}
        assertJSONDecodeSucceeds("{\"repeatedInt32\":[]}") {$0.repeatedInt32 == []}
        assertJSONDecodeSucceeds("{\"repeatedInt32\":[1]}") {$0.repeatedInt32 == [1]}
        assertJSONDecodeSucceeds("{\"repeatedInt32\":[1,2]}") {$0.repeatedInt32 == [1, 2]}
    }

    func testRepeatedString() {
        assertJSONEncode("{\"repeatedString\":[\"\"]}") {(o: inout MessageTestType) in
            o.repeatedString = [""]
        }
        assertJSONEncode("{\"repeatedString\":[\"abc\",\"\"]}") {(o: inout MessageTestType) in
            o.repeatedString = ["abc", ""]
        }
        assertJSONDecodeSucceeds("{\"repeatedString\":null}") {$0.repeatedString == []}
        assertJSONDecodeSucceeds("{\"repeatedString\":[]}") {$0.repeatedString == []}
        assertJSONDecodeSucceeds(" { \"repeatedString\" : [ \"1\" , \"2\" ] } ") {
            $0.repeatedString == ["1", "2"]
        }
    }

    func testRepeatedNestedMessage() {
        assertJSONEncode("{\"repeatedNestedMessage\":[{\"bb\":1}]}") {(o: inout MessageTestType) in
            var sub = Proto3Unittest_TestAllTypes.NestedMessage()
            sub.bb = 1
            o.repeatedNestedMessage = [sub]
        }
        assertJSONEncode("{\"repeatedNestedMessage\":[{\"bb\":1},{\"bb\":2}]}") {(o: inout MessageTestType) in
            var sub1 = Proto3Unittest_TestAllTypes.NestedMessage()
            sub1.bb = 1
            var sub2 = Proto3Unittest_TestAllTypes.NestedMessage()
            sub2.bb = 2
            o.repeatedNestedMessage = [sub1, sub2]
        }
        assertJSONDecodeSucceeds("{\"repeatedNestedMessage\": []}") {
            $0.repeatedNestedMessage == []
        }
    }


    // TODO: Test other repeated field types

    func testOneof() {
        assertJSONEncode("{\"oneofUint32\":1}") {(o: inout MessageTestType) in
            o.oneofUint32 = 1
        }
        assertJSONEncode("{\"oneofString\":\"abc\"}") {(o: inout MessageTestType) in
            o.oneofString = "abc"
        }
        assertJSONEncode("{\"oneofNestedMessage\":{\"bb\":1}}") {(o: inout MessageTestType) in
            var sub = Proto3Unittest_TestAllTypes.NestedMessage()
            sub.bb = 1
            o.oneofNestedMessage = sub
        }
        assertJSONDecodeFails("{\"oneofString\": 1}")
        assertJSONDecodeFails("{\"oneofUint32\":1,\"oneofString\":\"abc\"}")
        assertJSONDecodeFails("{\"oneofString\":\"abc\",\"oneofUint32\":1}")
    }

    func testEmptyMessage() {
        assertJSONDecodeSucceeds("{}") {MessageTestType -> Bool in true}
        assertJSONDecodeFails("")
        assertJSONDecodeFails("{")
        assertJSONDecodeFails("}")
    }
}


class Test_JSONPacked: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Proto3Unittest_TestPackedTypes

    func testPackedFloat() {
        assertJSONEncode("{\"packedFloat\":[1.0]}") {(o: inout MessageTestType) in
            o.packedFloat = [1]
        }
        assertJSONEncode("{\"packedFloat\":[1.0,0.25,0.125]}") {(o: inout MessageTestType) in
            o.packedFloat = [1, 0.25, 0.125]
        }
        assertJSONDecodeSucceeds("{\"packedFloat\":[1,0.25,125e-3]}") {
            $0.packedFloat == [1, 0.25, 0.125]
        }
        assertJSONDecodeSucceeds("{\"packedFloat\":null}") {$0.packedFloat == []}
        assertJSONDecodeSucceeds("{\"packedFloat\":[]}") {$0.packedFloat == []}
        assertJSONDecodeSucceeds("{\"packedFloat\":[\"1\"]}") {$0.packedFloat == [1]}
        assertJSONDecodeSucceeds("{\"packedFloat\":[\"1\",2]}") {$0.packedFloat == [1, 2]}
    }

    func testPackedDouble() {
        assertJSONEncode("{\"packedDouble\":[1.0]}") {(o: inout MessageTestType) in
            o.packedDouble = [1]
        }
        assertJSONEncode("{\"packedDouble\":[1.0,0.25,0.125]}") {(o: inout MessageTestType) in
            o.packedDouble = [1, 0.25, 0.125]
        }
        assertJSONDecodeSucceeds("{\"packedDouble\":[1,0.25,125e-3]}") {
            $0.packedDouble == [1, 0.25, 0.125]
        }
        assertJSONDecodeSucceeds("{\"packedDouble\":null}") {$0.packedDouble == []}
        assertJSONDecodeSucceeds("{\"packedDouble\":[]}") {$0.packedDouble == []}
        assertJSONDecodeSucceeds("{\"packedDouble\":[\"1\"]}") {$0.packedDouble == [1]}
        assertJSONDecodeSucceeds("{\"packedDouble\":[\"1\",2]}") {$0.packedDouble == [1, 2]}
    }

    func testPackedInt32() {
        assertJSONEncode("{\"packedInt32\":[1]}") {(o: inout MessageTestType) in
            o.packedInt32 = [1]
        }
        assertJSONEncode("{\"packedInt32\":[1,2]}") {(o: inout MessageTestType) in
            o.packedInt32 = [1, 2]
        }
        assertJSONEncode("{\"packedInt32\":[-2147483648,2147483647]}") {(o: inout MessageTestType) in
            o.packedInt32 = [Int32.min, Int32.max]
        }
        assertJSONDecodeSucceeds("{\"packedInt32\":null}") {$0.packedInt32 == []}
        assertJSONDecodeSucceeds("{\"packedInt32\":[]}") {$0.packedInt32 == []}
        assertJSONDecodeSucceeds("{\"packedInt32\":[\"1\"]}") {$0.packedInt32 == [1]}
        assertJSONDecodeSucceeds("{\"packedInt32\":[\"1\",\"2\"]}") {$0.packedInt32 == [1, 2]}
        assertJSONDecodeSucceeds(" { \"packedInt32\" : [ \"1\" , \"2\" ] } ") {$0.packedInt32 == [1, 2]}
    }

    func testPackedInt64() {
        assertJSONEncode("{\"packedInt64\":[\"1\"]}") {(o: inout MessageTestType) in
            o.packedInt64 = [1]
        }
        assertJSONEncode("{\"packedInt64\":[\"9223372036854775807\",\"-9223372036854775808\"]}") {
            (o: inout MessageTestType) in
            o.packedInt64 = [Int64.max, Int64.min]
        }
        assertJSONDecodeSucceeds("{\"packedInt64\":null}") {$0.packedInt64 == []}
        assertJSONDecodeSucceeds("{\"packedInt64\":[]}") {$0.packedInt64 == []}
        assertJSONDecodeSucceeds("{\"packedInt64\":[1]}") {$0.packedInt64 == [1]}
        assertJSONDecodeSucceeds("{\"packedInt64\":[1,2]}") {$0.packedInt64 == [1, 2]}
        assertJSONDecodeFails("{\"packedInt64\":[null]}")
    }

    func testPackedUInt32() {
        assertJSONEncode("{\"packedUint32\":[1]}") {(o: inout MessageTestType) in
            o.packedUint32 = [1]
        }
        assertJSONEncode("{\"packedUint32\":[0,4294967295]}") {(o: inout MessageTestType) in
            o.packedUint32 = [UInt32.min, UInt32.max]
        }
        assertJSONDecodeSucceeds("{\"packedUint32\":null}") {$0.packedUint32 == []}
        assertJSONDecodeSucceeds("{\"packedUint32\":[]}") {$0.packedUint32 == []}
        assertJSONDecodeSucceeds("{\"packedUint32\":[1]}") {$0.packedUint32 == [1]}
        assertJSONDecodeSucceeds("{\"packedUint32\":[1,2]}") {$0.packedUint32 == [1, 2]}
        assertJSONDecodeFails("{\"packedUint32\":[null]}")
        assertJSONDecodeFails("{\"packedUint32\":[-1]}")
        assertJSONDecodeFails("{\"packedUint32\":[1.2]}")
    }

    func testPackedUInt64() {
        assertJSONEncode("{\"packedUint64\":[\"1\"]}") {(o: inout MessageTestType) in
            o.packedUint64 = [1]
        }
        assertJSONEncode("{\"packedUint64\":[\"0\",\"18446744073709551615\"]}") {
            (o: inout MessageTestType) in
            o.packedUint64 = [UInt64.min, UInt64.max]
        }
        assertJSONDecodeSucceeds("{\"packedUint64\":null}") {$0.packedUint64 == []}
        assertJSONDecodeSucceeds("{\"packedUint64\":[]}") {$0.packedUint64 == []}
        assertJSONDecodeSucceeds("{\"packedUint64\":[1]}") {$0.packedUint64 == [1]}
        assertJSONDecodeSucceeds("{\"packedUint64\":[1,2]}") {$0.packedUint64 == [1, 2]}
        assertJSONDecodeFails("{\"packedUint64\":[null]}")
        assertJSONDecodeFails("{\"packedUint64\":[-1]}")
        assertJSONDecodeFails("{\"packedUint64\":[1.2]}")
    }

    func testPackedSInt32() {
        assertJSONEncode("{\"packedSint32\":[1]}") {(o: inout MessageTestType) in
            o.packedSint32 = [1]
        }
        assertJSONEncode("{\"packedSint32\":[-2147483648,2147483647]}") {(o: inout MessageTestType) in
            o.packedSint32 = [Int32.min, Int32.max]
        }
        assertJSONDecodeSucceeds("{\"packedSint32\":null}") {$0.packedSint32 == []}
        assertJSONDecodeSucceeds("{\"packedSint32\":[]}") {$0.packedSint32 == []}
        assertJSONDecodeSucceeds("{\"packedSint32\":[1]}") {$0.packedSint32 == [1]}
        assertJSONDecodeSucceeds("{\"packedSint32\":[1,2]}") {$0.packedSint32 == [1, 2]}
        assertJSONDecodeFails("{\"packedSint32\":[null]}")
        assertJSONDecodeFails("{\"packedSint32\":[1.2]}")
    }

    func testPackedSInt64() {
        assertJSONEncode("{\"packedSint64\":[\"1\"]}") {(o: inout MessageTestType) in
            o.packedSint64 = [1]
        }
        assertJSONEncode("{\"packedSint64\":[\"-9223372036854775808\",\"9223372036854775807\"]}") {
            (o: inout MessageTestType) in
            o.packedSint64 = [Int64.min, Int64.max]
        }
        assertJSONDecodeSucceeds("{\"packedSint64\":null}") {$0.packedSint64 == []}
        assertJSONDecodeSucceeds("{\"packedSint64\":[]}") {$0.packedSint64 == []}
        assertJSONDecodeSucceeds("{\"packedSint64\":[1]}") {$0.packedSint64 == [1]}
        assertJSONDecodeSucceeds("{\"packedSint64\":[1,2]}") {$0.packedSint64 == [1, 2]}
        assertJSONDecodeFails("{\"packedSint64\":[null]}")
        assertJSONDecodeFails("{\"packedSint64\":[1.2]}")
    }

    func testPackedFixed32() {
        assertJSONEncode("{\"packedFixed32\":[1]}") {(o: inout MessageTestType) in
            o.packedFixed32 = [1]
        }
        assertJSONEncode("{\"packedFixed32\":[0,4294967295]}") {(o: inout MessageTestType) in
            o.packedFixed32 = [UInt32.min, UInt32.max]
        }
        assertJSONDecodeSucceeds("{\"packedFixed32\":null}") {$0.packedFixed32 == []}
        assertJSONDecodeSucceeds("{\"packedFixed32\":[]}") {$0.packedFixed32 == []}
        assertJSONDecodeSucceeds("{\"packedFixed32\":[1]}") {$0.packedFixed32 == [1]}
        assertJSONDecodeSucceeds("{\"packedFixed32\":[1,2]}") {$0.packedFixed32 == [1, 2]}
        assertJSONDecodeFails("{\"packedFixed32\":[null]}")
        assertJSONDecodeFails("{\"packedFixed32\":[-1]}")
        assertJSONDecodeFails("{\"packedFixed32\":[1.2]}")
    }

    func testPackedFixed64() {
        assertJSONEncode("{\"packedFixed64\":[\"1\"]}") {(o: inout MessageTestType) in
            o.packedFixed64 = [1]
        }
        assertJSONEncode("{\"packedFixed64\":[\"0\",\"18446744073709551615\"]}") {
            (o: inout MessageTestType) in
            o.packedFixed64 = [UInt64.min, UInt64.max]
        }
        assertJSONDecodeSucceeds("{\"packedFixed64\":null}") {$0.packedFixed64 == []}
        assertJSONDecodeSucceeds("{\"packedFixed64\":[]}") {$0.packedFixed64 == []}
        assertJSONDecodeSucceeds("{\"packedFixed64\":[1]}") {$0.packedFixed64 == [1]}
        assertJSONDecodeSucceeds("{\"packedFixed64\":[1,2]}") {$0.packedFixed64 == [1, 2]}
        assertJSONDecodeFails("{\"packedFixed64\":[null]}")
        assertJSONDecodeFails("{\"packedFixed64\":[-1]}")
        assertJSONDecodeFails("{\"packedFixed64\":[1.2]}")
    }

    func testPackedSFixed32() {
        assertJSONEncode("{\"packedSfixed32\":[1]}") {(o: inout MessageTestType) in
            o.packedSfixed32 = [1]
        }
        assertJSONEncode("{\"packedSfixed32\":[-2147483648,2147483647]}") {(o: inout MessageTestType) in
            o.packedSfixed32 = [Int32.min, Int32.max]
        }
        assertJSONDecodeSucceeds("{\"packedSfixed32\":null}") {$0.packedSfixed32 == []}
        assertJSONDecodeSucceeds("{\"packedSfixed32\":[]}") {$0.packedSfixed32 == []}
        assertJSONDecodeSucceeds("{\"packedSfixed32\":[1]}") {$0.packedSfixed32 == [1]}
        assertJSONDecodeSucceeds("{\"packedSfixed32\":[1,2]}") {$0.packedSfixed32 == [1, 2]}
        assertJSONDecodeFails("{\"packedSfixed32\":[null]}")
        assertJSONDecodeFails("{\"packedSfixed32\":[1.2]}")
    }

    func testPackedSFixed64() {
        assertJSONEncode("{\"packedSfixed64\":[\"1\"]}") {(o: inout MessageTestType) in
            o.packedSfixed64 = [1]
        }
        assertJSONEncode("{\"packedSfixed64\":[\"-9223372036854775808\",\"9223372036854775807\"]}") {
            (o: inout MessageTestType) in
            o.packedSfixed64 = [Int64.min, Int64.max]
        }
        assertJSONDecodeSucceeds("{\"packedSfixed64\":null}") {$0.packedSfixed64 == []}
        assertJSONDecodeSucceeds("{\"packedSfixed64\":[]}") {$0.packedSfixed64 == []}
        assertJSONDecodeSucceeds("{\"packedSfixed64\":[1]}") {$0.packedSfixed64 == [1]}
        assertJSONDecodeSucceeds("{\"packedSfixed64\":[1,2]}") {$0.packedSfixed64 == [1, 2]}
        assertJSONDecodeFails("{\"packedSfixed64\":[null]}")
        assertJSONDecodeFails("{\"packedSfixed64\":[1.2]}")
    }

    func testPackedBool() {
        assertJSONEncode("{\"packedBool\":[true]}") {(o: inout MessageTestType) in
            o.packedBool = [true]
        }
        assertJSONEncode("{\"packedBool\":[true,false]}") {
            (o: inout MessageTestType) in
            o.packedBool = [true,false]
        }
        assertJSONDecodeSucceeds("{\"packedBool\":null}") {$0.packedBool == []}
        assertJSONDecodeSucceeds("{\"packedBool\":[]}") {$0.packedBool == []}
        assertJSONDecodeFails("{\"packedBool\":[null]}")
        assertJSONDecodeFails("{\"packedBool\":[1,0]}")
        assertJSONDecodeFails("{\"packedBool\":[\"true\"]}")
        assertJSONDecodeFails("{\"packedBool\":[\"false\"]}")
    }
}

class Test_JSONrepeated: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Proto3Unittest_TestUnpackedTypes

    func testPackedInt32() {
        assertJSONEncode("{\"repeatedInt32\":[1]}") {(o: inout MessageTestType) in
            o.repeatedInt32 = [1]
        }
        assertJSONEncode("{\"repeatedInt32\":[1,2]}") {(o: inout MessageTestType) in
            o.repeatedInt32 = [1, 2]
        }
        assertEncode([8, 1, 8, 2]) {(o: inout MessageTestType) in
            o.repeatedInt32 = [1, 2]
        }

        assertJSONDecodeSucceeds("{\"repeatedInt32\":null}") {$0.repeatedInt32 == []}
        assertJSONDecodeSucceeds("{\"repeatedInt32\":[]}") {$0.repeatedInt32 == []}
        assertJSONDecodeSucceeds("{\"repeatedInt32\":[1]}") {$0.repeatedInt32 == [1]}
        assertJSONDecodeSucceeds("{\"repeatedInt32\":[1,2]}") {$0.repeatedInt32 == [1, 2]}
    }
}
