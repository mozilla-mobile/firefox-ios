/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest

class TestSchemaTable: XCTestCase {
    // This is a very basic test. Adds an entry. Retrieves it, and then clears the database
    func testTable() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", files: files)

        // Test creating a table
        var testTable = getCreateTable()
        db.createOrUpdate(testTable)

        // Now make sure the item is in the table-table
        var err: NSError? = nil
        let table = SchemaTable()
        var cursor = db.withReadableConnection(&err) { (connection, err) -> Cursor<TableInfo> in
            return table.query(connection, options: QueryOptions(filter: testTable.name))
        }

        verifyTable(cursor, table: testTable)
        // We have to close this cursor to ensure we don't get results from a sqlite memory cache below when
        // we requery the table.
        cursor.close()

        // Now test updating the table
        testTable = getUpgradeTable()
        db.createOrUpdate(testTable)
        cursor = db.withReadableConnection(&err) { (connection, err) -> Cursor<TableInfo> in
            return table.query(connection, options: QueryOptions(filter: testTable.name))
        }
        verifyTable(cursor, table: testTable)
        // We have to close this cursor to ensure we don't get results from a sqlite memory cache below when
        // we requery the table.
        cursor.close()

        // Now try updating it again to the same version. This shouldn't call create or upgrade
        testTable = getNoOpTable()
        db.createOrUpdate(testTable)

        do {
            // Cleanup
            try files.remove("browser.db")
        } catch _ {
        }
    }

    // Helper for verifying that the data in a cursor matches whats in a table
    private func verifyTable(cursor: Cursor<TableInfo>, table: TestTable) {
        XCTAssertEqual(cursor.count, 1, "Cursor is the right size")
        let data = cursor[0] as! TableInfoWrapper
        XCTAssertNotNil(data, "Found an object of the right type")
        XCTAssertEqual(data.name, table.name, "Table info has the right name")
        XCTAssertEqual(data.version, table.version, "Table info has the right version")
    }

    // A test class for fake table creation/upgrades
    class TestTable: Table {
        var name: String { return "testName" }
        var _version: Int = -1
        var version: Int { return _version }

        typealias Type = Int

        // Called if the table is created
        let createCallback: () -> Bool
        // Called if the table is upgraded
        let updateCallback: (from: Int, to: Int) -> Bool

        let dropCallback: (() -> Void)?

        init(version: Int,
                createCallback: () -> Bool,
                updateCallback: (from: Int, to: Int) -> Bool,
                dropCallback: (() -> Void)? = nil) {
            self._version = version
            self.createCallback = createCallback
            self.updateCallback = updateCallback
            self.dropCallback = dropCallback
        }

        func exists(db: SQLiteDBConnection) -> Bool {
            let res = db.executeQuery("SELECT name FROM sqlite_master WHERE type = 'table' AND name=?", factory: StringFactory, withArgs: [name])
            return res.count > 0
        }

        func drop(db: SQLiteDBConnection) -> Bool {
            if let dropCallback = dropCallback {
                dropCallback()
            }
            let sqlStr = "DROP TABLE IF EXISTS \(name)"
            let err = db.executeChange(sqlStr, withArgs: [])
            return err == nil
        }

        func create(db: SQLiteDBConnection, version: Int) -> Bool {
            // BrowserDB uses a different query to determine if a table exists, so we need to ensure it actually happens
            db.executeChange("CREATE TABLE IF NOT EXISTS \(name) (ID INTEGER PRIMARY KEY AUTOINCREMENT)")
            return createCallback()
        }

        func updateTable(db: SQLiteDBConnection, from: Int, to: Int) -> Bool {
            return updateCallback(from: from, to: to)
        }

        // These are all no-ops for testing
        func insert(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int { return -1 }
        func update(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int { return -1 }
        func delete(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int { return -1 }
        func query(db: SQLiteDBConnection, options: QueryOptions?) -> Cursor<Type> { return Cursor(status: .Failure, msg: "Shouldn't hit this") }
    }

    // This function will create a table with appropriate callbacks set. Pass "create" if you expect the table to
    // be created. Pass "update" if it should be updated. Pass anythign else if neither callback should be called.
    func getCreateTable() -> TestTable {
        let t = TestTable(version: 1, createCallback: { _ -> Bool in
            XCTAssert(true, "Should have created table")
            return true
        }, updateCallback: { (from, to) -> Bool in
            XCTFail("Should not try to update table")
            return false
        })
        return t
    }

    func getUpgradeTable() -> TestTable {
        var upgraded = false
        var dropped = false
        let t = TestTable(version: 2, createCallback: { _ -> Bool in
            XCTAssertTrue(dropped, "Create should be called after upgrade attempt")
            return true
        }, updateCallback: { (from, to) -> Bool in
            XCTAssert(true, "Should try to update table")
            XCTAssertEqual(from, 1, "From is correct")
            XCTAssertEqual(to, 2, "To is correct")

            // We'll return false here. The db will take that as a sign to drop and recreate our table.
            upgraded = true
            return false
        }, dropCallback: { () -> Void in
            XCTAssertTrue(upgraded, "Should try to drop table")
            dropped = true
        })
        return t
    }

    func getNoOpTable() -> TestTable {
        let t = TestTable(version: 2, createCallback: { _ -> Bool in
            XCTFail("Should not try to create table")
            return false
        }, updateCallback: { (from, to) -> Bool in
            XCTFail("Should not try to update table")
            return false
        })
        return t
    }
}
