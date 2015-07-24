import XCTest
import SQLite

let stringA = Expression<String>(value: "A")
let stringB = Expression<String?>(value: "B")

let int1 = Expression<Int>(value: 1)
let int2 = Expression<Int?>(value: 2)

let double1 = Expression<Double>(value: 1.5)
let double2 = Expression<Double?>(value: 2.5)

let bool0 = Expression<Bool>(value: false)
let bool1 = Expression<Bool?>(value: true)

class ExpressionTests: SQLiteTestCase {

    func AssertSQLContains<T>(SQL: String, _ expression: Expression<T>, _ message: String? = nil, file: String = __FILE__, line: UInt = __LINE__) {
        AssertSQL("SELECT \(SQL) FROM \"users\"", users.select(expression), file: file, line: line)
    }

    override func setUp() {
        createUsersTable()

        super.setUp()
    }

    func test_alias_aliasesExpression() {
        let aliased = stringA.alias("string_a")
        AssertSQLContains("('A') AS \"string_a\"", aliased)
    }

    func test_stringExpressionPlusStringExpression_buildsConcatenatingStringExpression() {
        AssertSQLContains("('A' || 'A')", stringA + stringA)
        AssertSQLContains("('A' || 'B')", stringA + stringB)
        AssertSQLContains("('B' || 'A')", stringB + stringA)
        AssertSQLContains("('B' || 'B')", stringB + stringB)
        AssertSQLContains("('A' || 'B')", stringA + "B")
        AssertSQLContains("('B' || 'A')", stringB + "A")
        AssertSQLContains("('B' || 'A')", "B" + stringA)
        AssertSQLContains("('A' || 'B')", "A" + stringB)
    }

    func test_integerExpression_plusIntegerExpression_buildsAdditiveIntegerExpression() {
        AssertSQLContains("(1 + 1)", int1 + int1)
        AssertSQLContains("(1 + 2)", int1 + int2)
        AssertSQLContains("(2 + 1)", int2 + int1)
        AssertSQLContains("(2 + 2)", int2 + int2)
        AssertSQLContains("(1 + 2)", int1 + 2)
        AssertSQLContains("(2 + 1)", int2 + 1)
        AssertSQLContains("(2 + 1)", 2 + int1)
        AssertSQLContains("(1 + 2)", 1 + int2)
    }

    func test_doubleExpression_plusDoubleExpression_buildsAdditiveDoubleExpression() {
        AssertSQLContains("(1.5 + 1.5)", double1 + double1)
        AssertSQLContains("(1.5 + 2.5)", double1 + double2)
        AssertSQLContains("(2.5 + 1.5)", double2 + double1)
        AssertSQLContains("(2.5 + 2.5)", double2 + double2)
        AssertSQLContains("(1.5 + 2.5)", double1 + 2.5)
        AssertSQLContains("(2.5 + 1.5)", double2 + 1.5)
        AssertSQLContains("(2.5 + 1.5)", 2.5 + double1)
        AssertSQLContains("(1.5 + 2.5)", 1.5 + double2)
    }

    func test_integerExpression_minusIntegerExpression_buildsSubtractiveIntegerExpression() {
        AssertSQLContains("(1 - 1)", int1 - int1)
        AssertSQLContains("(1 - 2)", int1 - int2)
        AssertSQLContains("(2 - 1)", int2 - int1)
        AssertSQLContains("(2 - 2)", int2 - int2)
        AssertSQLContains("(1 - 2)", int1 - 2)
        AssertSQLContains("(2 - 1)", int2 - 1)
        AssertSQLContains("(2 - 1)", 2 - int1)
        AssertSQLContains("(1 - 2)", 1 - int2)
    }

    func test_doubleExpression_minusDoubleExpression_buildsSubtractiveDoubleExpression() {
        AssertSQLContains("(1.5 - 1.5)", double1 - double1)
        AssertSQLContains("(1.5 - 2.5)", double1 - double2)
        AssertSQLContains("(2.5 - 1.5)", double2 - double1)
        AssertSQLContains("(2.5 - 2.5)", double2 - double2)
        AssertSQLContains("(1.5 - 2.5)", double1 - 2.5)
        AssertSQLContains("(2.5 - 1.5)", double2 - 1.5)
        AssertSQLContains("(2.5 - 1.5)", 2.5 - double1)
        AssertSQLContains("(1.5 - 2.5)", 1.5 - double2)
    }

