import XCTest
import SQLite

class OperatorsTests : XCTestCase {

    func test_stringExpressionPlusStringExpression_buildsConcatenatingStringExpression() {
        AssertSQL("(\"string\" || \"string\")", string + string)
        AssertSQL("(\"string\" || \"stringOptional\")", string + stringOptional)
        AssertSQL("(\"stringOptional\" || \"string\")", stringOptional + string)
        AssertSQL("(\"stringOptional\" || \"stringOptional\")", stringOptional + stringOptional)
        AssertSQL("(\"string\" || 'literal')", string + "literal")
        AssertSQL("(\"stringOptional\" || 'literal')", stringOptional + "literal")
        AssertSQL("('literal' || \"string\")", "literal" + string)
        AssertSQL("('literal' || \"stringOptional\")", "literal" + stringOptional)
    }

    func test_numberExpression_plusNumberExpression_buildsAdditiveNumberExpression() {
        AssertSQL("(\"int\" + \"int\")", int + int)
        AssertSQL("(\"int\" + \"intOptional\")", int + intOptional)
        AssertSQL("(\"intOptional\" + \"int\")", intOptional + int)
        AssertSQL("(\"intOptional\" + \"intOptional\")", intOptional + intOptional)
        AssertSQL("(\"int\" + 1)", int + 1)
        AssertSQL("(\"intOptional\" + 1)", intOptional + 1)
        AssertSQL("(1 + \"int\")", 1 + int)
        AssertSQL("(1 + \"intOptional\")", 1 + intOptional)

        AssertSQL("(\"double\" + \"double\")", double + double)
        AssertSQL("(\"double\" + \"doubleOptional\")", double + doubleOptional)
        AssertSQL("(\"doubleOptional\" + \"double\")", doubleOptional + double)
        AssertSQL("(\"doubleOptional\" + \"doubleOptional\")", doubleOptional + doubleOptional)
        AssertSQL("(\"double\" + 1.0)", double + 1)
        AssertSQL("(\"doubleOptional\" + 1.0)", doubleOptional + 1)
        AssertSQL("(1.0 + \"double\")", 1 + double)
        AssertSQL("(1.0 + \"doubleOptional\")", 1 + doubleOptional)
    }

    func test_numberExpression_minusNumberExpression_buildsSubtractiveNumberExpression() {
        AssertSQL("(\"int\" - \"int\")", int - int)
        AssertSQL("(\"int\" - \"intOptional\")", int - intOptional)
        AssertSQL("(\"intOptional\" - \"int\")", intOptional - int)
        AssertSQL("(\"intOptional\" - \"intOptional\")", intOptional - intOptional)
        AssertSQL("(\"int\" - 1)", int - 1)
        AssertSQL("(\"intOptional\" - 1)", intOptional - 1)
        AssertSQL("(1 - \"int\")", 1 - int)
        AssertSQL("(1 - \"intOptional\")", 1 - intOptional)

        AssertSQL("(\"double\" - \"double\")", double - double)
        AssertSQL("(\"double\" - \"doubleOptional\")", double - doubleOptional)
        AssertSQL("(\"doubleOptional\" - \"double\")", doubleOptional - double)
        AssertSQL("(\"doubleOptional\" - \"doubleOptional\")", doubleOptional - doubleOptional)
        AssertSQL("(\"double\" - 1.0)", double - 1)
        AssertSQL("(\"doubleOptional\" - 1.0)", doubleOptional - 1)
        AssertSQL("(1.0 - \"double\")", 1 - double)
        AssertSQL("(1.0 - \"doubleOptional\")", 1 - doubleOptional)
    }

    func test_numberExpression_timesNumberExpression_buildsMultiplicativeNumberExpression() {
        AssertSQL("(\"int\" * \"int\")", int * int)
        AssertSQL("(\"int\" * \"intOptional\")", int * intOptional)
        AssertSQL("(\"intOptional\" * \"int\")", intOptional * int)
        AssertSQL("(\"intOptional\" * \"intOptional\")", intOptional * intOptional)
        AssertSQL("(\"int\" * 1)", int * 1)
        AssertSQL("(\"intOptional\" * 1)", intOptional * 1)
        AssertSQL("(1 * \"int\")", 1 * int)
        AssertSQL("(1 * \"intOptional\")", 1 * intOptional)

        AssertSQL("(\"double\" * \"double\")", double * double)
        AssertSQL("(\"double\" * \"doubleOptional\")", double * doubleOptional)
        AssertSQL("(\"doubleOptional\" * \"double\")", doubleOptional * double)
        AssertSQL("(\"doubleOptional\" * \"doubleOptional\")", doubleOptional * doubleOptional)
        AssertSQL("(\"double\" * 1.0)", double * 1)
        AssertSQL("(\"doubleOptional\" * 1.0)", doubleOptional * 1)
        AssertSQL("(1.0 * \"double\")", 1 * double)
        AssertSQL("(1.0 * \"doubleOptional\")", 1 * doubleOptional)
    }

