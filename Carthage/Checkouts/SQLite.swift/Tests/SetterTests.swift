import XCTest
import SQLite

class SetterTests : XCTestCase {

    func test_setterAssignmentOperator_buildsSetter() {
        AssertSQL("\"int\" = \"int\"", int <- int)
        AssertSQL("\"int\" = 1", int <- 1)
        AssertSQL("\"intOptional\" = \"int\"", intOptional <- int)
        AssertSQL("\"intOptional\" = \"intOptional\"", intOptional <- intOptional)
        AssertSQL("\"intOptional\" = 1", intOptional <- 1)
        AssertSQL("\"intOptional\" = NULL", intOptional <- nil)
    }

    func test_plusEquals_withStringExpression_buildsSetter() {
        AssertSQL("\"string\" = (\"string\" || \"string\")", string += string)
        AssertSQL("\"string\" = (\"string\" || 'literal')", string += "literal")
        AssertSQL("\"stringOptional\" = (\"stringOptional\" || \"string\")", stringOptional += string)
        AssertSQL("\"stringOptional\" = (\"stringOptional\" || \"stringOptional\")", stringOptional += stringOptional)
        AssertSQL("\"stringOptional\" = (\"stringOptional\" || 'literal')", stringOptional += "literal")
    }

    func test_plusEquals_withNumberExpression_buildsSetter() {
        AssertSQL("\"int\" = (\"int\" + \"int\")", int += int)
        AssertSQL("\"int\" = (\"int\" + 1)", int += 1)
        AssertSQL("\"intOptional\" = (\"intOptional\" + \"int\")", intOptional += int)
        AssertSQL("\"intOptional\" = (\"intOptional\" + \"intOptional\")", intOptional += intOptional)
        AssertSQL("\"intOptional\" = (\"intOptional\" + 1)", intOptional += 1)

        AssertSQL("\"double\" = (\"double\" + \"double\")", double += double)
        AssertSQL("\"double\" = (\"double\" + 1.0)", double += 1)
        AssertSQL("\"doubleOptional\" = (\"doubleOptional\" + \"double\")", doubleOptional += double)
        AssertSQL("\"doubleOptional\" = (\"doubleOptional\" + \"doubleOptional\")", doubleOptional += doubleOptional)
        AssertSQL("\"doubleOptional\" = (\"doubleOptional\" + 1.0)", doubleOptional += 1)
    }

    func test_minusEquals_withNumberExpression_buildsSetter() {
        AssertSQL("\"int\" = (\"int\" - \"int\")", int -= int)
        AssertSQL("\"int\" = (\"int\" - 1)", int -= 1)
        AssertSQL("\"intOptional\" = (\"intOptional\" - \"int\")", intOptional -= int)
        AssertSQL("\"intOptional\" = (\"intOptional\" - \"intOptional\")", intOptional -= intOptional)
        AssertSQL("\"intOptional\" = (\"intOptional\" - 1)", intOptional -= 1)

        AssertSQL("\"double\" = (\"double\" - \"double\")", double -= double)
        AssertSQL("\"double\" = (\"double\" - 1.0)", double -= 1)
        AssertSQL("\"doubleOptional\" = (\"doubleOptional\" - \"double\")", doubleOptional -= double)
        AssertSQL("\"doubleOptional\" = (\"doubleOptional\" - \"doubleOptional\")", doubleOptional -= doubleOptional)
        AssertSQL("\"doubleOptional\" = (\"doubleOptional\" - 1.0)", doubleOptional -= 1)
    }

    func test_timesEquals_withNumberExpression_buildsSetter() {
        AssertSQL("\"int\" = (\"int\" * \"int\")", int *= int)
        AssertSQL("\"int\" = (\"int\" * 1)", int *= 1)
        AssertSQL("\"intOptional\" = (\"intOptional\" * \"int\")", intOptional *= int)
        AssertSQL("\"intOptional\" = (\"intOptional\" * \"intOptional\")", intOptional *= intOptional)
        AssertSQL("\"intOptional\" = (\"intOptional\" * 1)", intOptional *= 1)

        AssertSQL("\"double\" = (\"double\" * \"double\")", double *= double)
        AssertSQL("\"double\" = (\"double\" * 1.0)", double *= 1)
        AssertSQL("\"doubleOptional\" = (\"doubleOptional\" * \"double\")", doubleOptional *= double)
        AssertSQL("\"doubleOptional\" = (\"doubleOptional\" * \"doubleOptional\")", doubleOptional *= doubleOptional)
        AssertSQL("\"doubleOptional\" = (\"doubleOptional\" * 1.0)", doubleOptional *= 1)
    }

