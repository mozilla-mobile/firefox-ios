import XCTest
import SQLite

class CoreFunctionsTests : XCTestCase {

    func test_round_wrapsDoubleExpressionsWithRoundFunction() {
        AssertSQL("round(\"double\")", double.round())
        AssertSQL("round(\"doubleOptional\")", doubleOptional.round())

        AssertSQL("round(\"double\", 1)", double.round(1))
        AssertSQL("round(\"doubleOptional\", 2)", doubleOptional.round(2))
    }

    func test_random_generatesExpressionWithRandomFunction() {
        AssertSQL("random()", Expression<Int64>.random())
        AssertSQL("random()", Expression<Int>.random())
    }

    func test_length_wrapsStringExpressionWithLengthFunction() {
        AssertSQL("length(\"string\")", string.length)
        AssertSQL("length(\"stringOptional\")", stringOptional.length)
    }

    func test_lowercaseString_wrapsStringExpressionWithLowerFunction() {
        AssertSQL("lower(\"string\")", string.lowercaseString)
        AssertSQL("lower(\"stringOptional\")", stringOptional.lowercaseString)
    }

    func test_uppercaseString_wrapsStringExpressionWithUpperFunction() {
        AssertSQL("upper(\"string\")", string.uppercaseString)
        AssertSQL("upper(\"stringOptional\")", stringOptional.uppercaseString)
    }

    func test_like_buildsExpressionWithLikeOperator() {
        AssertSQL("(\"string\" LIKE 'a%')", string.like("a%"))
        AssertSQL("(\"stringOptional\" LIKE 'b%')", stringOptional.like("b%"))

        AssertSQL("(\"string\" LIKE '%\\%' ESCAPE '\\')", string.like("%\\%", escape: "\\"))
        AssertSQL("(\"stringOptional\" LIKE '_\\_' ESCAPE '\\')", stringOptional.like("_\\_", escape: "\\"))
    }

    func test_glob_buildsExpressionWithGlobOperator() {
        AssertSQL("(\"string\" GLOB 'a*')", string.glob("a*"))
        AssertSQL("(\"stringOptional\" GLOB 'b*')", stringOptional.glob("b*"))
    }

    func test_match_buildsExpressionWithMatchOperator() {
        AssertSQL("(\"string\" MATCH 'a*')", string.match("a*"))
        AssertSQL("(\"stringOptional\" MATCH 'b*')", stringOptional.match("b*"))
    }

    func test_regexp_buildsExpressionWithRegexpOperator() {
        AssertSQL("(\"string\" REGEXP '^.+@.+\\.com$')", string.regexp("^.+@.+\\.com$"))
        AssertSQL("(\"stringOptional\" REGEXP '^.+@.+\\.net$')", stringOptional.regexp("^.+@.+\\.net$"))
    }

    func test_collate_buildsExpressionWithCollateOperator() {
        AssertSQL("(\"string\" COLLATE BINARY)", string.collate(.Binary))
        AssertSQL("(\"string\" COLLATE NOCASE)", string.collate(.Nocase))
        AssertSQL("(\"string\" COLLATE RTRIM)", string.collate(.Rtrim))
        AssertSQL("(\"string\" COLLATE \"CUSTOM\")", string.collate(.Custom("CUSTOM")))

        AssertSQL("(\"stringOptional\" COLLATE BINARY)", stringOptional.collate(.Binary))
        AssertSQL("(\"stringOptional\" COLLATE NOCASE)", stringOptional.collate(.Nocase))
        AssertSQL("(\"stringOptional\" COLLATE RTRIM)", stringOptional.collate(.Rtrim))
        AssertSQL("(\"stringOptional\" COLLATE \"CUSTOM\")", stringOptional.collate(.Custom("CUSTOM")))
    }