    func test_integerExpression_timesIntegerExpression_buildsMultiplicativeIntegerExpression() {
        AssertSQLContains("(1 * 1)", int1 * int1)
        AssertSQLContains("(1 * 2)", int1 * int2)
        AssertSQLContains("(2 * 1)", int2 * int1)
        AssertSQLContains("(2 * 2)", int2 * int2)
        AssertSQLContains("(1 * 2)", int1 * 2)
        AssertSQLContains("(2 * 1)", int2 * 1)
        AssertSQLContains("(2 * 1)", 2 * int1)
        AssertSQLContains("(1 * 2)", 1 * int2)
    }

    func test_doubleExpression_timesDoubleExpression_buildsMultiplicativeDoubleExpression() {
        AssertSQLContains("(1.5 * 1.5)", double1 * double1)
        AssertSQLContains("(1.5 * 2.5)", double1 * double2)
        AssertSQLContains("(2.5 * 1.5)", double2 * double1)
        AssertSQLContains("(2.5 * 2.5)", double2 * double2)
        AssertSQLContains("(1.5 * 2.5)", double1 * 2.5)
        AssertSQLContains("(2.5 * 1.5)", double2 * 1.5)
        AssertSQLContains("(2.5 * 1.5)", 2.5 * double1)
        AssertSQLContains("(1.5 * 2.5)", 1.5 * double2)
    }

    func test_integerExpression_dividedByIntegerExpression_buildsDivisiveIntegerExpression() {
        AssertSQLContains("(1 / 1)", int1 / int1)
        AssertSQLContains("(1 / 2)", int1 / int2)
        AssertSQLContains("(2 / 1)", int2 / int1)
        AssertSQLContains("(2 / 2)", int2 / int2)
        AssertSQLContains("(1 / 2)", int1 / 2)
        AssertSQLContains("(2 / 1)", int2 / 1)
        AssertSQLContains("(2 / 1)", 2 / int1)
        AssertSQLContains("(1 / 2)", 1 / int2)
    }

    func test_doubleExpression_dividedByDoubleExpression_buildsDivisiveDoubleExpression() {
        AssertSQLContains("(1.5 / 1.5)", double1 / double1)
        AssertSQLContains("(1.5 / 2.5)", double1 / double2)
        AssertSQLContains("(2.5 / 1.5)", double2 / double1)
        AssertSQLContains("(2.5 / 2.5)", double2 / double2)
        AssertSQLContains("(1.5 / 2.5)", double1 / 2.5)
        AssertSQLContains("(2.5 / 1.5)", double2 / 1.5)
        AssertSQLContains("(2.5 / 1.5)", 2.5 / double1)
        AssertSQLContains("(1.5 / 2.5)", 1.5 / double2)
    }

    func test_integerExpression_moduloIntegerExpression_buildsModuloIntegerExpression() {
        AssertSQLContains("(1 % 1)", int1 % int1)
        AssertSQLContains("(1 % 2)", int1 % int2)
        AssertSQLContains("(2 % 1)", int2 % int1)
        AssertSQLContains("(2 % 2)", int2 % int2)
        AssertSQLContains("(1 % 2)", int1 % 2)
        AssertSQLContains("(2 % 1)", int2 % 1)
        AssertSQLContains("(2 % 1)", 2 % int1)
        AssertSQLContains("(1 % 2)", 1 % int2)
    }

    func test_integerExpression_bitShiftLeftIntegerExpression_buildsLeftShiftedIntegerExpression() {
        AssertSQLContains("(1 << 1)", int1 << int1)
        AssertSQLContains("(1 << 2)", int1 << int2)
        AssertSQLContains("(2 << 1)", int2 << int1)
        AssertSQLContains("(2 << 2)", int2 << int2)
        AssertSQLContains("(1 << 2)", int1 << 2)
        AssertSQLContains("(2 << 1)", int2 << 1)
        AssertSQLContains("(2 << 1)", 2 << int1)
        AssertSQLContains("(1 << 2)", 1 << int2)
    }

    func test_integerExpression_bitShiftRightIntegerExpression_buildsRightShiftedIntegerExpression() {
        AssertSQLContains("(1 >> 1)", int1 >> int1)
        AssertSQLContains("(1 >> 2)", int1 >> int2)
        AssertSQLContains("(2 >> 1)", int2 >> int1)
        AssertSQLContains("(2 >> 2)", int2 >> int2)
        AssertSQLContains("(1 >> 2)", int1 >> 2)
        AssertSQLContains("(2 >> 1)", int2 >> 1)
        AssertSQLContains("(2 >> 1)", 2 >> int1)
        AssertSQLContains("(1 >> 2)", 1 >> int2)
    }

    func test_integerExpression_bitwiseAndIntegerExpression_buildsAndedIntegerExpression() {
        AssertSQLContains("(1 & 1)", int1 & int1)
        AssertSQLContains("(1 & 2)", int1 & int2)
        AssertSQLContains("(2 & 1)", int2 & int1)
        AssertSQLContains("(2 & 2)", int2 & int2)
        AssertSQLContains("(1 & 2)", int1 & 2)
        AssertSQLContains("(2 & 1)", int2 & 1)
        AssertSQLContains("(2 & 1)", 2 & int1)
        AssertSQLContains("(1 & 2)", 1 & int2)
    }

