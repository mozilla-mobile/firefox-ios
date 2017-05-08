/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Storage
import XCGLogger

import XCTest

private let log = XCGLogger.default

class TestBrowserDB: XCTestCase {
    let files = MockFiles()

    fileprivate func rm(_ path: String) {
        do {
            try files.remove(path)
        } catch {
        }
    }

    override func setUp() {
        super.setUp()
        rm("foo.db")
        rm("foo.db-shm")
        rm("foo.db-wal")
        rm("foo.db.bak.1")
        rm("foo.db.bak.1-shm")
        rm("foo.db.bak.1-wal")
    }

    class MockFailingTable: Table {
        var name: String { return "FAILURE" }
        var version: Int { return 1 }
        func exists(_ db: SQLiteDBConnection) -> Bool {
            return false
        }
        func drop(_ db: SQLiteDBConnection) -> Bool {
            return true
        }
        func create(_ db: SQLiteDBConnection) -> Bool {
            return false
        }
        func updateTable(_ db: SQLiteDBConnection, from: Int) -> Bool {
            return false
        }
    }

    fileprivate class MockListener {
        var notification: Notification?
        @objc
        func onDatabaseWasRecreated(_ notification: Notification) {
            self.notification = notification
        }
    }

    func testMovesDB() {
        let db = BrowserDB(filename: "foo.db", files: self.files)
        db.attachDB(filename: "metadata.db", as: AttachedDatabaseMetadata)
        XCTAssertTrue(db.createOrUpdate(BrowserTable()) == .success)

        db.run("CREATE TABLE foo (bar TEXT)").succeeded() // Just so we have writes in the WAL.

        XCTAssertTrue(files.exists("foo.db"))
        XCTAssertTrue(files.exists("foo.db-shm"))
        XCTAssertTrue(files.exists("foo.db-wal"))

        // Grab a pointer to the -shm so we can compare later.
        let shmAAttributes = try! files.attributesForFileAt(relativePath: "foo.db-shm")
        let creationA = shmAAttributes[FileAttributeKey.creationDate] as! Date
        let inodeA = (shmAAttributes[FileAttributeKey.systemFileNumber] as! NSNumber).uintValue

        XCTAssertFalse(files.exists("foo.db.bak.1"))
        XCTAssertFalse(files.exists("foo.db.bak.1-shm"))
        XCTAssertFalse(files.exists("foo.db.bak.1-wal"))

        let center = NotificationCenter.default
        let listener = MockListener()
        center.addObserver(listener, selector: #selector(MockListener.onDatabaseWasRecreated(_:)), name: NotificationDatabaseWasRecreated, object: nil)
        defer { center.removeObserver(listener) }

        // It'll still fail, but it moved our old DB.
        // Our current observation is that closing the DB deletes the .shm file and also
        // checkpoints the WAL.
        XCTAssertFalse(db.createOrUpdate(MockFailingTable()) == .success)
        db.run("CREATE TABLE foo (bar TEXT)").succeeded() // Just so we have writes in the WAL.

        XCTAssertTrue(files.exists("foo.db"))
        XCTAssertTrue(files.exists("foo.db-shm"))
        XCTAssertTrue(files.exists("foo.db-wal"))

        // But now it's been reopened, it's not the same -shm!
        let shmBAttributes = try! files.attributesForFileAt(relativePath: "foo.db-shm")
        let creationB = shmBAttributes[FileAttributeKey.creationDate] as! Date
        let inodeB = (shmBAttributes[FileAttributeKey.systemFileNumber] as! NSNumber).uintValue
        XCTAssertTrue(creationA.compare(creationB) != ComparisonResult.orderedDescending)
        XCTAssertNotEqual(inodeA, inodeB)

        XCTAssertTrue(files.exists("foo.db.bak.1"))
        XCTAssertFalse(files.exists("foo.db.bak.1-shm"))
        XCTAssertFalse(files.exists("foo.db.bak.1-wal"))

        // The right notification was issued.
        XCTAssertEqual("foo.db", (listener.notification?.object as? String))
    }
}