    func test_numberExpression_dividedByNumberExpression_buildsDivisiveNumberExpression() {
        AssertSQL("(\"int\" / \"int\")", int / int)
        AssertSQL("(\"int\" / \"intOptional\")", int / intOptional)
        AssertSQL("(\"intOptional\" / \"int\")", intOptional / int)
        AssertSQL("(\"intOptional\" / \"intOptional\")", intOptional / intOptional)
        AssertSQL("(\"int\" / 1)", int / 1)
        AssertSQL("(\"intOptional\" / 1)", intOptional / 1)
        AssertSQL("(1 / \"int\")", 1 / int)
        AssertSQL("(1 / \"intOptional\")", 1 / intOptional)

        AssertSQL("(\"double\" / \"double\")", double / double)
        AssertSQL("(\"double\" / \"doubleOptional\")", double / doubleOptional)
        AssertSQL("(\"doubleOptional\" / \"double\")", doubleOptional / double)
        AssertSQL("(\"doubleOptional\" / \"doubleOptional\")", doubleOptional / doubleOptional)
        AssertSQL("(\"double\" / 1.0)", double / 1)
        AssertSQL("(\"doubleOptional\" / 1.0)", doubleOptional / 1)
        AssertSQL("(1.0 / \"double\")", 1 / double)
        AssertSQL("(1.0 / \"doubleOptional\")", 1 / doubleOptional)
    }

    func test_numberExpression_prefixedWithMinus_buildsInvertedNumberExpression() {
        AssertSQL("-(\"int\")", -int)
        AssertSQL("-(\"intOptional\")", -intOptional)

        AssertSQL("-(\"double\")", -double)
        AssertSQL("-(\"doubleOptional\")", -doubleOptional)
    }

    func test_integerExpression_moduloIntegerExpression_buildsModuloIntegerExpression() {
        AssertSQL("(\"int\" % \"int\")", int % int)
        AssertSQL("(\"int\" % \"intOptional\")", int % intOptional)
        AssertSQL("(\"intOptional\" % \"int\")", intOptional % int)
        AssertSQL("(\"intOptional\" % \"intOptional\")", intOptional % intOptional)
        AssertSQL("(\"int\" % 1)", int % 1)
        AssertSQL("(\"intOptional\" % 1)", intOptional % 1)
        AssertSQL("(1 % \"int\")", 1 % int)
        AssertSQL("(1 % \"intOptional\")", 1 % intOptional)
    }

    func test_integerExpression_bitShiftLeftIntegerExpression_buildsLeftShiftedIntegerExpression() {
        AssertSQL("(\"int\" << \"int\")", int << int)
        AssertSQL("(\"int\" << \"intOptional\")", int << intOptional)
        AssertSQL("(\"intOptional\" << \"int\")", intOptional << int)
        AssertSQL("(\"intOptional\" << \"intOptional\")", intOptional << intOptional)
        AssertSQL("(\"int\" << 1)", int << 1)
        AssertSQL("(\"intOptional\" << 1)", intOptional << 1)
        AssertSQL("(1 << \"int\")", 1 << int)
        AssertSQL("(1 << \"intOptional\")", 1 << intOptional)
    }

    func test_integerExpression_bitShiftRightIntegerExpression_buildsRightShiftedIntegerExpression() {
        AssertSQL("(\"int\" >> \"int\")", int >> int)
        AssertSQL("(\"int\" >> \"intOptional\")", int >> intOptional)
        AssertSQL("(\"intOptional\" >> \"int\")", intOptional >> int)
        AssertSQL("(\"intOptional\" >> \"intOptional\")", intOptional >> intOptional)
        AssertSQL("(\"int\" >> 1)", int >> 1)
        AssertSQL("(\"intOptional\" >> 1)", intOptional >> 1)
        AssertSQL("(1 >> \"int\")", 1 >> int)
        AssertSQL("(1 >> \"intOptional\")", 1 >> intOptional)
    }

    func test_integerExpression_bitwiseAndIntegerExpression_buildsAndedIntegerExpression() {
        AssertSQL("(\"int\" & \"int\")", int & int)
        AssertSQL("(\"int\" & \"intOptional\")", int & intOptional)
        AssertSQL("(\"intOptional\" & \"int\")", intOptional & int)
        AssertSQL("(\"intOptional\" & \"intOptional\")", intOptional & intOptional)
        AssertSQL("(\"int\" & 1)", int & 1)
        AssertSQL("(\"intOptional\" & 1)", intOptional & 1)
        AssertSQL("(1 & \"int\")", 1 & int)
        AssertSQL("(1 & \"intOptional\")", 1 & intOptional)
    }

