import XCTest
import SQLite

class CipherTests: SQLiteTestCase {

    override func setUp() {
        db.key("hello")
        createUsersTable()
        insertUser("alice")

        super.setUp()
    }

    func test_key() {
        XCTAssertEqual(1, users.count)
    }

    func test_rekey() {
        db.rekey("world")
        XCTAssertEqual(1, users.count)
    }

}