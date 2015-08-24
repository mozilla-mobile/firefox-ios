import XCTest
import SQLite

class StatementTests: SQLiteTestCase {

    override func setUp() {
        createUsersTable()

        super.setUp()
    }

    func test_bind_withVariadicParameters_bindsParameters() {
        let stmt = db.prepare("SELECT ?, ?, ?, ?")
        withBlob { stmt.bind(1, 2.0, "3", $0) }
        AssertSQL("SELECT 1, 2.0, '3', x'34'", stmt)
    }

    func test_bind_withArrayOfParameters_bindsParameters() {
        let stmt = db.prepare("SELECT ?, ?, ?, ?")
        withBlob { stmt.bind([1, 2.0, "3", $0]) }
        AssertSQL("SELECT 1, 2.0, '3', x'34'", stmt)
    }

    func test_bind_withNamedParameters_bindsParameters() {
        let stmt = db.prepare("SELECT ?1, ?2, ?3, ?4")
        withBlob { stmt.bind(["?1": 1, "?2": 2.0, "?3": "3", "?4": $0]) }
        AssertSQL("SELECT 1, 2.0, '3', x'34'", stmt)
    }

    func test_bind_withBlob_bindsBlob() {
        let stmt = db.prepare("SELECT ?")
        withBlob { stmt.bind($0) }
        AssertSQL("SELECT x'34'", stmt)
    }

    func test_bind_withDouble_bindsDouble() {
        AssertSQL("SELECT 2.0", db.prepare("SELECT ?").bind(2.0))
    }

    func test_bind_withInt_bindsInt() {
        AssertSQL("SELECT 3", db.prepare("SELECT ?").bind(3))
    }

    func test_bind_withString() {
        AssertSQL("SELECT '4'", db.prepare("SELECT ?").bind("4"))
    }

    func test_run_withNoParameters() {
        db.prepare("INSERT INTO users (email, admin) VALUES ('alice@example.com', 1)").run()
        XCTAssertEqual(1, db.totalChanges)
    }

    func test_run_withVariadicParameters() {
        let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)")
        stmt.run("alice@example.com", 1)
        XCTAssertEqual(1, db.totalChanges)
    }

    func test_run_withArrayOfParameters() {
        let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)")
        stmt.run(["alice@example.com", 1])
        XCTAssertEqual(1, db.totalChanges)
    }

    func test_run_withNamedParameters() {
        let stmt = db.prepare(
            "INSERT INTO users (email, admin) VALUES ($email, $admin)"
        )
        stmt.run(["$email": "alice@example.com", "$admin": 1])
        XCTAssertEqual(1, db.totalChanges)
    }

    func test_scalar_withNoParameters() {
        let zero = db.prepare("SELECT 0")
        XCTAssertEqual(0, zero.scalar() as! Int64)
    }

    func test_scalar_withNoParameters_retainsBindings() {
        let count = db.prepare("SELECT count(*) FROM users WHERE age >= ?", 21)
        XCTAssertEqual(0, count.scalar() as! Int64)

        insertUser("alice", age: 21)
        XCTAssertEqual(1, count.scalar() as! Int64)
    }

    func test_scalar_withVariadicParameters() {
        insertUser( "alice", age: 21)
        let count = db.prepare("SELECT count(*) FROM users WHERE age >= ?")
        XCTAssertEqual(1, count.scalar(21) as! Int64)
    }

    func test_scalar_withArrayOfParameters() {
        insertUser( "alice", age: 21)
        let count = db.prepare("SELECT count(*) FROM users WHERE age >= ?")
        XCTAssertEqual(1, count.scalar([21]) as! Int64)
    }

    func test_scalar_withNamedParameters() {
        insertUser("alice", age: 21)
        let count = db.prepare("SELECT count(*) FROM users WHERE age >= $age")
        XCTAssertEqual(1, count.scalar(["$age": 21]) as! Int64)
    }

    func test_scalar_withParameters_updatesBindings() {
        insertUser("alice", age: 21)
        let count = db.prepare("SELECT count(*) FROM users WHERE age >= ?")
        XCTAssertEqual(1, count.scalar(21) as! Int64)
        XCTAssertEqual(0, count.scalar(22) as! Int64)
    }

    func test_scalar_doubleReturnValue() {
        XCTAssertEqual(2.0, db.scalar("SELECT 2.0") as! Double)
    }

    func test_scalar_intReturnValue() {
        XCTAssertEqual(3, db.scalar("SELECT 3") as! Int64)
    }

    func test_scalar_stringReturnValue() {
        XCTAssertEqual("4", db.scalar("SELECT '4'") as! String)
    }

    func test_generate_allowsIteration() {
        insertUsers("alice", "betsy", "cindy")
        var count = 0
        for row in db.prepare("SELECT id FROM users") {
            XCTAssertEqual(1, row.count)
            count++
        }
        XCTAssertEqual(3, count)
    }

    func test_generate_allowsReuse() {
        insertUsers("alice", "betsy", "cindy")
        var count = 0
        let stmt = db.prepare("SELECT id FROM users")
        for row in stmt { count++ }
        for row in stmt { count++ }
        XCTAssertEqual(6, count)
    }

    func test_row_returnsValues() {
        insertUser("alice")
        let stmt = db.prepare("SELECT id, email FROM users")
        stmt.step()

        XCTAssertEqual(1, stmt.row[0] as Int64)
        XCTAssertEqual("alice@example.com", stmt.row[1] as String)
    }

}

func withBlob(block: Blob -> ()) {
    let length = 1
    let buflen = Int(length) + 1
    let buffer = UnsafeMutablePointer<()>.alloc(buflen)
    memcpy(buffer, "4", length)
    block(Blob(bytes: buffer, length: length))
    buffer.dealloc(buflen)
}
