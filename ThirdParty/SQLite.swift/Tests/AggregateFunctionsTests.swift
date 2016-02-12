import XCTest
import SQLite

class AggregateFunctionsTests : XCTestCase {

    func test_distinct_prependsExpressionsWithDistinctKeyword() {
        AssertSQL("DISTINCT \"int\"", int.distinct)
        AssertSQL("DISTINCT \"intOptional\"", intOptional.distinct)
        AssertSQL("DISTINCT \"double\"", double.distinct)
        AssertSQL("DISTINCT \"doubleOptional\"", doubleOptional.distinct)
        AssertSQL("DISTINCT \"string\"", string.distinct)
        AssertSQL("DISTINCT \"stringOptional\"", stringOptional.distinct)
    }

    func test_count_wrapsOptionalExpressionsWithCountFunction() {
        AssertSQL("count(\"intOptional\")", intOptional.count)
        AssertSQL("count(\"doubleOptional\")", doubleOptional.count)
        AssertSQL("count(\"stringOptional\")", stringOptional.count)
    }

    func test_max_wrapsComparableExpressionsWithMaxFunction() {
        AssertSQL("max(\"int\")", int.max)
        AssertSQL("max(\"intOptional\")", intOptional.max)
        AssertSQL("max(\"double\")", double.max)
        AssertSQL("max(\"doubleOptional\")", doubleOptional.max)
        AssertSQL("max(\"string\")", string.max)
        AssertSQL("max(\"stringOptional\")", stringOptional.max)
    }

    func test_min_wrapsComparableExpressionsWithMinFunction() {
        AssertSQL("min(\"int\")", int.min)
        AssertSQL("min(\"intOptional\")", intOptional.min)
        AssertSQL("min(\"double\")", double.min)
        AssertSQL("min(\"doubleOptional\")", doubleOptional.min)
        AssertSQL("min(\"string\")", string.min)
        AssertSQL("min(\"stringOptional\")", stringOptional.min)
    }

    func test_average_wrapsNumericExpressionsWithAvgFunction() {
        AssertSQL("avg(\"int\")", int.average)
        AssertSQL("avg(\"intOptional\")", intOptional.average)
        AssertSQL("avg(\"double\")", double.average)
        AssertSQL("avg(\"doubleOptional\")", doubleOptional.average)
    }

    func test_sum_wrapsNumericExpressionsWithSumFunction() {
        AssertSQL("sum(\"int\")", int.sum)
        AssertSQL("sum(\"intOptional\")", intOptional.sum)
        AssertSQL("sum(\"double\")", double.sum)
        AssertSQL("sum(\"doubleOptional\")", doubleOptional.sum)
    }

    func test_total_wrapsNumericExpressionsWithTotalFunction() {
        AssertSQL("total(\"int\")", int.total)
        AssertSQL("total(\"intOptional\")", intOptional.total)
        AssertSQL("total(\"double\")", double.total)
        AssertSQL("total(\"doubleOptional\")", doubleOptional.total)
    }

    func test_count_withStar_wrapsStarWithCountFunction() {
        AssertSQL("count(*)", count(*))
    }

}