    func test_integerExpression_bitwiseOrIntegerExpression_buildsOredIntegerExpression() {
        AssertSQL("(\"int\" | \"int\")", int | int)
        AssertSQL("(\"int\" | \"intOptional\")", int | intOptional)
        AssertSQL("(\"intOptional\" | \"int\")", intOptional | int)
        AssertSQL("(\"intOptional\" | \"intOptional\")", intOptional | intOptional)
        AssertSQL("(\"int\" | 1)", int | 1)
        AssertSQL("(\"intOptional\" | 1)", intOptional | 1)
        AssertSQL("(1 | \"int\")", 1 | int)
        AssertSQL("(1 | \"intOptional\")", 1 | intOptional)
    }

    func test_integerExpression_bitwiseExclusiveOrIntegerExpression_buildsOredIntegerExpression() {
        AssertSQL("(~((\"int\" & \"int\")) & (\"int\" | \"int\"))", int ^ int)
        AssertSQL("(~((\"int\" & \"intOptional\")) & (\"int\" | \"intOptional\"))", int ^ intOptional)
        AssertSQL("(~((\"intOptional\" & \"int\")) & (\"intOptional\" | \"int\"))", intOptional ^ int)
        AssertSQL("(~((\"intOptional\" & \"intOptional\")) & (\"intOptional\" | \"intOptional\"))", intOptional ^ intOptional)
        AssertSQL("(~((\"int\" & 1)) & (\"int\" | 1))", int ^ 1)
        AssertSQL("(~((\"intOptional\" & 1)) & (\"intOptional\" | 1))", intOptional ^ 1)
        AssertSQL("(~((1 & \"int\")) & (1 | \"int\"))", 1 ^ int)
        AssertSQL("(~((1 & \"intOptional\")) & (1 | \"intOptional\"))", 1 ^ intOptional)
    }

    func test_bitwiseNot_integerExpression_buildsComplementIntegerExpression() {
        AssertSQL("~(\"int\")", ~int)
        AssertSQL("~(\"intOptional\")", ~intOptional)
    }

    func test_equalityOperator_withEquatableExpressions_buildsBooleanExpression() {
        AssertSQL("(\"bool\" = \"bool\")", bool == bool)
        AssertSQL("(\"bool\" = \"boolOptional\")", bool == boolOptional)
        AssertSQL("(\"boolOptional\" = \"bool\")", boolOptional == bool)
        AssertSQL("(\"boolOptional\" = \"boolOptional\")", boolOptional == boolOptional)
        AssertSQL("(\"bool\" = 1)", bool == true)
        AssertSQL("(\"boolOptional\" = 1)", boolOptional == true)
        AssertSQL("(1 = \"bool\")", true == bool)
        AssertSQL("(1 = \"boolOptional\")", true == boolOptional)

        AssertSQL("(\"boolOptional\" IS NULL)", boolOptional == nil)
        AssertSQL("(NULL IS \"boolOptional\")", nil == boolOptional)
    }

    func test_inequalityOperator_withEquatableExpressions_buildsBooleanExpression() {
        AssertSQL("(\"bool\" != \"bool\")", bool != bool)
        AssertSQL("(\"bool\" != \"boolOptional\")", bool != boolOptional)
        AssertSQL("(\"boolOptional\" != \"bool\")", boolOptional != bool)
        AssertSQL("(\"boolOptional\" != \"boolOptional\")", boolOptional != boolOptional)
        AssertSQL("(\"bool\" != 1)", bool != true)
        AssertSQL("(\"boolOptional\" != 1)", boolOptional != true)
        AssertSQL("(1 != \"bool\")", true != bool)
        AssertSQL("(1 != \"boolOptional\")", true != boolOptional)

        AssertSQL("(\"boolOptional\" IS NOT NULL)", boolOptional != nil)
        AssertSQL("(NULL IS NOT \"boolOptional\")", nil != boolOptional)
    }

    func test_greaterThanOperator_withComparableExpressions_buildsBooleanExpression() {
        AssertSQL("(\"bool\" > \"bool\")", bool > bool)
        AssertSQL("(\"bool\" > \"boolOptional\")", bool > boolOptional)
        AssertSQL("(\"boolOptional\" > \"bool\")", boolOptional > bool)
        AssertSQL("(\"boolOptional\" > \"boolOptional\")", boolOptional > boolOptional)
        AssertSQL("(\"bool\" > 1)", bool > true)
        AssertSQL("(\"boolOptional\" > 1)", boolOptional > true)
        AssertSQL("(1 > \"bool\")", true > bool)
        AssertSQL("(1 > \"boolOptional\")", true > boolOptional)
    }

