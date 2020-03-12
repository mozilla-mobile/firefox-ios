// Tests/SwiftProtobufTests/Test_Enum_Proto2.swift - Exercise generated enums
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Check that proto enums are properly translated into Swift enums.  Among
/// other things, enums can have duplicate tags, the names should be correctly
/// translated into Swift lowerCamelCase conventions, etc.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

class Test_Enum_Proto2: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestAllTypes

    func testEqual() {
        XCTAssertEqual(ProtobufUnittest_TestEnumWithDupValue.foo1, ProtobufUnittest_TestEnumWithDupValue.foo2)
        XCTAssertNotEqual(ProtobufUnittest_TestEnumWithDupValue.foo1, ProtobufUnittest_TestEnumWithDupValue.bar1)
    }

    func testUnknownIgnored() {
        // Proto2 requires that unknown enum values be dropped or ignored.
        assertJSONDecodeSucceeds("{\"optionalNestedEnum\":\"FOO\"}") { (m: MessageTestType) -> Bool in
            // If this compiles, then it includes all cases.
            // If it fails to compile because it's missing an "UNRECOGNIZED" case,
            // the code generator has created an UNRECOGNIZED case that should not be there.
            switch m.optionalNestedEnum {
            case .foo: return true
            case .bar: return false
            case .baz: return false
            case .neg: return false
            // DO NOT ADD A DEFAULT CASE TO THIS SWITCH!!!
            }
        }
    }

    func testJSONsingular() {
        assertJSONEncode("{\"optionalNestedEnum\":\"FOO\"}") { (m: inout MessageTestType) in
            m.optionalNestedEnum = ProtobufUnittest_TestAllTypes.NestedEnum.foo
        }
    }

    func testJSONrepeated() {
        assertJSONEncode("{\"repeatedNestedEnum\":[\"FOO\",\"BAR\"]}") { (m: inout MessageTestType) in
            m.repeatedNestedEnum = [.foo, .bar]
        }
    }

    func testUnknownValues() throws {
        let orig = Proto3PreserveUnknownEnumUnittest_MyMessagePlusExtra.with {
            $0.e = .eExtra
            $0.repeatedE.append(.eExtra)
            $0.repeatedPackedE.append(.eExtra)
            $0.oneofE1 = .eExtra
        }

        let origSerialized = try orig.serializedData()
        let msg = try Proto2PreserveUnknownEnumUnittest_MyMessage(serializedData: origSerialized)

        // Nothing should be set, should all be in unknowns.
        XCTAssertFalse(msg.hasE)
        XCTAssertEqual(msg.repeatedE.count, 0)
        XCTAssertEqual(msg.repeatedPackedE.count, 0)
        XCTAssertNil(msg.o)
        XCTAssertFalse(msg.unknownFields.data.isEmpty)

        let msgSerialized = try msg.serializedData()
        let msgPrime = try Proto3PreserveUnknownEnumUnittest_MyMessagePlusExtra(serializedData: msgSerialized)

        // They should be back in the right fields.
        XCTAssertEqual(msgPrime.e, .eExtra)
        XCTAssertEqual(msgPrime.repeatedE, [.eExtra])
        XCTAssertEqual(msgPrime.repeatedPackedE, [.eExtra])
        XCTAssertEqual(msgPrime.o, .oneofE1(.eExtra))
        XCTAssertTrue(msgPrime.unknownFields.data.isEmpty)
    }

    func testEnumPrefixStripping() {
        // This is basicly a compile tests, it is ensuring the expected names were
        // generated, and compile failures mean things didn't generate as expected.

        // Note: "firstValue" and "secondValue" on these, the enum name has been removed.
        XCTAssertEqual(ProtobufUnittest_SwiftEnumTest.EnumTest1.firstValue.rawValue, 1)
        XCTAssertEqual(ProtobufUnittest_SwiftEnumTest.EnumTest1.secondValue.rawValue, 2)
        XCTAssertEqual(ProtobufUnittest_SwiftEnumTest.EnumTest2.firstValue.rawValue, 1)
        XCTAssertEqual(ProtobufUnittest_SwiftEnumTest.EnumTest2.secondValue.rawValue, 2)
        // And these don't use the enum name in the value names, so nothing is trimmed.
        XCTAssertEqual(ProtobufUnittest_SwiftEnumTest.EnumTestNoStem.enumTestNoStem1.rawValue, 1)
        XCTAssertEqual(ProtobufUnittest_SwiftEnumTest.EnumTestNoStem.enumTestNoStem2.rawValue, 2)
        // And this checks handing of reversed words, which means backticks are needed around
        // some of the generated code.
        XCTAssertEqual(ProtobufUnittest_SwiftEnumTest.EnumTestReservedWord.var.rawValue, 1)
        XCTAssertEqual(ProtobufUnittest_SwiftEnumTest.EnumTestReservedWord.notReserved.rawValue, 2)
    }

    func testEnumPrefixStripping_TextFormat() throws {
        var txt = "values1: ENUM_TEST_1_FIRST_VALUE\nvalues1: ENUM_TEST_1_SECOND_VALUE\n"
        var msg = ProtobufUnittest_SwiftEnumTest.with {
            $0.values1 = [ .firstValue, .secondValue ]
        }
        XCTAssertEqual(msg.textFormatString(), txt)
        var msg2 = try ProtobufUnittest_SwiftEnumTest(textFormatString: txt)
        XCTAssertEqual(msg2, msg)

        txt = "values2: ENUM_TEST_2_FIRST_VALUE\nvalues2: SECOND_VALUE\n"
        msg = ProtobufUnittest_SwiftEnumTest.with {
            $0.values2 = [ .firstValue, .secondValue ]
        }
        XCTAssertEqual(msg.textFormatString(), txt)
        msg2 = try ProtobufUnittest_SwiftEnumTest(textFormatString: txt)
        XCTAssertEqual(msg2, msg)

        txt = "values3: ENUM_TEST_NO_STEM_1\nvalues3: ENUM_TEST_NO_STEM_2\n"
        msg = ProtobufUnittest_SwiftEnumTest.with {
            $0.values3 = [ .enumTestNoStem1, .enumTestNoStem2 ]
        }
        XCTAssertEqual(msg.textFormatString(), txt)
        msg2 = try ProtobufUnittest_SwiftEnumTest(textFormatString: txt)
        XCTAssertEqual(msg2, msg)

        txt = "values4: ENUM_TEST_RESERVED_WORD_VAR\nvalues4: ENUM_TEST_RESERVED_WORD_NOT_RESERVED\n"
        msg = ProtobufUnittest_SwiftEnumTest.with {
            $0.values4 = [ .var, .notReserved ]
        }
        XCTAssertEqual(msg.textFormatString(), txt)
        msg2 = try ProtobufUnittest_SwiftEnumTest(textFormatString: txt)
        XCTAssertEqual(msg2, msg)
    }

    func testEnumPrefixStripping_JSON() throws {
        var json = "{\"values1\":[\"ENUM_TEST_1_FIRST_VALUE\",\"ENUM_TEST_1_SECOND_VALUE\"]}"
        var msg = ProtobufUnittest_SwiftEnumTest.with {
            $0.values1 = [ .firstValue, .secondValue ]
        }
        XCTAssertEqual(try msg.jsonString(), json)
        var msg2 = try ProtobufUnittest_SwiftEnumTest(jsonString: json)
        XCTAssertEqual(msg2, msg)

        json = "{\"values2\":[\"ENUM_TEST_2_FIRST_VALUE\",\"SECOND_VALUE\"]}"
        msg = ProtobufUnittest_SwiftEnumTest.with {
            $0.values2 = [ .firstValue, .secondValue ]
        }
        XCTAssertEqual(try msg.jsonString(), json)
        msg2 = try ProtobufUnittest_SwiftEnumTest(jsonString: json)
        XCTAssertEqual(msg2, msg)

        json = "{\"values3\":[\"ENUM_TEST_NO_STEM_1\",\"ENUM_TEST_NO_STEM_2\"]}"
        msg = ProtobufUnittest_SwiftEnumTest.with {
            $0.values3 = [ .enumTestNoStem1, .enumTestNoStem2 ]
        }
        XCTAssertEqual(try msg.jsonString(), json)
        msg2 = try ProtobufUnittest_SwiftEnumTest(jsonString: json)
        XCTAssertEqual(msg2, msg)

        json = "{\"values4\":[\"ENUM_TEST_RESERVED_WORD_VAR\",\"ENUM_TEST_RESERVED_WORD_NOT_RESERVED\"]}"
        msg = ProtobufUnittest_SwiftEnumTest.with {
            $0.values4 = [ .var, .notReserved ]
        }
        XCTAssertEqual(try msg.jsonString(), json)
        msg2 = try ProtobufUnittest_SwiftEnumTest(jsonString: json)
        XCTAssertEqual(msg2, msg)
    }

    func testCaseIterable() {
      #if swift(>=4.2)
        // proto2 syntax enums have allCases generated by the compiled, this
        // just ensures the generator pereserved the order of the file and
        // the handing of aliases doesn't confuse things.
        var i = ProtobufUnittest_SwiftEnumWithAliasTest.EnumWithAlias.allCases.makeIterator()
        guard let e1 = i.next() else {
          XCTFail("Couldn't get first value")
          return
        }
        guard let e2 = i.next() else {
          XCTFail("Couldn't get second value")
          return
        }
        guard let e3 = i.next() else {
          XCTFail("Couldn't get second value")
          return
        }
        // Should be the end.
        XCTAssertNil(i.next())

        XCTAssertEqual(e1, .foo1)
        XCTAssertEqual(e2, .baz1)
        XCTAssertEqual(e3, .bar1)
      #endif
    }
}