    func test_dividedByEquals_withNumberExpression_buildsSetter() {
        AssertSQL("\"int\" = (\"int\" / \"int\")", int /= int)
        AssertSQL("\"int\" = (\"int\" / 1)", int /= 1)
        AssertSQL("\"intOptional\" = (\"intOptional\" / \"int\")", intOptional /= int)
        AssertSQL("\"intOptional\" = (\"intOptional\" / \"intOptional\")", intOptional /= intOptional)
        AssertSQL("\"intOptional\" = (\"intOptional\" / 1)", intOptional /= 1)

        AssertSQL("\"double\" = (\"double\" / \"double\")", double /= double)
        AssertSQL("\"double\" = (\"double\" / 1.0)", double /= 1)
        AssertSQL("\"doubleOptional\" = (\"doubleOptional\" / \"double\")", doubleOptional /= double)
        AssertSQL("\"doubleOptional\" = (\"doubleOptional\" / \"doubleOptional\")", doubleOptional /= doubleOptional)
        AssertSQL("\"doubleOptional\" = (\"doubleOptional\" / 1.0)", doubleOptional /= 1)
    }

    func test_moduloEquals_withIntegerExpression_buildsSetter() {
        AssertSQL("\"int\" = (\"int\" % \"int\")", int %= int)
        AssertSQL("\"int\" = (\"int\" % 1)", int %= 1)
        AssertSQL("\"intOptional\" = (\"intOptional\" % \"int\")", intOptional %= int)
        AssertSQL("\"intOptional\" = (\"intOptional\" % \"intOptional\")", intOptional %= intOptional)
        AssertSQL("\"intOptional\" = (\"intOptional\" % 1)", intOptional %= 1)
    }

    func test_leftShiftEquals_withIntegerExpression_buildsSetter() {
        AssertSQL("\"int\" = (\"int\" << \"int\")", int <<= int)
        AssertSQL("\"int\" = (\"int\" << 1)", int <<= 1)
        AssertSQL("\"intOptional\" = (\"intOptional\" << \"int\")", intOptional <<= int)
        AssertSQL("\"intOptional\" = (\"intOptional\" << \"intOptional\")", intOptional <<= intOptional)
        AssertSQL("\"intOptional\" = (\"intOptional\" << 1)", intOptional <<= 1)
    }

    func test_rightShiftEquals_withIntegerExpression_buildsSetter() {
        AssertSQL("\"int\" = (\"int\" >> \"int\")", int >>= int)
        AssertSQL("\"int\" = (\"int\" >> 1)", int >>= 1)
        AssertSQL("\"intOptional\" = (\"intOptional\" >> \"int\")", intOptional >>= int)
        AssertSQL("\"intOptional\" = (\"intOptional\" >> \"intOptional\")", intOptional >>= intOptional)
        AssertSQL("\"intOptional\" = (\"intOptional\" >> 1)", intOptional >>= 1)
    }

    func test_bitwiseAndEquals_withIntegerExpression_buildsSetter() {
        AssertSQL("\"int\" = (\"int\" & \"int\")", int &= int)
        AssertSQL("\"int\" = (\"int\" & 1)", int &= 1)
        AssertSQL("\"intOptional\" = (\"intOptional\" & \"int\")", intOptional &= int)
        AssertSQL("\"intOptional\" = (\"intOptional\" & \"intOptional\")", intOptional &= intOptional)
        AssertSQL("\"intOptional\" = (\"intOptional\" & 1)", intOptional &= 1)
    }

    func test_bitwiseOrEquals_withIntegerExpression_buildsSetter() {
        AssertSQL("\"int\" = (\"int\" | \"int\")", int |= int)
        AssertSQL("\"int\" = (\"int\" | 1)", int |= 1)
        AssertSQL("\"intOptional\" = (\"intOptional\" | \"int\")", intOptional |= int)
        AssertSQL("\"intOptional\" = (\"intOptional\" | \"intOptional\")", intOptional |= intOptional)
        AssertSQL("\"intOptional\" = (\"intOptional\" | 1)", intOptional |= 1)
    }

    func test_bitwiseExclusiveOrEquals_withIntegerExpression_buildsSetter() {
        AssertSQL("\"int\" = (~((\"int\" & \"int\")) & (\"int\" | \"int\"))", int ^= int)
        AssertSQL("\"int\" = (~((\"int\" & 1)) & (\"int\" | 1))", int ^= 1)
        AssertSQL("\"intOptional\" = (~((\"intOptional\" & \"int\")) & (\"intOptional\" | \"int\"))", intOptional ^= int)
        AssertSQL("\"intOptional\" = (~((\"intOptional\" & \"intOptional\")) & (\"intOptional\" | \"intOptional\"))", intOptional ^= intOptional)
        AssertSQL("\"intOptional\" = (~((\"intOptional\" & 1)) & (\"intOptional\" | 1))", intOptional ^= 1)
    }

    func test_postfixPlus_withIntegerValue_buildsSetter() {
        AssertSQL("\"int\" = (\"int\" + 1)", int++)
        AssertSQL("\"intOptional\" = (\"intOptional\" + 1)", intOptional++)
    }

    func test_postfixMinus_withIntegerValue_buildsSetter() {
        AssertSQL("\"int\" = (\"int\" - 1)", int--)
        AssertSQL("\"intOptional\" = (\"intOptional\" - 1)", intOptional--)
    }

}
