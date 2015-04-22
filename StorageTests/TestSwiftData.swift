/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
import Storage

class TestSwiftData: XCTestCase {
    var swiftData: SwiftData!

    override func setUp() {
        let files = MockFiles()
        files.remove("testSwiftData.db")
        let testDB = files.getAndEnsureDirectory()!.stringByAppendingPathComponent("testSwiftData.db")
        swiftData = SwiftData(filename: testDB)

        // Ensure static flags match expected values.
        XCTAssert(SwiftData.ReuseConnections, "Reusing database connections")
        XCTAssert(SwiftData.EnableWAL, "WAL enabled")
    }

    override func tearDown() {
        // Restore static flags to their default values.
        SwiftData.ReuseConnections = true
        SwiftData.EnableWAL = true
    }

    func testNoWALOrConnectionReuse() {
        SwiftData.ReuseConnections = false
        SwiftData.EnableWAL = false
        var error = writeDuringRead()
        XCTAssertEqual(error!.code, 5, "Got 'database is locked' error")
    }

    func testNoConnectionReuse() {
        SwiftData.ReuseConnections = false
        var error = writeDuringRead()
        XCTAssertEqual(error!.code, 8, "Got 'attempt to write to read-only database' error")
    }

    func testNoWAL() {
        SwiftData.EnableWAL = false
        var error = writeDuringRead()
        XCTAssertNil(error, "Insertion succeeded")
    }

    func testDefaultSettings() {
        var error = writeDuringRead()
        XCTAssertNil(error, "Insertion succeeded")
    }

    func testBusyTimeout() {
        SwiftData.ReuseConnections = false
        SwiftData.EnableWAL = false
        var error = writeDuringRead(closeTimeout: 1)
        XCTAssertNil(error, "Insertion succeeded")
    }

    func testFilledCursor() {
        SwiftData.ReuseConnections = false
        SwiftData.EnableWAL = false
        var error = writeDuringRead(safeQuery: true)
        XCTAssertNil(error, "Insertion succeeded")
    }

    private func writeDuringRead(safeQuery: Bool = false, closeTimeout: UInt64? = nil) -> NSError? {
        let historyTable = HistoryTable<Site>()

        swiftData.withConnection(SwiftData.Flags.ReadWriteCreate) { db in
            historyTable.create(db, version: 1)
            return nil
        }

        var error = addSite(historyTable, url: "url0", title: "title0")
        XCTAssertNil(error, "Inserted URL")

        // Query the database and hold the cursor.
        var historyCursor: Cursor!
        error = swiftData.withConnection(SwiftData.Flags.ReadOnly) { db in
            let (query, args) = historyTable.getQueryAndArgs(nil)!
            if safeQuery {
                historyCursor = db.executeQuery(query, factory: historyTable.factory!, withArgs: args)
            } else {
                historyCursor = db.executeQueryUnsafe(query, factory: historyTable.factory!, withArgs: args)
            }
            return nil
        }
        XCTAssertNil(error, "Queried database")

        // If we have a live cursor, this will step to the first result.
        // Stepping through a prepared statement without resetting it will lock the connection.
        historyCursor[0]

        // Close the cursor after a delay if there's a close timeout set.
        if let closeTimeout = closeTimeout {
            let queue = dispatch_queue_create("cursor timeout queue", DISPATCH_QUEUE_SERIAL)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(closeTimeout * NSEC_PER_SEC)), queue) {
                historyCursor.close()
            }
        }

        return addSite(historyTable, url: "url1", title: "title1")
    }

    private func addSite(history: HistoryTable<Site>, url: String, title: String) -> NSError? {
        return swiftData.withConnection(.ReadWrite) { connection -> NSError? in
            var err: NSError?
            let site = Site(url: url, title: title)
            history.insert(connection, item: site, err: &err)
            return err
        }
    }
}