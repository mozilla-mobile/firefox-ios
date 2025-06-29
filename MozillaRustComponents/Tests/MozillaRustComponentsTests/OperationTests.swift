/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
@testable import MozillaAppServices

final class OperationTests: XCTestCase {
    lazy var queue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()

    override func tearDownWithError() throws {
        queue.waitUntilAllOperationsAreFinished()
    }

    func catchAll(_ queue: OperationQueue, thunk: @escaping (Operation) throws -> Void) -> Operation {
        let op = BlockOperation()
        op.addExecutionBlock {
            try? thunk(op)
        }
        queue.addOperation(op)
        return op
    }

    func testOperationTimedOut() throws {
        var finishedNormally = false

        let job = catchAll(queue) { op in
            for _ in 0 ..< 50 {
                Thread.sleep(forTimeInterval: 0.1)
                guard !op.isCancelled else {
                    return
                }
            }

            if !op.isCancelled {
                finishedNormally = true
            }
        }

        let didFinishNormally = job.joinOrTimeout(timeout: 1.0)
        XCTAssertFalse(finishedNormally)
        XCTAssertFalse(didFinishNormally)
    }

    func testOperationFinishedNotmally() throws {
        var finishedNormally = false

        let job = catchAll(queue) { op in
            for _ in 0 ..< 5 {
                Thread.sleep(forTimeInterval: 0.1)
                guard !op.isCancelled else {
                    return
                }
            }

            if !op.isCancelled {
                finishedNormally = true
            }
        }

        let didFinishNormally = job.joinOrTimeout(timeout: 1.0)
        XCTAssertTrue(finishedNormally)
        XCTAssertTrue(didFinishNormally)
    }
}