    func test_integerExpression_bitwiseOrIntegerExpression_buildsOredIntegerExpression() {
        AssertSQLContains("(1 | 1)", int1 | int1)
        AssertSQLContains("(1 | 2)", int1 | int2)
        AssertSQLContains("(2 | 1)", int2 | int1)
        AssertSQLContains("(2 | 2)", int2 | int2)
        AssertSQLContains("(1 | 2)", int1 | 2)
        AssertSQLContains("(2 | 1)", int2 | 1)
        AssertSQLContains("(2 | 1)", 2 | int1)
        AssertSQLContains("(1 | 2)", 1 | int2)
    }

    func test_integerExpression_bitwiseExclusiveOrIntegerExpression_buildsOredIntegerExpression() {
        AssertSQLContains("(~((1 & 1)) & (1 | 1))", int1 ^ int1)
        AssertSQLContains("(~((1 & 2)) & (1 | 2))", int1 ^ int2)
        AssertSQLContains("(~((2 & 1)) & (2 | 1))", int2 ^ int1)
        AssertSQLContains("(~((2 & 2)) & (2 | 2))", int2 ^ int2)
        AssertSQLContains("(~((1 & 2)) & (1 | 2))", int1 ^ 2)
        AssertSQLContains("(~((2 & 1)) & (2 | 1))", int2 ^ 1)
        AssertSQLContains("(~((2 & 1)) & (2 | 1))", 2 ^ int1)
        AssertSQLContains("(~((1 & 2)) & (1 | 2))", 1 ^ int2)
    }

    func test_bitwiseNot_integerExpression_buildsComplementIntegerExpression() {
        AssertSQLContains("~(1)", ~int1)
        AssertSQLContains("~(2)", ~int2)
    }

    func test_equalityOperator_withEquatableExpressions_buildsBooleanExpression() {
        AssertSQLContains("(0 = 0)", bool0 == bool0)
        AssertSQLContains("(0 = 1)", bool0 == bool1)
        AssertSQLContains("(1 = 0)", bool1 == bool0)
        AssertSQLContains("(1 = 1)", bool1 == bool1)
        AssertSQLContains("(0 = 1)", bool0 == true)
        AssertSQLContains("(1 = 0)", bool1 == false)
        AssertSQLContains("(1 = 0)", true == bool0)
        AssertSQLContains("(0 = 1)", false == bool1)
    }

    func test_inequalityOperator_withEquatableExpressions_buildsBooleanExpression() {
        AssertSQLContains("(0 != 0)", bool0 != bool0)
        AssertSQLContains("(0 != 1)", bool0 != bool1)
        AssertSQLContains("(1 != 0)", bool1 != bool0)
        AssertSQLContains("(1 != 1)", bool1 != bool1)
        AssertSQLContains("(0 != 1)", bool0 != true)
        AssertSQLContains("(1 != 0)", bool1 != false)
        AssertSQLContains("(1 != 0)", true != bool0)
        AssertSQLContains("(0 != 1)", false != bool1)
    }

    func test_greaterThanOperator_withComparableExpressions_buildsBooleanExpression() {
        AssertSQLContains("(1 > 1)", int1 > int1)
        AssertSQLContains("(1 > 2)", int1 > int2)
        AssertSQLContains("(2 > 1)", int2 > int1)
        AssertSQLContains("(2 > 2)", int2 > int2)
        AssertSQLContains("(1 > 2)", int1 > 2)
        AssertSQLContains("(2 > 1)", int2 > 1)
        AssertSQLContains("(2 > 1)", 2 > int1)
        AssertSQLContains("(1 > 2)", 1 > int2)
    }

    func test_greaterThanOrEqualToOperator_withComparableExpressions_buildsBooleanExpression() {
        AssertSQLContains("(1 >= 1)", int1 >= int1)
        AssertSQLContains("(1 >= 2)", int1 >= int2)
        AssertSQLContains("(2 >= 1)", int2 >= int1)
        AssertSQLContains("(2 >= 2)", int2 >= int2)
        AssertSQLContains("(1 >= 2)", int1 >= 2)
        AssertSQLContains("(2 >= 1)", int2 >= 1)
        AssertSQLContains("(2 >= 1)", 2 >= int1)
        AssertSQLContains("(1 >= 2)", 1 >= int2)
    }

