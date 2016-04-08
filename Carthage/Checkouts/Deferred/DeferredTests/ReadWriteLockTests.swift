//
//  ReadWriteLockTests.swift
//  ReadWriteLockTests
//
//  Created by John Gallagher on 7/19/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

import XCTest
import Deferred

func timeIntervalSleep(duration: NSTimeInterval) {
    usleep(useconds_t(duration * NSTimeInterval(USEC_PER_SEC)))
}

class PerfTestThread: NSThread {
    let iters: Int
    var lock: ReadWriteLock
    let joinLock = NSConditionLock(condition: 0)

    init(lock: ReadWriteLock, iters: Int) {
        self.lock = lock
        self.iters = iters
        super.init()
    }

    override func main() {
        joinLock.lock()
        let doNothing: () -> () = {}
        for i in 0 ..< iters {
            if (i % 10) == 0 {
                lock.withWriteLock(doNothing)
            } else {
                lock.withReadLock(doNothing)
            }
        }
        joinLock.unlockWithCondition(1)
    }

    func join() {
        joinLock.lockWhenCondition(1)
        joinLock.unlock()
    }
}

class ReadWriteLockTests: XCTestCase {
    var gcdLock: GCDReadWriteLock!
    var spinLock: SpinLock!
    var casSpinLock: CASSpinLock!
    var queue: dispatch_queue_t!

    override func setUp() {
        super.setUp()

        gcdLock = GCDReadWriteLock()
        spinLock = SpinLock()
        casSpinLock = CASSpinLock()

        queue = dispatch_queue_create("ReadWriteLockTests", DISPATCH_QUEUE_CONCURRENT)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testMultipleConcurrentReaders() {
        // do not test spinLock, as it does not allow concurrent reading
        let locks: [ReadWriteLock] = [gcdLock, casSpinLock]
        for (var lock) in locks {
            // start up 32 readers that block for 0.1 seconds each...
            for i in 0 ..< 32 {
                let expectation = expectationWithDescription("read \(lock)")
                dispatch_async(queue) {
                    lock.withReadLock {
                        timeIntervalSleep(0.1)
                        expectation.fulfill()
                    }
                }
            }

            // and make sure all 32 complete in < 3 second. If the readers
            // did not run concurrently, they would take >= 3.2 seconds
            waitForExpectationsWithTimeout(3, handler: nil)
        }
    }

    func testMultipleConcurrentWriters() {
        // all three lock types ensure writes happen exclusively
        let locks: [ReadWriteLock] = [gcdLock, casSpinLock, spinLock]
        for (var lock) in locks {
            var x: Int32 = 0

            // spin up 5 writers concurrently...
            for i in 0 ..< 5 {
                let expectation = expectationWithDescription("write \(lock) #\(i)")
                dispatch_async(queue) {
                    lock.withWriteLock {
                        // ... and make sure each runs in order by checking that
                        // no two blocks increment x at the same time
                        XCTAssertEqual(OSAtomicIncrement32Barrier(&x), 1)
                        timeIntervalSleep(0.05)
                        XCTAssertEqual(OSAtomicDecrement32Barrier(&x), 0)
                        expectation.fulfill()
                    }
                }
            }
            waitForExpectationsWithTimeout(5, handler: nil)
        }
    }

    func testSimultaneousReadersAndWriters() {
        // all three lock types ensure reads cannot run while writes do
        let locks: [ReadWriteLock] = [gcdLock, casSpinLock, spinLock]

        for (var lock) in locks {
            var x: Int32 = 0

            let startReader: (Int) -> () = { i in
                let expectation = self.expectationWithDescription("reader \(i)")
                dispatch_async(self.queue) {
                    lock.withReadLock {
                        // make sure we get the value of x either before or after
                        // the writer runs, never a partway-through value
                        XCTAssertTrue(x == 0 || x == 5)
                        expectation.fulfill()
                    }
                }
            }

            // spin up 32 readers before a writer
            for i in 0 ..< 32 {
                startReader(i)
            }
            // spin up a writer that (slowly) increments x from 0 to 5
            let expectation = expectationWithDescription("writer")
            dispatch_async(queue) {
                lock.withWriteLock {
                    for i in 0 ..< 5 {
                        OSAtomicIncrement32Barrier(&x)
                        timeIntervalSleep(0.1)
                    }
                    expectation.fulfill()
                }
            }
            // and spin up 32 more readers after
            for i in 32 ..< 64 {
                startReader(i)
            }
            
            waitForExpectationsWithTimeout(5, handler: nil)
        }
    }

    /*
    func measureReadLockSingleThread(var lock: ReadWriteLock, iters: Int) {
        let doNothing: () -> () = {}
        self.measureBlock {
            for i in 0 ..< iters {
                lock.withReadLock(doNothing)
            }
        }
    }

    func measureWriteLockSingleThread(var lock: ReadWriteLock, iters: Int) {
        let doNothing: () -> () = {}
        self.measureBlock {
            for i in 0 ..< iters {
                lock.withWriteLock(doNothing)
            }
        }
    }

    func measureLock90PercentReadsNThreads(var lock: ReadWriteLock, iters: Int, nthreads: Int) {
        self.measureBlock {
            var threads: [PerfTestThread] = []
            for i in 0 ..< nthreads {
                let t = PerfTestThread(lock: lock, iters: iters)
                t.start()
                threads.append(t)
            }
            for t in threads {
                t.join()
            }
        }
    }

    func testSingleThreadPerformanceGCDLockRead() {
        measureReadLockSingleThread(gcdLock, iters: 200_000)
    }
    func testSingleThreadPerformanceGCDLockWrite() {
        measureWriteLockSingleThread(gcdLock, iters: 200_000)
    }

    func testSingleThreadPerformanceSpinLockRead() {
        measureReadLockSingleThread(spinLock, iters: 1_000_000)
    }
    func testSingleThreadPerformanceSpinLockWrite() {
        measureWriteLockSingleThread(spinLock, iters: 1_000_000)
    }

    func testSingleThreadPerformanceCASSpinLockRead() {
        measureReadLockSingleThread(casSpinLock, iters: 1_000_000)
    }
    func testSingleThreadPerformanceCASSpinLockWrite() {
        measureWriteLockSingleThread(casSpinLock, iters: 1_000_000)
    }

    func test90PercentReads4ThreadsGCDLock() {
        measureLock90PercentReadsNThreads(gcdLock, iters: 2_500, nthreads: 4)
    }
    func test90PercentReads4ThreadsSpinLock() {
        measureLock90PercentReadsNThreads(spinLock, iters: 250_000, nthreads: 4)
    }
    func test90PercentReads4ThreadsCASSpinLock() {
        measureLock90PercentReadsNThreads(casSpinLock, iters: 250_000, nthreads: 4)
    }
    */
}
