import XCTest

import SQLite

class SQLiteTestCase : XCTestCase {

    var trace = [String: Int]()

    let db = try! Connection()

    let users = Table("users")

    override func setUp() {
        super.setUp()

        db.trace { SQL in
            print(SQL)
            self.trace[SQL] = (self.trace[SQL] ?? 0) + 1
        }
    }

    func CreateUsersTable() {
        try! db.execute(
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

    func InsertUsers(names: String...) throws {
        try InsertUsers(names)
    }

    func InsertUsers(names: [String]) throws {
        for name in names { try InsertUser(name) }
    }

    func InsertUser(name: String, age: Int? = nil, admin: Bool = false) throws -> Statement {
        return try db.run(
            "INSERT INTO \"users\" (email, age, admin) values (?, ?, ?)",
            "\(name)@example.com", age?.datatypeValue, admin.datatypeValue
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
        try! statement.run()
        AssertSQL(SQL, 1, message, file: file, line: line)
        if let count = trace[SQL] { trace[SQL] = count - 1 }
    }

//    func AssertSQL(SQL: String, _ query: Query, _ message: String? = nil, file: String = __FILE__, line: UInt = __LINE__) {
//        for _ in query {}
//        AssertSQL(SQL, 1, message, file: file, line: line)
//        if let count = trace[SQL] { trace[SQL] = count - 1 }
//    }

    func async(expect description: String = "async", timeout: Double = 5, @noescape block: (() -> Void) -> Void) {
        let expectation = expectationWithDescription(description)
        block(expectation.fulfill)
        waitForExpectationsWithTimeout(timeout, handler: nil)
    }

}

let bool = Expression<Bool>("bool")
let boolOptional = Expression<Bool?>("boolOptional")

let data = Expression<Blob>("blob")
let dataOptional = Expression<Blob?>("blobOptional")

let date = Expression<NSDate>("date")
let dateOptional = Expression<NSDate?>("dateOptional")

let double = Expression<Double>("double")
let doubleOptional = Expression<Double?>("doubleOptional")

let int = Expression<Int>("int")
let intOptional = Expression<Int?>("intOptional")

let int64 = Expression<Int64>("int64")
let int64Optional = Expression<Int64?>("int64Optional")

let string = Expression<String>("string")
let stringOptional = Expression<String?>("stringOptional")

func AssertSQL(@autoclosure expression1: () -> String, @autoclosure _ expression2: () -> Expressible, file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertEqual(expression1(), expression2().asSQL(), file: file, line: line)
}

func AssertThrows<T>(@autoclosure expression: () throws -> T, file: String = __FILE__, line: UInt = __LINE__) {
    do {
        try expression()
        XCTFail("expression expected to throw", file: file, line: line)
    } catch {
        XCTAssert(true, file: file, line: line)
    }
}

let table = Table("table")
let virtualTable = VirtualTable("virtual_table")
let _view = View("view") // avoid Mac XCTestCase collision