    func test_ltrim_wrapsStringWithLtrimFunction() {
        AssertSQL("ltrim(\"string\")", string.ltrim())
        AssertSQL("ltrim(\"stringOptional\")", stringOptional.ltrim())

        AssertSQL("ltrim(\"string\", ' ')", string.ltrim([" "]))
        AssertSQL("ltrim(\"stringOptional\", ' ')", stringOptional.ltrim([" "]))
    }

    func test_ltrim_wrapsStringWithRtrimFunction() {
        AssertSQL("rtrim(\"string\")", string.rtrim())
        AssertSQL("rtrim(\"stringOptional\")", stringOptional.rtrim())

        AssertSQL("rtrim(\"string\", ' ')", string.rtrim([" "]))
        AssertSQL("rtrim(\"stringOptional\", ' ')", stringOptional.rtrim([" "]))
    }

    func test_ltrim_wrapsStringWithTrimFunction() {
        AssertSQL("trim(\"string\")", string.trim())
        AssertSQL("trim(\"stringOptional\")", stringOptional.trim())

        AssertSQL("trim(\"string\", ' ')", string.trim([" "]))
        AssertSQL("trim(\"stringOptional\", ' ')", stringOptional.trim([" "]))
    }

    func test_replace_wrapsStringWithReplaceFunction() {
        AssertSQL("replace(\"string\", '@example.com', '@example.net')", string.replace("@example.com", with: "@example.net"))
        AssertSQL("replace(\"stringOptional\", '@example.net', '@example.com')", stringOptional.replace("@example.net", with: "@example.com"))
    }

    func test_substring_wrapsStringWithSubstrFunction() {
        AssertSQL("substr(\"string\", 1, 2)", string.substring(1, length: 2))
        AssertSQL("substr(\"stringOptional\", 2, 1)", stringOptional.substring(2, length: 1))
    }

    func test_subscriptWithRange_wrapsStringWithSubstrFunction() {
        AssertSQL("substr(\"string\", 1, 2)", string[1..<3])
        AssertSQL("substr(\"stringOptional\", 2, 1)", stringOptional[2..<3])
    }

    func test_nilCoalescingOperator_wrapsOptionalsWithIfnullFunction() {
        AssertSQL("ifnull(\"intOptional\", 1)", intOptional ?? 1)
        // AssertSQL("ifnull(\"doubleOptional\", 1.0)", doubleOptional ?? 1) // rdar://problem/21677256
        XCTAssertEqual("ifnull(\"doubleOptional\", 1.0)", (doubleOptional ?? 1).asSQL())
        AssertSQL("ifnull(\"stringOptional\", 'literal')", stringOptional ?? "literal")

        AssertSQL("ifnull(\"intOptional\", \"int\")", intOptional ?? int)
        AssertSQL("ifnull(\"doubleOptional\", \"double\")", doubleOptional ?? double)
        AssertSQL("ifnull(\"stringOptional\", \"string\")", stringOptional ?? string)

        AssertSQL("ifnull(\"intOptional\", \"intOptional\")", intOptional ?? intOptional)
        AssertSQL("ifnull(\"doubleOptional\", \"doubleOptional\")", doubleOptional ?? doubleOptional)
        AssertSQL("ifnull(\"stringOptional\", \"stringOptional\")", stringOptional ?? stringOptional)
    }

    func test_absoluteValue_wrapsNumberWithAbsFucntion() {
        AssertSQL("abs(\"int\")", int.absoluteValue)
        AssertSQL("abs(\"intOptional\")", intOptional.absoluteValue)

        AssertSQL("abs(\"double\")", double.absoluteValue)
        AssertSQL("abs(\"doubleOptional\")", doubleOptional.absoluteValue)
    }

    func test_contains_buildsExpressionWithInOperator() {
        AssertSQL("(\"string\" IN ('hello', 'world'))", ["hello", "world"].contains(string))
        AssertSQL("(\"stringOptional\" IN ('hello', 'world'))", ["hello", "world"].contains(stringOptional))
    }

}
