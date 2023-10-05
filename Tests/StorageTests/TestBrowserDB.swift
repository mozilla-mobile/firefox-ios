// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
@testable import Storage
import XCTest

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

    class MockFailingSchema: Schema {
        var name: String { return "FAILURE" }
        var version: Int { return BrowserSchema.DefaultVersion + 1 }
        func drop(_ db: SQLiteDBConnection) -> Bool {
            return true
        }
        func create(_ db: SQLiteDBConnection) -> Bool {
            return false
        }
        func update(_ db: SQLiteDBConnection, from: Int) -> Bool {
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

    func mozWaitForCondition(_ condition: @autoclosure () -> Bool, timeout: TimeInterval = 5.0, errorMessage: String) {
        let startTime = Date()

        while !condition() {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail(errorMessage)
                break
            }
            usleep(10000)
        }
    }

    func mozWaitForEqual<T: Equatable>(_ expected: T, _ actual: @autoclosure () -> T?, timeout: TimeInterval = 5.0, errorMessage: String) {
        let startTime = Date()

        while actual() != expected {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail(errorMessage)
                break
            }
            usleep(10000)
        }
    }

    func mozWaitForComparison(_ comparison: @autoclosure () -> ComparisonResult, toBe result: ComparisonResult, timeout: TimeInterval = 5.0, errorMessage: String) {
        let startTime = Date()

        while comparison() != result {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail(errorMessage)
                break
            }
            usleep(10000)
        }
    }

    func mozWaitForNotEqual<T: Equatable>(_ value1: @autoclosure () -> T, _ value2: @autoclosure () -> T, timeout: TimeInterval = 5.0, errorMessage: String) {
        let startTime = Date()

        while value1() == value2() {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail(errorMessage)
                break
            }
            usleep(10000)
        }
    }

    func mozWaitForAttributes(file: String, errorMessage: String, timeout: TimeInterval = 5.0) -> [FileAttributeKey: Any]? {
        let startTime = Date()

        var attributes: [FileAttributeKey: Any]?
        while Date().timeIntervalSince(startTime) < timeout {
            do {
                attributes = try self.files.attributesForFileAt(relativePath: file)
                if !attributes!.isEmpty {
                    return attributes
                }
            } catch {
                // Simply continue the loop in case of an error.
            }

            // Pause for a fraction of a second to avoid tight-loop spinning.
            Thread.sleep(forTimeInterval: 0.05)
        }

        // If the loop exits without returning, it means the condition was not satisfied within the timeout.
        print(errorMessage)
        return nil
    }

    @discardableResult
    func waitForNotification(name: Notification.Name, timeout: TimeInterval = 5.0, action: () -> Void) -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var observed = false
        let token = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { _ in
            observed = true
            semaphore.signal()
        }

        action()  // Trigger the action after setting up the observer.

        defer { NotificationCenter.default.removeObserver(token) }

        _ = semaphore.wait(timeout: .now() + timeout)

        if !observed {
            XCTFail("Waited for \(name.rawValue) notification but did not receive it.")
        }

        return observed
    }

    func testUpgradeV33toV34RemovesLongURLs() {
        let db = BrowserDB(filename: "v33.db", schema: BrowserSchema(), files: SupportingFiles())
        let results = db.runQuery("SELECT bmkUri, title FROM bookmarksLocal WHERE type = 1", args: nil, factory: { row in
            (row[0] as! String, row[1] as! String)
        }).value.successValue!

        // The bookmark with the long URL has been deleted.
        XCTAssertTrue(results.count == 1)

        let remaining = results[0]!

        // This one's title has been truncated to 4096 chars.
        XCTAssertEqual(remaining.1.count, 4096)
        XCTAssertEqual(remaining.1.utf8.count, 4096)
        XCTAssertTrue(remaining.1.hasPrefix("abcdefghijkl"))
        XCTAssertEqual(remaining.0, "http://example.com/short")
    }

    // Temp. Disabled: https://mozilla-hub.atlassian.net/browse/FXIOS-7505
    func testMovesDB() throws {
        var db = BrowserDB(filename: "foo.db", schema: BrowserSchema(), files: self.files)

        db.run("CREATE TABLE foo (bar TEXT)").succeeded()

        mozWaitForCondition(files.exists("foo.db"), errorMessage: "Expected foo.db to exist")
        mozWaitForCondition(files.exists("foo.db-shm"), errorMessage: "Expected foo.db-shm to exist")
        mozWaitForCondition(files.exists("foo.db-wal"), errorMessage: "Expected foo.db-wal to exist")

        let shmAAttributes = try files.attributesForFileAt(relativePath: "foo.db-shm")
        let creationA = shmAAttributes[FileAttributeKey.creationDate] as! Date
        let inodeA = (shmAAttributes[FileAttributeKey.systemFileNumber] as! NSNumber).uintValue

        mozWaitForCondition(!files.exists("foo.db.bak.1"), errorMessage: "Expected foo.db.bak.1 not to exist")
        mozWaitForCondition(!files.exists("foo.db.bak.1-shm"), errorMessage: "Expected foo.db.bak.1-shm not to exist")
        mozWaitForCondition(!files.exists("foo.db.bak.1-wal"), errorMessage: "Expected foo.db.bak.1-wal not to exist")

        let center = NotificationCenter.default
        let listener = MockListener()
        center.addObserver(listener, selector: #selector(MockListener.onDatabaseWasRecreated), name: .DatabaseWasRecreated, object: nil)
        defer { center.removeObserver(listener) }

        waitForNotification(name: .DatabaseWasClosed) {
                db.forceClose()
        }

        db = BrowserDB(filename: "foo.db", schema: MockFailingSchema(), files: self.files)
        db.run("CREATE TABLE foo (bar TEXT)").failed() // This might not actually write since we'll get a failed connection

        db = BrowserDB(filename: "foo.db", schema: BrowserSchema(), files: self.files)
        db.run("CREATE TABLE foo (bar TEXT)").succeeded()

        mozWaitForCondition(files.exists("foo.db"), errorMessage: "Expected foo.db to exist")
        mozWaitForCondition(files.exists("foo.db-shm"), errorMessage: "Expected foo.db-shm to exist")
        mozWaitForCondition(files.exists("foo.db-wal"), errorMessage: "Expected foo.db-wal to exist")

        let shmBAttributes = try files.attributesForFileAt(relativePath: "foo.db-shm")
        let creationB = shmBAttributes[FileAttributeKey.creationDate] as! Date
        let inodeB = (shmBAttributes[FileAttributeKey.systemFileNumber] as! NSNumber).uintValue

        mozWaitForComparison(creationA.compare(creationB), toBe: .orderedAscending, errorMessage: "Expected creationA to be ordered ascending compared to creationB")
        mozWaitForNotEqual(inodeA, inodeB, errorMessage: "Expected inodeA to not be equal to inodeB")

        mozWaitForCondition(files.exists("foo.db.bak.1"), errorMessage: "Expected foo.db.bak.1 to exist")
        mozWaitForCondition(!files.exists("foo.db.bak.1-shm"), errorMessage: "Expected foo.db.bak.1-shm not to exist")
        mozWaitForCondition(!files.exists("foo.db.bak.1-wal"), errorMessage: "Expected foo.db.bak.1-wal not to exist")

        mozWaitForEqual("foo.db", listener.notification?.object as? String, errorMessage: "Expected listener.notification?.object to equal foo.db")
    }

    func testConcurrentQueriesDealloc() {
        let expectation = self.expectation(description: "Got all DB results")

        let db = BrowserDB(filename: "foo.db", schema: BrowserSchema(), files: self.files)
        db.run("CREATE TABLE foo (id INTEGER PRIMARY KEY AUTOINCREMENT, bar TEXT)").succeeded()

        _ = db.withConnection { connection -> Void in
            for i in 0..<1000 {
                let args: Args = ["bar \(i)"]
                try connection.executeChange("INSERT INTO foo (bar) VALUES (?)", withArgs: args)
            }
        }

        func fooBarFactory(_ row: SDRow) -> [String: Any] {
            var result: [String: Any] = [:]
            result["id"] = row["id"]
            result["bar"] = row["bar"]
            return result
        }

        let shortConcurrentQuery = db.runQueryConcurrently("SELECT * FROM foo LIMIT 1", args: nil, factory: fooBarFactory)

        _ = shortConcurrentQuery.bind { result -> Deferred<Maybe<[[String: Any]]>> in
            if let results = result.successValue?.asArray() {
                expectation.fulfill()
                return deferMaybe(results)
            }

            return deferMaybe(DatabaseError(description: "Unable to execute concurrent short-running query"))
        }

        trackForMemoryLeaks(shortConcurrentQuery)

        waitForExpectations(timeout: 10, handler: nil)
    }

    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated, potential memory leak.", file: file, line: line)
        }
    }
}
