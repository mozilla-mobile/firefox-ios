import XCTest
import SQLiteCipher

class CipherTests: XCTestCase {

    let db = try! Connection()

    override func setUp() {
        try! db.key("hello")

        try! db.run("CREATE TABLE foo (bar TEXT)")
        try! db.run("INSERT INTO foo (bar) VALUES ('world')")

        super.setUp()
    }

    func test_key() {
        XCTAssertEqual(1, try! db.scalar("SELECT count(*) FROM foo") as! Int64)
    }

    func test_rekey() {
        try! db.rekey("goodbye")
        XCTAssertEqual(1, try! db.scalar("SELECT count(*) FROM foo") as! Int64)
    }
    
}
