/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Storage

import XCTest

// TODO: rewrite this test to not use BrowserSchema. It used to use HistoryTable…
class TestSwiftData: XCTestCase {
    var swiftData: SwiftData?
    var urlCounter = 1
    var testDB: String!

    override func setUp() {
        let files = MockFiles()
        do {
            try files.remove("testSwiftData.db")
        } catch _ {
        }
        testDB = (try! (files.getAndEnsureDirectory() as NSString)).appendingPathComponent("testSwiftData.db")
        swiftData = SwiftData(filename: testDB, schema: BrowserSchema(), files: files)
        let table = BrowserSchema()

        // Ensure static flags match expected values.
        XCTAssert(SwiftData.ReuseConnections, "Reusing database connections")
        XCTAssert(SwiftData.EnableWAL, "WAL enabled")

        XCTAssertNil(addSite(table, url: "http://url0", title: "title0"), "Added url0.")
    }

    override func tearDown() {
        // Restore static flags to their default values.
        SwiftData.ReuseConnections = true
        SwiftData.EnableWAL = true
    }

    /*
    // These two tests broke after pull #427.
    func testNoWALOrConnectionReuse() {
    SwiftData.EnableWAL = false
        SwiftData.ReuseConnections = false
        var error = writeDuringRead()
        XCTAssertEqual(error!.code, 5, "Got 'database is locked' error")
    }

    func testNoConnectionReuse() {
        SwiftData.EnableWAL = true
        SwiftData.ReuseConnections = false
        var error = writeDuringRead()
        XCTAssertNotNil(error, "Expected error during write.")
        XCTAssertEqual(error?.code ?? 0, 8, "Got 'attempt to write to read-only database' error")
    }
    */

    func testNoWAL() {
        SwiftData.EnableWAL = false
        SwiftData.ReuseConnections = true
        let error = writeDuringRead()
        XCTAssertNil(error, "Insertion succeeded")
    }

    func testDefaultSettings() {
        SwiftData.EnableWAL = true
        SwiftData.ReuseConnections = true
        let error = writeDuringRead()
        XCTAssertNil(error, "Insertion succeeded")
    }

    func testBusyTimeout() {
        SwiftData.EnableWAL = false
        SwiftData.ReuseConnections = false
        let error = writeDuringRead(closeTimeout: 1)
        XCTAssertNil(error, "Insertion succeeded")
    }

    func testFilledCursor() {
        SwiftData.ReuseConnections = false
        SwiftData.EnableWAL = false
        XCTAssertNil(writeDuringRead(true), "Insertion succeeded")
    }

