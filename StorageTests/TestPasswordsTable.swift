import Foundation
import XCTest

class TestPasswordsTable : XCTestCase {
    var db: SwiftData!
    var factory: ((row: SDRow) -> Password)? {
        return { row -> Password in
            var user = row["username"] as? String ?? ""
            var pass = row["password"] as? String ?? ""
            let pw = Password(hostname: row["hostname"] as! String, username: user as String, password: pass)
            return pw
        }
    }

    func testPasswordTable() {
        let files = MockFiles()
        self.db = SwiftData(filename: files.getAndEnsureDirectory()!.stringByAppendingPathComponent("test.db"))
        let table = PasswordsTable<Password>()
        table.encryption = EncryptionType.AES256

        self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { (db) -> NSError? in
            table.create(db, version: 1)
            return nil
        })

        let Username = "Username"
        let Pass = "Password"
        let HostName = "HOstName"

        // Test inserting a password.
        let p = Password(hostname: HostName, username: Username, password: Pass)
        var err: NSError? = nil
        self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { db -> NSError? in
            let inserted = table.insert(db, item: p, err: &err)
            XCTAssertGreaterThan(inserted, 0, "Password was inserted")
            return err
        })
        XCTAssertNil(err, "No error from inserting")

        // Test querying a password.
        self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { db -> NSError? in
            let options = QueryOptions(filter: p.hostname)
            let cursor = table.query(db, options: options)
            XCTAssertEqual(cursor.count, 1, "Cursor has one entry")
            let p = cursor[0] as! Password

            XCTAssertEqual(p.username, Username , "Cursor has right username")
            XCTAssertEqual(p.password, Pass, "Cursor has right password")
            XCTAssertEqual(p.hostname, HostName, "Cursor has right hostname")
            return err
        })
        XCTAssertNil(err, "No error from query")

        // Query to make sure passwords are encrypted

        self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { db -> NSError? in
            let cursor =  db.executeQuery("SELECT * FROM logins", factory: self.factory!, withArgs: nil)
            XCTAssertEqual(cursor.count, 1, "Cursor has one entry")
            let p = cursor[0] as! Password
            XCTAssertEqual(p.username, Username, "Cursor has non-encrypted username")
            XCTAssertNotEqual(p.password, Pass, "Cursor has encrypted password")
            XCTAssertEqual(p.hostname, HostName, "Cursor has right hostname")
            return err
        })
        XCTAssertNil(err, "No error from query")

        // Turning off encryption should still return a stored passwords decrypted.
        table.encryption = .NONE
        self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { db -> NSError? in
            let options = QueryOptions(filter: p.hostname)
            let cursor = table.query(db, options: options)
            XCTAssertEqual(cursor.count, 1, "Cursor has one entry")
            let p = cursor[0] as! Password
            XCTAssertEqual(p.username, Username, "Cursor has right username")
            XCTAssertEqual(p.password, Pass, "Cursor has right password")
            XCTAssertEqual(p.hostname, HostName, "Cursor has right hostname")
            return err
        })
        XCTAssertNil(err, "No error from query")

        // Remove stored password.
        table.encryption = EncryptionType.AES256
        self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { db -> NSError? in
            var deleted = table.delete(db, item: p, err: &err)
            XCTAssertGreaterThan(deleted, 0, "Password was deleted")
            return err
        })
        XCTAssertNil(err, "No error from deleting")

        // Insert an unencrypted password.
        table.encryption = .NONE
        self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { db -> NSError? in
            let inserted = table.insert(db, item: p, err: &err)
            XCTAssertGreaterThan(inserted, 0, "Password was inserted")
            return err
        })
        XCTAssertNil(err, "No error from inserting")

        // Query returns unencrypted password
        self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { db -> NSError? in
            let options = QueryOptions(filter: p.hostname)
            let cursor = table.query(db, options: options)
            XCTAssertEqual(cursor.count, 1, "Cursor has one entry")
            let p = cursor[0] as! Password
            XCTAssertEqual(p.username, Username, "Cursor has right username")
            XCTAssertEqual(p.password, Pass, "Cursor has right password")
            XCTAssertEqual(p.hostname, HostName, "Cursor has right hostname")
            return err
        })
        XCTAssertNil(err, "No error from query")

        // Query to make sure passwords are unencrypted
        self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { db -> NSError? in
            let cursor =  db.executeQuery("SELECT * FROM logins", factory: self.factory!, withArgs: nil)
            XCTAssertEqual(cursor.count, 1, "Cursor has one entry")
            let p = cursor[0] as! Password
            XCTAssertEqual(p.username, Username, "Cursor has encrypted username")
            XCTAssertEqual(p.password, Pass, "Cursor has encrypted password")
            XCTAssertEqual(p.hostname, HostName, "Cursor has right hostname")
            return err
        })
        XCTAssertNil(err, "No error from query")

        // Remove all passwords.
        self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { db -> NSError? in
            var deleted = table.delete(db, item: nil, err: &err)
            XCTAssert(deleted > 0, "Passwords were deleted")
            return err
        })
        XCTAssertNil(err, "No error from deleting")

        files.remove("test.db")
    }
}