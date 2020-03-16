// Tests/SwiftProtobufTests/Test_JSON_Array.swift - Exercise JSON flat array coding
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

class Test_JSON_Array: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Proto3Unittest_TestAllTypes

    private func configureTwoObjects(_ o: inout [MessageTestType]) {
        var o1 = MessageTestType()
        o1.optionalInt32 = 1
        o1.optionalInt64 = 2
        o1.optionalUint32 = 3
        o1.optionalUint64 = 4
        o1.optionalSint32 = 5
        o1.optionalSint64 = 6
        o1.optionalFixed32 = 7
        o1.optionalFixed64 = 8
        o1.optionalSfixed32 = 9
        o1.optionalSfixed64 = 10
        o1.optionalFloat = 11
        o1.optionalDouble = 12
        o1.optionalBool = true
        o1.optionalString = "abc"
        o1.optionalBytes = Data([65, 66])
        var nested = MessageTestType.NestedMessage()
        nested.bb = 7
        o1.optionalNestedMessage = nested
        var foreign = Proto3Unittest_ForeignMessage()
        foreign.c = 88
        o1.optionalForeignMessage = foreign
        var importMessage = ProtobufUnittestImport_ImportMessage()
        importMessage.d = -9
        o1.optionalImportMessage = importMessage
        o1.optionalNestedEnum = .baz
        o1.optionalForeignEnum = .foreignBaz
//        o1.optionalImportEnum = .importBaz
        var publicImportMessage = ProtobufUnittestImport_PublicImportMessage()
        publicImportMessage.e = -999999
        o1.optionalPublicImportMessage = publicImportMessage
        o1.repeatedInt32 = [1, 2]
        o1.repeatedInt64 = [3, 4]
        o1.repeatedUint32 = [5, 6]
        o1.repeatedUint64 = [7, 8]
        o1.repeatedSint32 = [9, 10]
        o1.repeatedSint64 = [11, 12]
        o1.repeatedFixed32 = [13, 14]
        o1.repeatedFixed64 = [15, 16]
        o1.repeatedSfixed32 = [17, 18]
        o1.repeatedSfixed64 = [19, 20]
        o1.repeatedFloat = [21, 22]
        o1.repeatedDouble = [23, 24]
        o1.repeatedBool = [true, false]
        o1.repeatedString = ["abc", "def"]
        o1.repeatedBytes = [Data(), Data([65, 66])]
        var nested2 = nested
        nested2.bb = -7
        o1.repeatedNestedMessage = [nested, nested2]
        var foreign2 = foreign
        foreign2.c = -88
        o1.repeatedForeignMessage = [foreign, foreign2]
        var importMessage2 = importMessage
        importMessage2.d = 999999
        o1.repeatedNestedEnum = [.bar, .baz]
        o1.repeatedForeignEnum = [.foreignBar, .foreignBaz]
        var publicImportMessage2 = publicImportMessage
        publicImportMessage2.e = 999999
        o1.oneofUint32 = 99
        o.append(o1)

        let o2 = MessageTestType()
        o.append(o2)
    }

    func testTwoObjectsWithMultipleFields() {
        let expected: String = ("[{"
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
//            + "\"optionalImportEnum\":\"IMPORT_BAZ\","
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
            + "\"repeatedNestedEnum\":[\"BAR\",\"BAZ\"],"
            + "\"repeatedForeignEnum\":[\"FOREIGN_BAR\",\"FOREIGN_BAZ\"],"
            + "\"oneofUint32\":99"
            + "},{}]")
        assertJSONArrayEncode(expected, configure: configureTwoObjects)
    }

    func testRepeatedNestedMessage() {
        assertJSONArrayEncode("[{\"repeatedNestedMessage\":[{\"bb\":1}]},{\"repeatedNestedMessage\":[{\"bb\":1},{\"bb\":2}]}]") {(o: inout [MessageTestType]) in
            var o1 = MessageTestType()
            var sub1 = Proto3Unittest_TestAllTypes.NestedMessage()
            sub1.bb = 1
            o1.repeatedNestedMessage = [sub1]
            o.append(o1)

            var o2 = MessageTestType()
            var sub2 = Proto3Unittest_TestAllTypes.NestedMessage()
            sub2.bb = 1
            var sub3 = Proto3Unittest_TestAllTypes.NestedMessage()
            sub3.bb = 2
            o2.repeatedNestedMessage = [sub2, sub3]
            o.append(o2)
        }

        assertJSONArrayDecodeSucceeds("[{\"repeatedNestedMessage\": []}]") {
            $0[0].repeatedNestedMessage == []
        }

        assertJSONArrayDecodeFails("{\"repeatedNestedMessage\": []}")
    }
}
