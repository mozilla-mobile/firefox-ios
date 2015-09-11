import SQLite
import XCTest

let id = Expression<Int64>("id")
let email = Expression<String>("email")
let age = Expression<Int?>("age")
let salary = Expression<Double>("salary")
let admin = Expression<Bool>("admin")
let manager_id = Expression<Int64?>("manager_id")

class SQLiteTestCase: XCTestCase {

    var trace = [String: Int]()

    let db = Database()

    var users: Query { return db["users"] }

    override func setUp() {
        super.setUp()

        db.trace { SQL in
            println(SQL)
            self.trace[SQL] = (self.trace[SQL] ?? 0) + 1
        }
    }

    func createUsersTable() {
        db.execute(
            "CREATE TABLE \"users\" (" +
                "id INTEGER PRIMARY KEY, " +
                "email TEXT NOT NULL UNIQUE, " +
                "age INTEGER, " +
                "salary REAL, " +
                "admin BOOLEAN NOT NULL DEFAULT 0 CHECK (admin IN (0, 1)), " +
                "manager_id INTEGER, " +
                "FOREIGN KEY(manager_id) REFERENCES users(id)" +
            ")"
        )
    }

    func insertUsers(names: String...) {
        insertUsers(names)
    }

    func insertUsers(names: [String]) {
        for name in names { insertUser(name) }
    }

    func insertUser(name: String, age: Int? = nil, admin: Bool = false) -> Statement {
        return db.run(
            "INSERT INTO \"users\" (email, age, admin) values (?, ?, ?)",
            ["\(name)@example.com", age, admin.datatypeValue]
        )
    }

    func AssertSQL(SQL: String, _ executions: Int = 1, _ message: String? = nil, file: String = __FILE__, line: UInt = __LINE__) {
        XCTAssertEqual(
            executions, trace[SQL] ?? 0,
            message ?? SQL,
            file: file, line: line
        )
    }

    func AssertSQL(SQL: String, _ statement: Statement, _ message: String? = nil, file: String = __FILE__, line: UInt = __LINE__) {
        statement.run()
        AssertSQL(SQL, 1, message, file: file, line: line)
        if let count = trace[SQL] { trace[SQL] = count - 1 }
    }

    func AssertSQL(SQL: String, _ query: Query, _ message: String? = nil, file: String = __FILE__, line: UInt = __LINE__) {
        for _ in query {}
        AssertSQL(SQL, 1, message, file: file, line: line)
        if let count = trace[SQL] { trace[SQL] = count - 1 }
    }

}