    func test_lessThanOperator_withComparableExpressions_buildsBooleanExpression() {
        AssertSQLContains("(1 < 1)", int1 < int1)
        AssertSQLContains("(1 < 2)", int1 < int2)
        AssertSQLContains("(2 < 1)", int2 < int1)
        AssertSQLContains("(2 < 2)", int2 < int2)
        AssertSQLContains("(1 < 2)", int1 < 2)
        AssertSQLContains("(2 < 1)", int2 < 1)
        AssertSQLContains("(2 < 1)", 2 < int1)
        AssertSQLContains("(1 < 2)", 1 < int2)
    }

    func test_lessThanOrEqualToOperator_withComparableExpressions_buildsBooleanExpression() {
        AssertSQLContains("(1 <= 1)", int1 <= int1)
        AssertSQLContains("(1 <= 2)", int1 <= int2)
        AssertSQLContains("(2 <= 1)", int2 <= int1)
        AssertSQLContains("(2 <= 2)", int2 <= int2)
        AssertSQLContains("(1 <= 2)", int1 <= 2)
        AssertSQLContains("(2 <= 1)", int2 <= 1)
        AssertSQLContains("(2 <= 1)", 2 <= int1)
        AssertSQLContains("(1 <= 2)", 1 <= int2)
    }

    func test_unaryMinusOperator_withIntegerExpression_buildsNegativeIntegerExpression() {
        AssertSQLContains("-(1)", -int1)
        AssertSQLContains("-(2)", -int2)
    }

    func test_unaryMinusOperator_withDoubleExpression_buildsNegativeDoubleExpression() {
        AssertSQLContains("-(1.5)", -double1)
        AssertSQLContains("-(2.5)", -double2)
    }

    func test_betweenOperator_withComparableExpression_buildsBetweenBooleanExpression() {
        AssertSQLContains("1 BETWEEN 0 AND 5", 0...5 ~= int1)
        AssertSQLContains("2 BETWEEN 0 AND 5", 0...5 ~= int2)
    }

    func test_likeOperator_withStringExpression_buildsLikeExpression() {
        AssertSQLContains("('A' LIKE 'B%')", like("B%", stringA))
        AssertSQLContains("('B' LIKE 'A%')", like("A%", stringB))
    }

    func test_globOperator_withStringExpression_buildsGlobExpression() {
        AssertSQLContains("('A' GLOB 'B*')", glob("B*", stringA))
        AssertSQLContains("('B' GLOB 'A*')", glob("A*", stringB))
    }

    func test_matchOperator_withStringExpression_buildsMatchExpression() {
        AssertSQLContains("('A' MATCH 'B')", match("B", stringA))
        AssertSQLContains("('B' MATCH 'A')", match("A", stringB))
    }

    func test_collateOperator_withStringExpression_buildsCollationExpression() {
        AssertSQLContains("('A' COLLATE \"BINARY\")", collate(.Binary, stringA))
        AssertSQLContains("('B' COLLATE \"NOCASE\")", collate(.Nocase, stringB))
        AssertSQLContains("('A' COLLATE \"RTRIM\")", collate(.Rtrim, stringA))

        db.create(collation: "NODIACRITIC") { lhs, rhs in
            return lhs.compare(rhs, options: .DiacriticInsensitiveSearch)
        }
        AssertSQLContains("('A' COLLATE \"NODIACRITIC\")", collate(.Custom("NODIACRITIC"), stringA))
    }

    func test_cast_buildsCastingExpressions() {
        let string1 = Expression<String>(value: "10")
        let string2 = Expression<String?>(value: "10")
        AssertSQLContains("CAST ('10' AS REAL)", cast(string1) as Expression<Double>)
        AssertSQLContains("CAST ('10' AS INTEGER)", cast(string1) as Expression<Int>)
        AssertSQLContains("CAST ('10' AS TEXT)", cast(string1) as Expression<String>)
        AssertSQLContains("CAST ('10' AS REAL)", cast(string2) as Expression<Double?>)
        AssertSQLContains("CAST ('10' AS INTEGER)", cast(string2) as Expression<Int?>)
        AssertSQLContains("CAST ('10' AS TEXT)", cast(string2) as Expression<String?>)
    }

    func test_doubleAndOperator_withBooleanExpressions_buildsCompoundExpression() {
        AssertSQLContains("(0 AND 0)", bool0 && bool0)
        AssertSQLContains("(0 AND 1)", bool0 && bool1)
        AssertSQLContains("(1 AND 0)", bool1 && bool0)
        AssertSQLContains("(1 AND 1)", bool1 && bool1)
        AssertSQLContains("(0 AND 1)", bool0 && true)
        AssertSQLContains("(1 AND 0)", bool1 && false)
        AssertSQLContains("(1 AND 0)", true && bool0)
        AssertSQLContains("(0 AND 1)", false && bool1)
    }

