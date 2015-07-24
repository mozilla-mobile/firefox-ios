import XCTest
import SQLite

class FunctionsTests: SQLiteTestCase {

    func test_createFunction_withZeroArguments() {
        let f1: () -> Expression<Bool> = db.create(function: "f1") { true }
        let f2: () -> Expression<Bool?> = db.create(function: "f2") { nil }

        let table = db["table"]
        db.create(table: table) { $0.column(Expression<Int>("id"), primaryKey: true) }
        table.insert()!

        XCTAssert(table.select(f1()).first![f1()])
        AssertSQL("SELECT \"f1\"() FROM \"table\" LIMIT 1")

        XCTAssertNil(table.select(f2()).first![f2()])
        AssertSQL("SELECT \"f2\"() FROM \"table\" LIMIT 1")
    }

    func test_createFunction_withOneArgument() {
        let f1: Expression<String> -> Expression<Bool> = db.create(function: "f1") { _ in return true }
        let f2: Expression<String?> -> Expression<Bool> = db.create(function: "f2") { _ in return false }
        let f3: Expression<String> -> Expression<Bool?> = db.create(function: "f3") { _ in return true }
        let f4: Expression<String?> -> Expression<Bool?> = db.create(function: "f4") { _ in return nil }

        let table = db["table"]
        let s1 = Expression<String>("s1")
        let s2 = Expression<String?>("s2")
        db.create(table: table) { t in
            t.column(s1)
            t.column(s2)
        }
        table.insert(s1 <- "s1")!

        let null = Expression<String?>(value: nil as String?)

        XCTAssert(table.select(f1(s1)).first![f1(s1)])
        AssertSQL("SELECT \"f1\"(\"s1\") FROM \"table\" LIMIT 1")

        XCTAssert(!table.select(f2(s2)).first![f2(s2)])
        AssertSQL("SELECT \"f2\"(\"s2\") FROM \"table\" LIMIT 1")

        XCTAssert(table.select(f3(s1)).first![f3(s1)]!)
        AssertSQL("SELECT \"f3\"(\"s1\") FROM \"table\" LIMIT 1")

        XCTAssertNil(table.select(f4(null)).first![f4(null)])
        AssertSQL("SELECT \"f4\"(NULL) FROM \"table\" LIMIT 1")
    }

    func test_createFunction_withValueArgument() {
        let f1: Expression<Bool> -> Expression<Bool> = (
            db.create(function: "f1") { (a: Bool) -> Bool in
                return a
            }
        )

        let table = db["table"]
        let b = Expression<Bool>("b")
        db.create(table: table) { t in
            t.column(b)
        }
        table.insert(b <- true)!

        XCTAssert(table.select(f1(b)).first![f1(b)])
        AssertSQL("SELECT \"f1\"(\"b\") FROM \"table\" LIMIT 1")
    }

