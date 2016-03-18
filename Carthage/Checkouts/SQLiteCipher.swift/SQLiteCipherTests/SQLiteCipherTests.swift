import XCTest
import SQLiteCipher

class CipherTests: XCTestCase {
    
    let db = try! Connection()
    let db2 = try! Connection()
    
    override func setUp() {
        // db
        try! db.key("hello")
        
        try! db.run("CREATE TABLE foo (bar TEXT)")
        try! db.run("INSERT INTO foo (bar) VALUES ('world')")
        
        // db2
        let keyData = NSMutableData(length: 64)!
        let _ = SecRandomCopyBytes(kSecRandomDefault, 64, UnsafeMutablePointer<UInt8>(keyData.mutableBytes))
        try! db2.key(Blob(bytes: keyData.bytes, length: keyData.length))
        
        try! db2.run("CREATE TABLE foo (bar TEXT)")
        try! db2.run("INSERT INTO foo (bar) VALUES ('world')")
        
        super.setUp()
    }
    
    func test_key() {
        XCTAssertEqual(1, db.scalar("SELECT count(*) FROM foo") as? Int64)
    }
    
    func test_rekey() {
        try! db.rekey("goodbye")
        XCTAssertEqual(1, db.scalar("SELECT count(*) FROM foo") as? Int64)
    }
    
    func test_data_key() {
        XCTAssertEqual(1, db2.scalar("SELECT count(*) FROM foo") as? Int64)
    }
    
    func test_data_rekey() {
        let keyData = NSMutableData(length: 64)!
        SecRandomCopyBytes(kSecRandomDefault, 64, UnsafeMutablePointer<UInt8>(keyData.mutableBytes))
        
        try! db2.rekey(Blob(bytes: keyData.bytes, length: keyData.length))
        XCTAssertEqual(1, db2.scalar("SELECT count(*) FROM foo") as? Int64)
    }
    
    func test_keyFailure() {
        let path = "\(NSTemporaryDirectory())/db.sqlite3"
        _ = try? NSFileManager.defaultManager().removeItemAtPath(path)
        
        let connA = try! Connection(path)
        defer { try! NSFileManager.defaultManager().removeItemAtPath(path) }
        
        try! connA.key("hello")
        
        let connB = try! Connection(path)
        
        var rc: Int32?
        do {
            try connB.key("world")
        } catch Result.Error(_, let code, _) {
            rc = code
        } catch {
            XCTFail()
        }
        XCTAssertEqual(SQLITE_NOTADB, rc)
    }
    
}