    func test_doubleOrOperator_withBooleanExpressions_buildsCompoundExpression() {
        AssertSQLContains("(0 OR 0)", bool0 || bool0)
        AssertSQLContains("(0 OR 1)", bool0 || bool1)
        AssertSQLContains("(1 OR 0)", bool1 || bool0)
        AssertSQLContains("(1 OR 1)", bool1 || bool1)
        AssertSQLContains("(0 OR 1)", bool0 || true)
        AssertSQLContains("(1 OR 0)", bool1 || false)
        AssertSQLContains("(1 OR 0)", true || bool0)
        AssertSQLContains("(0 OR 1)", false || bool1)
    }

    func test_unaryNotOperator_withBooleanExpressions_buildsNotExpression() {
        AssertSQLContains("NOT (0)", !bool0)
        AssertSQLContains("NOT (1)", !bool1)
    }

    func test_absFunction_withNumberExpressions_buildsAbsExpression() {
        let int1 = Expression<Int>(value: -1)
        let int2 = Expression<Int?>(value: -2)

        AssertSQLContains("abs(-1)", abs(int1))
        AssertSQLContains("abs(-2)", abs(int2))
    }

    func test_coalesceFunction_withValueExpressions_buildsCoalesceExpression() {
        let int1 = Expression<Int?>(value: nil as Int?)
        let int2 = Expression<Int?>(value: nil as Int?)
        let int3 = Expression<Int?>(value: 3)

        AssertSQLContains("coalesce(NULL, NULL, 3)", coalesce(int1, int2, int3))
    }

    func test_ifNullFunction_withValueExpressionAndValue_buildsIfNullExpression() {
        let int1 = Expression<Int?>(value: nil as Int?)
        let int2 = Expression<Int?>(value: 2)
        let int3 = Expression<Int>(value: 3)

        AssertSQLContains("ifnull(NULL, 1)", ifnull(int1, 1))
        AssertSQLContains("ifnull(NULL, 1)", int1 ?? 1)
        AssertSQLContains("ifnull(NULL, 2)", ifnull(int1, int2))
        AssertSQLContains("ifnull(NULL, 2)", int1 ?? int2)
        AssertSQLContains("ifnull(NULL, 3)", ifnull(int1, int3))
        AssertSQLContains("ifnull(NULL, 3)", int1 ?? int3)
    }

    func test_lengthFunction_withValueExpression_buildsLengthIntExpression() {
        AssertSQLContains("length('A')", length(stringA))
        AssertSQLContains("length('B')", length(stringB))
    }

    func test_lowerFunction_withStringExpression_buildsLowerStringExpression() {
        AssertSQLContains("lower('A')", lower(stringA))
        AssertSQLContains("lower('B')", lower(stringB))
    }

    func test_ltrimFunction_withStringExpression_buildsTrimmedStringExpression() {
        AssertSQLContains("ltrim('A')", ltrim(stringA))
        AssertSQLContains("ltrim('B')", ltrim(stringB))
    }

    func test_ltrimFunction_withStringExpressionAndReplacementCharacters_buildsTrimmedStringExpression() {
        AssertSQLContains("ltrim('A', 'A?')", ltrim(stringA, "A?"))
        AssertSQLContains("ltrim('B', 'B?')", ltrim(stringB, "B?"))
    }

    func test_randomFunction_buildsRandomIntExpression() {
        AssertSQLContains("random()", random())
    }

    func test_replaceFunction_withStringExpressionAndFindReplaceStrings_buildsReplacedStringExpression() {
        AssertSQLContains("replace('A', 'A', 'B')", replace(stringA, "A", "B"))
        AssertSQLContains("replace('B', 'B', 'A')", replace(stringB, "B", "A"))
    }

    func test_roundFunction_withDoubleExpression_buildsRoundedDoubleExpression() {
        AssertSQLContains("round(1.5)", round(double1))
        AssertSQLContains("round(2.5)", round(double2))
    }

    func test_roundFunction_withDoubleExpressionAndPrecision_buildsRoundedDoubleExpression() {
        AssertSQLContains("round(1.5, 1)", round(double1, 1))
        AssertSQLContains("round(2.5, 1)", round(double2, 1))
    }

    func test_rtrimFunction_withStringExpression_buildsTrimmedStringExpression() {
        AssertSQLContains("rtrim('A')", rtrim(stringA))
        AssertSQLContains("rtrim('B')", rtrim(stringB))
    }

    func test_rtrimFunction_withStringExpressionAndReplacementCharacters_buildsTrimmedStringExpression() {
        AssertSQLContains("rtrim('A', 'A?')", rtrim(stringA, "A?"))
        AssertSQLContains("rtrim('B', 'B?')", rtrim(stringB, "B?"))
    }

