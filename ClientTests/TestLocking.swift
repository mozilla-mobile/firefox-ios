/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest

class TestLocking: XCTestCase {
    // Test creating a read lock while a read lock is already active
    func testReadLock() {
        let lock = Lock(name: "MyLock")
        var reading = false
        var passed = false

        let expectation = expectationWithDescription("main thread")
        lock.withReadLock { () -> Void in
            reading = true
            let queue = dispatch_queue_create("Test", nil)
            dispatch_async(queue) { () -> Void in
                lock.withReadLock() {
                    passed = reading
                    XCTAssertTrue(reading, "Can get two read locks at once")
                }

                expectation.fulfill()
            }

            // If we're reading, we'll wait for the inner read lock to pass before finishing
            self.waitForExpectationsWithTimeout(10, handler: nil)
            reading = false;
        }
        XCTAssertFalse(reading, "Reading is done")
        XCTAssertTrue(passed, "Multiple read locks were allowed")
    }

    // Test creating a write lock while a read lock is already active
    func testWriteLock() {
        let lock = Lock(name: "MyLock")
        var reading = false
        var writing = false
        var started = false

        let expectation = expectationWithDescription("main thread")
        let queue = dispatch_queue_create("Test", nil)

        lock.withReadLock {
            reading = true
            dispatch_async(queue) { () -> Void in
                started = true
                lock.withWriteLock { () -> Void in
                    writing = true
                    XCTAssertTrue(writing, "Writer is running")
                    XCTAssertFalse(reading, "Reader is finished")
                    writing = false
                    expectation.fulfill()
                }
                started = false
            }

            // Give the write thread some time to start (and block on the write lock)
            sleep(1)
            XCTAssertTrue(reading, "Reading thread is working")
            XCTAssertTrue(started, "Write thread is started")
            XCTAssertFalse(writing, "Write task is blocked")
            reading = false
        }

        waitForExpectationsWithTimeout(10, handler: nil)
        XCTAssertFalse(reading, "Reader is done")
        XCTAssertFalse(started, "Writer is done")
        XCTAssertFalse(writing, "Write task is done")
    }

    // Test two threads accessing the read Protector at the same time
    func testProtectorReading() {
        let p = Protector(name: "testProtector", item: [1,2,3]);
        var reading = false
        var passed = false
        let queue = dispatch_queue_create("Test", nil)

        let expectation = expectationWithDescription("main thread")
        dispatch_async(queue) { () -> Void in
            p.withReadLock { protected -> Void in
                XCTAssertEqual(protected[0], 1, "Item zero is correct")
                XCTAssertEqual(protected[1], 2, "Item one is correct")
                XCTAssertEqual(protected[2], 3, "Item two is correct")
                // protected[0] = 4 // This array is immuatable, so this won't build. Need a better way to test.
                passed = reading
                XCTAssertTrue(reading, "Can get two read protectors at once")
            }
            expectation.fulfill()
        }

        p.withReadLock { protected -> Void in
            reading = true
            // If we're reading, we'll wait for the inner read protectors to pass
            self.waitForExpectationsWithTimeout(10, handler: nil)
            XCTAssertEqual(protected[0], 1, "Item zero is correct")
            XCTAssertEqual(protected[1], 2, "Item one is correct")
            XCTAssertEqual(protected[2], 3, "Item two is correct")
            reading = false;
        }

        XCTAssertFalse(reading, "Reading is done")
        XCTAssertTrue(passed, "Multiple read locks were allowed")
    }

    // Test a writer accessing the protector at the same time a reader is active
    func testProtectorWriting() {
        let lock = Protector(name: "MyLock", item: [1,2,3])
        var reading = false
        var writing = false
        var started = false

        let expectation = expectationWithDescription("main thread")
        let queue = dispatch_queue_create("Test", nil)

        lock.withReadLock { protected -> Void in
            reading = true
            dispatch_async(queue) { () -> Void in
                started = true
                lock.withWriteLock { protected -> Void in
                    writing = true
                    XCTAssertEqual(protected[0], 1, "Item zero is correct")
                    XCTAssertEqual(protected[1], 2, "Item one is correct")
                    XCTAssertEqual(protected[2], 3, "Item two is correct")
                    protected[0] = 4
                    XCTAssertEqual(protected[0], 4, "Item zero modified")
                    XCTAssertTrue(writing, "Writer is running")
                    XCTAssertFalse(reading, "Reader is finished")
                    writing = false
                    expectation.fulfill()
                }
                started = false
            }

            // Give the write thread some time to start
            sleep(1)
            XCTAssertEqual(protected[0], 1, "Item zero is correct");
            XCTAssertEqual(protected[1], 2, "Item one is correct");
            XCTAssertEqual(protected[2], 3, "Item two is correct");
            XCTAssertTrue(reading, "Reading thread is working")
            XCTAssertTrue(started, "Write thread is started")
            XCTAssertFalse(writing, "Write task is blocked")
            reading = false
        }

        self.waitForExpectationsWithTimeout(10, handler: nil)
        XCTAssertFalse(reading, "Reader is done")
        XCTAssertFalse(started, "Writer is done")
        XCTAssertFalse(writing, "Write task is done")
        lock.withReadLock { protected -> Void in
            XCTAssertEqual(protected[0], 4, "Item zero was modified")
            XCTAssertEqual(protected[1], 2, "Item one is correct")
            XCTAssertEqual(protected[2], 3, "Item two is correct")
        }
    }
}
