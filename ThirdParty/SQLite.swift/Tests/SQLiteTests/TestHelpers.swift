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

    func InsertUsers(_ names: String...) throws {
        try InsertUsers(names)
    }

    func InsertUsers(_ names: [String]) throws {
        for name in names { try InsertUser(name) }
    }

    @discardableResult func InsertUser(_ name: String, age: Int? = nil, admin: Bool = false) throws -> Statement {
        return try db.run(
            "INSERT INTO \"users\" (email, age, admin) values (?, ?, ?)",
            "\(name)@example.com", age?.datatypeValue, admin.datatypeValue
        )
    }

    func AssertSQL(_ SQL: String, _ executions: Int = 1, _ message: String? = nil, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(
            executions, trace[SQL] ?? 0,
            message ?? SQL,
            file: file, line: line
        )
    }

    func AssertSQL(_ SQL: String, _ statement: Statement, _ message: String? = nil, file: StaticString = #file, line: UInt = #line) {
        try! statement.run()
        AssertSQL(SQL, 1, message, file: file, line: line)
        if let count = trace[SQL] { trace[SQL] = count - 1 }
    }

//    func AssertSQL(SQL: String, _ query: Query, _ message: String? = nil, file: String = __FILE__, line: UInt = __LINE__) {
//        for _ in query {}
//        AssertSQL(SQL, 1, message, file: file, line: line)
//        if let count = trace[SQL] { trace[SQL] = count - 1 }
//    }

    func async(expect description: String = "async", timeout: Double = 5, block: (@escaping () -> Void) -> Void) {
        let expectation = self.expectation(description: description)
        block(expectation.fulfill)
        waitForExpectations(timeout: timeout, handler: nil)
    }

}

let bool = Expression<Bool>("bool")
let boolOptional = Expression<Bool?>("boolOptional")

let data = Expression<Blob>("blob")
let dataOptional = Expression<Blob?>("blobOptional")

let date = Expression<Date>("date")
let dateOptional = Expression<Date?>("dateOptional")

let double = Expression<Double>("double")
let doubleOptional = Expression<Double?>("doubleOptional")

let int = Expression<Int>("int")
let intOptional = Expression<Int?>("intOptional")

let int64 = Expression<Int64>("int64")
let int64Optional = Expression<Int64?>("int64Optional")

let string = Expression<String>("string")
let stringOptional = Expression<String?>("stringOptional")

func AssertSQL(_ expression1: @autoclosure () -> String, _ expression2: @autoclosure () -> Expressible, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(expression1(), expression2().asSQL(), file: file, line: line)
}

func AssertThrows<T>(_ expression: @autoclosure () throws -> T, file: StaticString = #file, line: UInt = #line) {
    do {
        _ = try expression()
        XCTFail("expression expected to throw", file: file, line: line)
    } catch {
        XCTAssert(true, file: file, line: line)
    }
}

let table = Table("table")
let qualifiedTable = Table("table", database: "main")
let virtualTable = VirtualTable("virtual_table")
let _view = View("view") // avoid Mac XCTestCase collision