    func test_substrFunction_withStringExpressionAndStartIndex_buildsSubstringExpression() {
        AssertSQLContains("substr('A', 1)", substr(stringA, 1))
        AssertSQLContains("substr('B', 1)", substr(stringB, 1))
    }

    func test_substrFunction_withStringExpressionPositionAndLength_buildsSubstringExpression() {
        AssertSQLContains("substr('A', 1, 2)", substr(stringA, 1, 2))
        AssertSQLContains("substr('B', 1, 2)", substr(stringB, 1, 2))
    }

    func test_substrFunction_withStringExpressionAndRange_buildsSubstringExpression() {
        AssertSQLContains("substr('A', 1, 2)", substr(stringA, 1..<3))
        AssertSQLContains("substr('B', 1, 2)", substr(stringB, 1..<3))
    }

    func test_trimFunction_withStringExpression_buildsTrimmedStringExpression() {
        AssertSQLContains("trim('A')", trim(stringA))
        AssertSQLContains("trim('B')", trim(stringB))
    }

    func test_trimFunction_withStringExpressionAndReplacementCharacters_buildsTrimmedStringExpression() {
        AssertSQLContains("trim('A', 'A?')", trim(stringA, "A?"))
        AssertSQLContains("trim('B', 'B?')", trim(stringB, "B?"))
    }

    func test_upperFunction_withStringExpression_buildsLowerStringExpression() {
        AssertSQLContains("upper('A')", upper(stringA))
        AssertSQLContains("upper('B')", upper(stringB))
    }

    let email2 = Expression<String?>("email")
    let age2 = Expression<Int?>("age")
    let salary2 = Expression<Double?>("salary")
    let admin2 = Expression<Bool?>("admin")

    func test_countFunction_withExpression_buildsCountExpression() {
        AssertSQLContains("count(\"age\")", count(age))
        AssertSQLContains("count(\"email\")", count(email2))
        AssertSQLContains("count(\"salary\")", count(salary2))
        AssertSQLContains("count(\"admin\")", count(admin2))
        AssertSQLContains("count(DISTINCT \"id\")", count(distinct: id))
        AssertSQLContains("count(DISTINCT \"age\")", count(distinct: age))
        AssertSQLContains("count(DISTINCT \"email\")", count(distinct: email))
        AssertSQLContains("count(DISTINCT \"email\")", count(distinct: email2))
        AssertSQLContains("count(DISTINCT \"salary\")", count(distinct: salary))
        AssertSQLContains("count(DISTINCT \"salary\")", count(distinct: salary2))
        AssertSQLContains("count(DISTINCT \"admin\")", count(distinct: admin))
        AssertSQLContains("count(DISTINCT \"admin\")", count(distinct: admin2))
    }

    func test_countFunction_withStar_buildsCountExpression() {
        AssertSQLContains("count(*)", count(*))
    }

    func test_maxFunction_withExpression_buildsMaxExpression() {
        AssertSQLContains("max(\"id\")", max(id))
        AssertSQLContains("max(\"age\")", max(age))
        AssertSQLContains("max(\"email\")", max(email))
        AssertSQLContains("max(\"email\")", max(email2))
        AssertSQLContains("max(\"salary\")", max(salary))
        AssertSQLContains("max(\"salary\")", max(salary2))
    }

    func test_minFunction_withExpression_buildsMinExpression() {
        AssertSQLContains("min(\"id\")", min(id))
        AssertSQLContains("min(\"age\")", min(age))
        AssertSQLContains("min(\"email\")", min(email))
        AssertSQLContains("min(\"email\")", min(email2))
        AssertSQLContains("min(\"salary\")", min(salary))
        AssertSQLContains("min(\"salary\")", min(salary2))
    }

    func test_averageFunction_withExpression_buildsAverageExpression() {
        AssertSQLContains("avg(\"id\")", average(id))
        AssertSQLContains("avg(\"age\")", average(age))
        AssertSQLContains("avg(\"salary\")", average(salary))
        AssertSQLContains("avg(\"salary\")", average(salary2))
        AssertSQLContains("avg(DISTINCT \"id\")", average(distinct: id))
        AssertSQLContains("avg(DISTINCT \"age\")", average(distinct: age))
        AssertSQLContains("avg(DISTINCT \"salary\")", average(distinct: salary))
        AssertSQLContains("avg(DISTINCT \"salary\")", average(distinct: salary2))
    }