    fileprivate func writeDuringRead(_ safeQuery: Bool = false, closeTimeout: UInt64? = nil) -> MaybeErrorType? {

        // Query the database and hold the cursor.
        var c: Cursor<SDRow>!
        let result = swiftData!.withConnection(SwiftData.Flags.readOnly) { db -> Void in
            if safeQuery {
                c = db.executeQuery("SELECT * FROM history", factory: { $0 })
            } else {
                c = db.executeQueryUnsafe("SELECT * FROM history", factory: { $0 }, withArgs: nil)
            }
            return ()
        }

        XCTAssertNil(result.value.failureValue, "Queried database")

        // If we have a live cursor, this will step to the first result.
        // Stepping through a prepared statement without resetting it will lock the connection.
        let _ = c[0]

        // Close the cursor after a delay if there's a close timeout set.
        if let closeTimeout = closeTimeout {
            let queue = DispatchQueue(label: "cursor timeout queue", attributes: [])
            queue.asyncAfter(deadline: DispatchTime.now() + Double(Int64(closeTimeout * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
                c.close()
            }
        }

        defer { urlCounter += 1 }
        return addSite(BrowserSchema(), url: "http://url/\(urlCounter)", title: "title\(urlCounter)")
    }

    fileprivate func addSite(_ table: BrowserSchema, url: String, title: String) -> MaybeErrorType? {
        let result = swiftData!.withConnection(SwiftData.Flags.readWrite) { connection -> Void in
            let args: Args = [Bytes.generateGUID(), url, title]
            try connection.executeChange("INSERT INTO history (guid, url, title, is_deleted, should_upload) VALUES (?, ?, ?, 0, 0)", withArgs: args)
        }
        
        return result.value.failureValue
    }

    func testEncrypt() {
        // XXX: Something is holding an open connection to the normal database, making it impossible
        // to change its encryption. This kills it so that we can move on.
        let files = MockFiles()
        do {
            try files.remove("testSwiftData.db")
        } catch _ {
        }
        let path = testDB
        func verifyData(_ swiftData: SwiftData) -> MaybeErrorType? {
            let resultDeferred = swiftData.withConnection(SwiftData.Flags.readOnly) { db -> Void in
                return ()
            }
            return resultDeferred.value.failureValue
        }

        XCTAssertNotNil(SwiftData(filename: path!, schema: BrowserSchema(), files: files), "Connected to unencrypted database")

        // Encrypt the database.
        XCTAssertNil(verifyData(SwiftData(filename: path!, key: "Secret", schema: BrowserSchema(), files: files)), "Encrypted database")

        // Now change the encryption key.
        XCTAssertNil(verifyData(SwiftData(filename: path!, key: "Secret2", prevKey: "Secret", schema: BrowserSchema(), files: files)), "Re-encrypted database")

        // Changing the encryption without the prevKey should fail.
        XCTAssertNotNil(verifyData(SwiftData(filename: path!, schema: BrowserSchema(), files: files)), "Failed decrypting database")

        // Now remove the encryption key.
        XCTAssertNil(verifyData(SwiftData(filename: path!, prevKey: "Secret2", schema: BrowserSchema(), files: files)), "Decrypted database")
    }

    func testNulls() {
        guard let db = swiftData else {
            XCTFail("DB not open")
            return
        }
        db.withConnection(SwiftData.Flags.readWriteCreate) { db in
            try! db.executeChange("CREATE TABLE foo ( bar TEXT, baz INTEGER )")
            try! db.executeChange("INSERT INTO foo VALUES (NULL, 1), ('here', 2)")
            let shouldBeString = db.executeQuery("SELECT bar FROM foo WHERE baz = 2", factory: { (row) in row["bar"] }).asArray()[0]
            guard let s = shouldBeString as? String else {
                XCTFail("Couldn't cast.")
                return
            }
            XCTAssertEqual(s, "here")

            let shouldBeNull = db.executeQuery("SELECT bar FROM foo WHERE baz = 1", factory: { (row) in row["bar"] }).asArray()[0]
            XCTAssertNil(shouldBeNull as? String)
            XCTAssertNil(shouldBeNull)
        }.succeeded()
    }

    func testArrayCursor() {
        let data = ["One", "Two", "Three"]
        let t = ArrayCursor<String>(data: data)

        // Test subscript access
        XCTAssertNil(t[-1], "Subscript -1 returns nil")
        XCTAssertEqual(t[0]!, "One", "Subscript zero returns the correct data")
        XCTAssertEqual(t[1]!, "Two", "Subscript one returns the correct data")
        XCTAssertEqual(t[2]!, "Three", "Subscript two returns the correct data")
        XCTAssertNil(t[3], "Subscript three returns nil")

        // Test status data with default initializer
        XCTAssertEqual(t.status, CursorStatus.success, "Cursor as correct status")
        XCTAssertEqual(t.statusMessage, "Success", "Cursor as correct status message")
        XCTAssertEqual(t.count, 3, "Cursor as correct size")

        // Test generator access
        var i = 0
        for s in t {
            XCTAssertEqual(s!, data[i], "Subscript zero returns the correct data")
            i += 1
        }

        // Test creating a failed cursor
        let t2 = ArrayCursor<String>(data: data, status: CursorStatus.failure, statusMessage: "Custom status message")
        XCTAssertEqual(t2.status, CursorStatus.failure, "Cursor as correct status")
        XCTAssertEqual(t2.statusMessage, "Custom status message", "Cursor as correct status message")
        XCTAssertEqual(t2.count, 0, "Cursor as correct size")

        // Test subscript access return nil for a failed cursor
        XCTAssertNil(t2[0], "Subscript zero returns nil if failure")
        XCTAssertNil(t2[1], "Subscript one returns nil if failure")
        XCTAssertNil(t2[2], "Subscript two returns nil if failure")
        XCTAssertNil(t2[3], "Subscript three returns nil if failure")

        // Test that generator doesn't work with failed cursors
        var ran = false
        for s in t2 {
            print("Got \(s ?? "nil")", terminator: "\n")
            ran = true
        }
        XCTAssertFalse(ran, "for...in didn't run for failed cursor")
    }
}