    func test_createFunction_withTwoArguments() {
        let table = db["table"]
        let b1 = Expression<Bool>("b1")
        let b2 = Expression<Bool?>("b2")
        db.create(table: table) { t in
            t.column(b1)
            t.column(b2)
        }
        table.insert(b1 <- true)!

        let f1: (Bool, Expression<Bool>) -> Expression<Bool> = db.create(function: "f1") { $0 && $1 }
        let f2: (Bool?, Expression<Bool>) -> Expression<Bool> = db.create(function: "f2") { $0 ?? $1 }
        let f3: (Bool, Expression<Bool?>) -> Expression<Bool> = db.create(function: "f3") { $0 && $1 != nil }
        let f4: (Bool?, Expression<Bool?>) -> Expression<Bool> = db.create(function: "f4") { $0 ?? $1 != nil }

        XCTAssert(table.select(f1(true, b1)).first![f1(true, b1)])
        AssertSQL("SELECT \"f1\"(1, \"b1\") FROM \"table\" LIMIT 1")
        XCTAssert(table.select(f2(nil, b1)).first![f2(nil, b1)])
        AssertSQL("SELECT \"f2\"(NULL, \"b1\") FROM \"table\" LIMIT 1")
        XCTAssertFalse(table.select(f3(false, b2)).first![f3(false, b2)])
        AssertSQL("SELECT \"f3\"(0, \"b2\") FROM \"table\" LIMIT 1")
        XCTAssertFalse(table.select(f4(nil, b2)).first![f4(nil, b2)])
        AssertSQL("SELECT \"f4\"(NULL, \"b2\") FROM \"table\" LIMIT 1")

        let f5: (Bool, Expression<Bool>) -> Expression<Bool?> = db.create(function: "f5") { $0 && $1 }
        let f6: (Bool?, Expression<Bool>) -> Expression<Bool?> = db.create(function: "f6") { $0 ?? $1 }
        let f7: (Bool, Expression<Bool?>) -> Expression<Bool?> = db.create(function: "f7") { $0 && $1 != nil }
        let f8: (Bool?, Expression<Bool?>) -> Expression<Bool?> = db.create(function: "f8") { $0 ?? $1 != nil }

        XCTAssert(table.select(f5(true, b1)).first![f5(true, b1)]!)
        AssertSQL("SELECT \"f5\"(1, \"b1\") FROM \"table\" LIMIT 1")
        XCTAssert(table.select(f6(nil, b1)).first![f6(nil, b1)]!)
        AssertSQL("SELECT \"f6\"(NULL, \"b1\") FROM \"table\" LIMIT 1")
        XCTAssertFalse(table.select(f7(false, b2)).first![f7(false, b2)]!)
        AssertSQL("SELECT \"f7\"(0, \"b2\") FROM \"table\" LIMIT 1")
        XCTAssertFalse(table.select(f8(nil, b2)).first![f8(nil, b2)]!)
        AssertSQL("SELECT \"f8\"(NULL, \"b2\") FROM \"table\" LIMIT 1")

        let f9: (Expression<Bool>, Expression<Bool>) -> Expression<Bool> = db.create(function: "f9") { $0 && $1 }
        let f10: (Expression<Bool?>, Expression<Bool>) -> Expression<Bool> = db.create(function: "f10") { $0 ?? $1 }
        let f11: (Expression<Bool>, Expression<Bool?>) -> Expression<Bool> = db.create(function: "f11") { $0 && $1 != nil }
        let f12: (Expression<Bool?>, Expression<Bool?>) -> Expression<Bool> = db.create(function: "f12") { $0 ?? $1 != nil }

        XCTAssert(table.select(f9(b1, b1)).first![f9(b1, b1)])
        AssertSQL("SELECT \"f9\"(\"b1\", \"b1\") FROM \"table\" LIMIT 1")
        XCTAssert(table.select(f10(b2, b1)).first![f10(b2, b1)])
        AssertSQL("SELECT \"f10\"(\"b2\", \"b1\") FROM \"table\" LIMIT 1")
        XCTAssertFalse(table.select(f11(b1, b2)).first![f11(b1, b2)])
        AssertSQL("SELECT \"f11\"(\"b1\", \"b2\") FROM \"table\" LIMIT 1")
        XCTAssertFalse(table.select(f12(b2, b2)).first![f12(b2, b2)])
        AssertSQL("SELECT \"f12\"(\"b2\", \"b2\") FROM \"table\" LIMIT 1")

        let f13: (Expression<Bool>, Expression<Bool>) -> Expression<Bool?> = db.create(function: "f13") { $0 && $1 }
        let f14: (Expression<Bool?>, Expression<Bool>) -> Expression<Bool?> = db.create(function: "f14") { $0 ?? $1 }
        let f15: (Expression<Bool>, Expression<Bool?>) -> Expression<Bool?> = db.create(function: "f15") { $0 && $1 != nil }
        let f16: (Expression<Bool?>, Expression<Bool?>) -> Expression<Bool?> = db.create(function: "f16") { $0 ?? $1 != nil }

        XCTAssert(table.select(f13(b1, b1)).first![f13(b1, b1)]!)
        AssertSQL("SELECT \"f13\"(\"b1\", \"b1\") FROM \"table\" LIMIT 1")
        XCTAssert(table.select(f14(b2, b1)).first![f14(b2, b1)]!)
        AssertSQL("SELECT \"f14\"(\"b2\", \"b1\") FROM \"table\" LIMIT 1")
        XCTAssertFalse(table.select(f15(b1, b2)).first![f15(b1, b2)]!)
        AssertSQL("SELECT \"f15\"(\"b1\", \"b2\") FROM \"table\" LIMIT 1")
        XCTAssertFalse(table.select(f16(b2, b2)).first![f16(b2, b2)]!)
        AssertSQL("SELECT \"f16\"(\"b2\", \"b2\") FROM \"table\" LIMIT 1")

        let f17: (Expression<Bool>, Bool) -> Expression<Bool> = db.create(function: "f17") { $0 && $1 }
        let f18: (Expression<Bool?>, Bool) -> Expression<Bool> = db.create(function: "f18") { $0 ?? $1 }
        let f19: (Expression<Bool>, Bool?) -> Expression<Bool> = db.create(function: "f19") { $0 && $1 != nil }
        let f20: (Expression<Bool?>, Bool?) -> Expression<Bool> = db.create(function: "f20") { $0 ?? $1 != nil }

        XCTAssert(table.select(f17(b1, true)).first![f17(b1, true)])
        AssertSQL("SELECT \"f17\"(\"b1\", 1) FROM \"table\" LIMIT 1")
        XCTAssert(table.select(f18(b2, true)).first![f18(b2, true)])
        AssertSQL("SELECT \"f18\"(\"b2\", 1) FROM \"table\" LIMIT 1")
        XCTAssertFalse(table.select(f19(b1, nil)).first![f19(b1, nil)])
        AssertSQL("SELECT \"f19\"(\"b1\", NULL) FROM \"table\" LIMIT 1")
        XCTAssertFalse(table.select(f20(b2, nil)).first![f20(b2, nil)])
        AssertSQL("SELECT \"f20\"(\"b2\", NULL) FROM \"table\" LIMIT 1")

        let f21: (Expression<Bool>, Bool) -> Expression<Bool?> = db.create(function: "f21") { $0 && $1 }
        let f22: (Expression<Bool?>, Bool) -> Expression<Bool?> = db.create(function: "f22") { $0 ?? $1 }
        let f23: (Expression<Bool>, Bool?) -> Expression<Bool?> = db.create(function: "f23") { $0 && $1 != nil }
        let f24: (Expression<Bool?>, Bool?) -> Expression<Bool?> = db.create(function: "f24") { $0 ?? $1 != nil }

        XCTAssert(table.select(f21(b1, true)).first![f21(b1, true)]!)
        AssertSQL("SELECT \"f21\"(\"b1\", 1) FROM \"table\" LIMIT 1")
        XCTAssert(table.select(f22(b2, true)).first![f22(b2, true)]!)
        AssertSQL("SELECT \"f22\"(\"b2\", 1) FROM \"table\" LIMIT 1")
        XCTAssertFalse(table.select(f23(b1, nil)).first![f23(b1, nil)]!)
        AssertSQL("SELECT \"f23\"(\"b1\", NULL) FROM \"table\" LIMIT 1")
        XCTAssertFalse(table.select(f24(b2, nil)).first![f24(b2, nil)]!)
        AssertSQL("SELECT \"f24\"(\"b2\", NULL) FROM \"table\" LIMIT 1")
    }

}