    func test_sumFunction_withExpression_buildsSumExpression() {
        AssertSQLContains("sum(\"id\")", sum(id))
        AssertSQLContains("sum(\"age\")", sum(age))
        AssertSQLContains("sum(\"salary\")", sum(salary))
        AssertSQLContains("sum(\"salary\")", sum(salary2))
        AssertSQLContains("sum(DISTINCT \"id\")", sum(distinct: id))
        AssertSQLContains("sum(DISTINCT \"age\")", sum(distinct: age))
        AssertSQLContains("sum(DISTINCT \"salary\")", sum(distinct: salary))
        AssertSQLContains("sum(DISTINCT \"salary\")", sum(distinct: salary2))
    }

    func test_totalFunction_withExpression_buildsTotalExpression() {
        AssertSQLContains("total(\"id\")", total(id))
        AssertSQLContains("total(\"age\")", total(age))
        AssertSQLContains("total(\"salary\")", total(salary))
        AssertSQLContains("total(\"salary\")", total(salary2))
        AssertSQLContains("total(DISTINCT \"id\")", total(distinct: id))
        AssertSQLContains("total(DISTINCT \"age\")", total(distinct: age))
        AssertSQLContains("total(DISTINCT \"salary\")", total(distinct: salary))
        AssertSQLContains("total(DISTINCT \"salary\")", total(distinct: salary2))
    }

    func test_containsFunction_withValueExpressionAndValueArray_buildsInExpression() {
        AssertSQLContains("(\"id\" IN (1, 2, 3))", contains([1, 2, 3], id))
        AssertSQLContains("(\"age\" IN (20, 30, 40))", contains([20, 30, 40], age))

        AssertSQLContains("(\"id\" IN (1))", contains(Set([1]), id))
        AssertSQLContains("(\"age\" IN (20))", contains(Set([20]), age))
    }

    func test_containsFunction_withValueExpressionAndQuery_buildsInExpression() {
        let query = users.select(max(age)).group(id)
        AssertSQLContains("(\"id\" IN (SELECT max(\"age\") FROM \"users\" GROUP BY \"id\"))", contains(query, id))
    }

    func test_plusEquals_withStringExpression_buildsSetter() {
        users.update(email += email)!
        users.update(email += email2)!
        users.update(email2 += email)!
        users.update(email2 += email2)!
        AssertSQL("UPDATE \"users\" SET \"email\" = (\"email\" || \"email\")", 4)
    }

    func test_plusEquals_withStringValue_buildsSetter() {
        users.update(email += ".com")!
        users.update(email2 += ".com")!

        AssertSQL("UPDATE \"users\" SET \"email\" = (\"email\" || '.com')", 2)
    }

    func test_plusEquals_withNumberExpression_buildsSetter() {
        users.update(age += age)!
        users.update(age += age2)!
        users.update(age2 += age)!
        users.update(age2 += age2)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" + \"age\")", 4)