    func test_greaterThanOrEqualToOperator_withComparableExpressions_buildsBooleanExpression() {
        AssertSQL("(\"bool\" >= \"bool\")", bool >= bool)
        AssertSQL("(\"bool\" >= \"boolOptional\")", bool >= boolOptional)
        AssertSQL("(\"boolOptional\" >= \"bool\")", boolOptional >= bool)
        AssertSQL("(\"boolOptional\" >= \"boolOptional\")", boolOptional >= boolOptional)
        AssertSQL("(\"bool\" >= 1)", bool >= true)
        AssertSQL("(\"boolOptional\" >= 1)", boolOptional >= true)
        AssertSQL("(1 >= \"bool\")", true >= bool)
        AssertSQL("(1 >= \"boolOptional\")", true >= boolOptional)
    }

    func test_lessThanOperator_withComparableExpressions_buildsBooleanExpression() {
        AssertSQL("(\"bool\" < \"bool\")", bool < bool)
        AssertSQL("(\"bool\" < \"boolOptional\")", bool < boolOptional)
        AssertSQL("(\"boolOptional\" < \"bool\")", boolOptional < bool)
        AssertSQL("(\"boolOptional\" < \"boolOptional\")", boolOptional < boolOptional)
        AssertSQL("(\"bool\" < 1)", bool < true)
        AssertSQL("(\"boolOptional\" < 1)", boolOptional < true)
        AssertSQL("(1 < \"bool\")", true < bool)
        AssertSQL("(1 < \"boolOptional\")", true < boolOptional)
    }

    func test_lessThanOrEqualToOperator_withComparableExpressions_buildsBooleanExpression() {
        AssertSQL("(\"bool\" <= \"bool\")", bool <= bool)
        AssertSQL("(\"bool\" <= \"boolOptional\")", bool <= boolOptional)
        AssertSQL("(\"boolOptional\" <= \"bool\")", boolOptional <= bool)
        AssertSQL("(\"boolOptional\" <= \"boolOptional\")", boolOptional <= boolOptional)
        AssertSQL("(\"bool\" <= 1)", bool <= true)
        AssertSQL("(\"boolOptional\" <= 1)", boolOptional <= true)
        AssertSQL("(1 <= \"bool\")", true <= bool)
        AssertSQL("(1 <= \"boolOptional\")", true <= boolOptional)
    }

    func test_patternMatchingOperator_withComparableInterval_buildsBetweenBooleanExpression() {
        AssertSQL("\"int\" BETWEEN 0 AND 5", 0...5 ~= int)
        AssertSQL("\"intOptional\" BETWEEN 0 AND 5", 0...5 ~= intOptional)
    }

    func test_doubleAndOperator_withBooleanExpressions_buildsCompoundExpression() {
        AssertSQL("(\"bool\" AND \"bool\")", bool && bool)
        AssertSQL("(\"bool\" AND \"boolOptional\")", bool && boolOptional)
        AssertSQL("(\"boolOptional\" AND \"bool\")", boolOptional && bool)
        AssertSQL("(\"boolOptional\" AND \"boolOptional\")", boolOptional && boolOptional)
        AssertSQL("(\"bool\" AND 1)", bool && true)
        AssertSQL("(\"boolOptional\" AND 1)", boolOptional && true)
        AssertSQL("(1 AND \"bool\")", true && bool)
        AssertSQL("(1 AND \"boolOptional\")", true && boolOptional)
    }

    func test_doubleOrOperator_withBooleanExpressions_buildsCompoundExpression() {
        AssertSQL("(\"bool\" OR \"bool\")", bool || bool)
        AssertSQL("(\"bool\" OR \"boolOptional\")", bool || boolOptional)
        AssertSQL("(\"boolOptional\" OR \"bool\")", boolOptional || bool)
        AssertSQL("(\"boolOptional\" OR \"boolOptional\")", boolOptional || boolOptional)
        AssertSQL("(\"bool\" OR 1)", bool || true)
        AssertSQL("(\"boolOptional\" OR 1)", boolOptional || true)
        AssertSQL("(1 OR \"bool\")", true || bool)
        AssertSQL("(1 OR \"boolOptional\")", true || boolOptional)
    }

    func test_unaryNotOperator_withBooleanExpressions_buildsNotExpression() {
        AssertSQL("NOT (\"bool\")", !bool)
        AssertSQL("NOT (\"boolOptional\")", !boolOptional)
    }

    func test_precedencePreserved() {
        let n = Expression<Int>(value: 1)
        AssertSQL("(((1 = 1) AND (1 = 1)) OR (1 = 1))", (n == n && n == n) || n == n)
        AssertSQL("((1 = 1) AND ((1 = 1) OR (1 = 1)))", n == n && (n == n || n == n))
    }

}