        users.update(salary += salary)!
        users.update(salary += salary2)!
        users.update(salary2 += salary)!
        users.update(salary2 += salary2)!
        AssertSQL("UPDATE \"users\" SET \"salary\" = (\"salary\" + \"salary\")", 4)
    }

    func test_plusEquals_withNumberValue_buildsSetter() {
        users.update(age += 1)!
        users.update(age2 += 1)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" + 1)", 2)

        users.update(salary += 100)!
        users.update(salary2 += 100)!
        AssertSQL("UPDATE \"users\" SET \"salary\" = (\"salary\" + 100.0)", 2)
    }

    func test_minusEquals_withNumberExpression_buildsSetter() {
        users.update(age -= age)!
        users.update(age -= age2)!
        users.update(age2 -= age)!
        users.update(age2 -= age2)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" - \"age\")", 4)

        users.update(salary -= salary)!
        users.update(salary -= salary2)!
        users.update(salary2 -= salary)!
        users.update(salary2 -= salary2)!
        AssertSQL("UPDATE \"users\" SET \"salary\" = (\"salary\" - \"salary\")", 4)
    }

    func test_minusEquals_withNumberValue_buildsSetter() {
        users.update(age -= 1)!
        users.update(age2 -= 1)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" - 1)", 2)

        users.update(salary -= 100)!
        users.update(salary2 -= 100)!
        AssertSQL("UPDATE \"users\" SET \"salary\" = (\"salary\" - 100.0)", 2)
    }

    func test_timesEquals_withNumberExpression_buildsSetter() {
        users.update(age *= age)!
        users.update(age *= age2)!
        users.update(age2 *= age)!
        users.update(age2 *= age2)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" * \"age\")", 4)

        users.update(salary *= salary)!
        users.update(salary *= salary2)!
        users.update(salary2 *= salary)!
        users.update(salary2 *= salary2)!
        AssertSQL("UPDATE \"users\" SET \"salary\" = (\"salary\" * \"salary\")", 4)
    }

    func test_timesEquals_withNumberValue_buildsSetter() {
        users.update(age *= 1)!
        users.update(age2 *= 1)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" * 1)", 2)

        users.update(salary *= 100)!
        users.update(salary2 *= 100)!
        AssertSQL("UPDATE \"users\" SET \"salary\" = (\"salary\" * 100.0)", 2)
    }

    func test_divideEquals_withNumberExpression_buildsSetter() {
        users.update(age /= age)!
        users.update(age /= age2)!
        users.update(age2 /= age)!
        users.update(age2 /= age2)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" / \"age\")", 4)

        users.update(salary /= salary)!
        users.update(salary /= salary2)!
        users.update(salary2 /= salary)!
        users.update(salary2 /= salary2)!
        AssertSQL("UPDATE \"users\" SET \"salary\" = (\"salary\" / \"salary\")", 4)
    }

    func test_divideEquals_withNumberValue_buildsSetter() {
        users.update(age /= 1)!
        users.update(age2 /= 1)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" / 1)", 2)

        users.update(salary /= 100)!
        users.update(salary2 /= 100)!
        AssertSQL("UPDATE \"users\" SET \"salary\" = (\"salary\" / 100.0)", 2)
    }

    func test_moduloEquals_withIntegerExpression_buildsSetter() {
        users.update(age %= age)!
        users.update(age %= age2)!
        users.update(age2 %= age)!
        users.update(age2 %= age2)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" % \"age\")", 4)
    }

    func test_moduloEquals_withIntegerValue_buildsSetter() {
        users.update(age %= 10)!
        users.update(age2 %= 10)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" % 10)", 2)
    }

    func test_rightShiftEquals_withIntegerExpression_buildsSetter() {
        users.update(age >>= age)!
        users.update(age >>= age2)!
        users.update(age2 >>= age)!
        users.update(age2 >>= age2)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" >> \"age\")", 4)
    }

    func test_rightShiftEquals_withIntegerValue_buildsSetter() {
        users.update(age >>= 1)!
        users.update(age2 >>= 1)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" >> 1)", 2)
    }

    func test_leftShiftEquals_withIntegerExpression_buildsSetter() {
        users.update(age <<= age)!
        users.update(age <<= age2)!
        users.update(age2 <<= age)!
        users.update(age2 <<= age2)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" << \"age\")", 4)
    }

    func test_leftShiftEquals_withIntegerValue_buildsSetter() {
        users.update(age <<= 1)!
        users.update(age2 <<= 1)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" << 1)", 2)
    }

    func test_bitwiseAndEquals_withIntegerExpression_buildsSetter() {
        users.update(age &= age)!
        users.update(age &= age2)!
        users.update(age2 &= age)!
        users.update(age2 &= age2)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" & \"age\")", 4)
    }

    func test_bitwiseAndEquals_withIntegerValue_buildsSetter() {
        users.update(age &= 1)!
        users.update(age2 &= 1)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" & 1)", 2)
    }

    func test_bitwiseOrEquals_withIntegerExpression_buildsSetter() {
        users.update(age |= age)!
        users.update(age |= age2)!
        users.update(age2 |= age)!
        users.update(age2 |= age2)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" | \"age\")", 4)
    }

    func test_bitwiseOrEquals_withIntegerValue_buildsSetter() {
        users.update(age |= 1)!
        users.update(age2 |= 1)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" | 1)", 2)
    }

    func test_bitwiseExclusiveOrEquals_withIntegerExpression_buildsSetter() {
        users.update(age ^= age)!
        users.update(age ^= age2)!
        users.update(age2 ^= age)!
        users.update(age2 ^= age2)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (~((\"age\" & \"age\")) & (\"age\" | \"age\"))", 4)
    }

    func test_bitwiseExclusiveOrEquals_withIntegerValue_buildsSetter() {
        users.update(age ^= 1)!
        users.update(age2 ^= 1)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (~((\"age\" & 1)) & (\"age\" | 1))", 2)
    }

    func test_postfixPlus_withIntegerValue_buildsSetter() {
        users.update(age++)!
        users.update(age2++)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" + 1)", 2)
    }

    func test_postfixMinus_withIntegerValue_buildsSetter() {
        users.update(age--)!
        users.update(age2--)!
        AssertSQL("UPDATE \"users\" SET \"age\" = (\"age\" - 1)", 2)
    }

    func test_precedencePreserved() {
        let n = Expression<Int>(value: 1)
        AssertSQLContains("(((1 = 1) AND (1 = 1)) OR (1 = 1))", (n == n && n == n) || n == n)
        AssertSQLContains("((1 = 1) AND ((1 = 1) OR (1 = 1)))", n == n && (n == n || n == n))
    }

}
