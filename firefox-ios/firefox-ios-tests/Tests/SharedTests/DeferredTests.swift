// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Shared
import XCTest

// Trivial test for using Deferred.
class DeferredTests: XCTestCase {
    func testDeferred() {
        let d = Deferred<Int>()
        XCTAssertNil(d.peek(), "Value not yet filled.")

        let expectation = self.expectation(description: "Waiting on value.")
        d.upon({ x in
            expectation.fulfill()
        })

        d.fill(5)
        waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error, "\(error.debugDescription)")
        }

        XCTAssertEqual(5, d.peek()!, "Value is filled.")
    }

    func testMultipleUponBlocks() {
        let e1 = self.expectation(description: "First.")
        let e2 = self.expectation(description: "Second.")
        let d = Deferred<Int>()
        d.upon { x in
            XCTAssertEqual(x, 5)
            e1.fulfill()
        }
        d.upon { x in
            XCTAssertEqual(x, 5)
            e2.fulfill()
        }
        d.fill(5)
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testOperators() {
        let e1 = self.expectation(description: "First.")
        let e2 = self.expectation(description: "Second.")

        let f1: () -> Deferred<Maybe<Int>> = {
            return deferMaybe(5)
        }

        let f2: (_ x: Int) -> Deferred<Maybe<String>> = {
            if $0 == 5 {
                e1.fulfill()
            }
            return deferMaybe("Hello!")
        }

        // Type signatures:
        let combined: () -> Deferred<Maybe<String>> = { f1() >>== f2 }
        let result: Deferred<Maybe<String>> = combined()

        result.upon {
            XCTAssertEqual("Hello!", $0.successValue!)
            e2.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testPassAccumulate_andDoesntLeak() {
        let expectation = self.expectation(description: "Deinit is called")
        let accumulateCall: () -> Success = {
            return succeed()
        }

        var myclass: AccumulateTestClass? = AccumulateTestClass(
            expectation: expectation,
            accumulateCall: accumulateCall
        )
        trackForMemoryLeaks(myclass!)
        myclass = nil

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testFailAccumulate_andDoesntLeak() {
        let expectation = self.expectation(description: "Deinit is called")

        let accumulateCall: () -> Success = {
            return Deferred(value: Maybe(failure: AccumulateTestClass.Error()))
        }

        var myclass: AccumulateTestClass? = AccumulateTestClass(
            expectation: expectation,
            accumulateCall: accumulateCall
        )
        trackForMemoryLeaks(myclass!)
        myclass = nil

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDeferMaybe() {
        XCTAssertTrue(deferMaybe("foo").value.isSuccess)
    }

    @MainActor // Test explicitly calling `all` on the main thread
    func testDeferredAll_calledOnMainThread() {
        let expectation = self.expectation(description: "All blocks ran")

        let deferreds = [
            Success(value: Maybe(success: ()), defaultQueue: .main),
            Success(value: Maybe(success: ()), defaultQueue: .global())
        ]

        _ = all(deferreds).bind { results -> Success in
            XCTAssertEqual(results.count, 2)

            if let failure = results.first(where: { $0.isFailure }) {
                return deferMaybe(failure.failureValue!)
            }

            expectation.fulfill()
            return succeed()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    @MainActor // Test explicitly calling `all` on the main thread
    func testDeferredAll_calledOnMainThread_withFailure() {
        let expectation = self.expectation(description: "All blocks ran")

        let deferreds = [
            Success(value: Maybe(success: ()), defaultQueue: .main),
            Success(value: Maybe(success: ()), defaultQueue: .global()),
            Success(value: Maybe(success: ()), defaultQueue: .main),
            Success(value: Maybe(failure: NSError()), defaultQueue: .main)
        ]

        _ = all(deferreds).bind { results -> Success in
            XCTAssertEqual(results.count, 4)

            if let failure = results.first(where: { $0.isFailure }) {
                // We expect one of the results to be a failure
                expectation.fulfill()
                return deferMaybe(failure.failureValue!)
            }

            return succeed()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDeferredAll_calledOnBackgroundThread() {
        let expectation = self.expectation(description: "All blocks ran")

        let deferreds = [
            Success(value: Maybe(success: ()), defaultQueue: .main),
            Success(value: Maybe(success: ()), defaultQueue: .global())
        ]

        // Run from a background thread
        Task {
            _ = all(deferreds).bind { results -> Success in
                XCTAssertEqual(results.count, 2)

                if let failure = results.first(where: { $0.isFailure }) {
                    return deferMaybe(failure.failureValue!)
                }

                expectation.fulfill()
                return succeed()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDeferredAll_calledOnBackgroundThread_withFailure() {
        let expectation = self.expectation(description: "All blocks ran")

        let deferreds = [
            Success(value: Maybe(success: ()), defaultQueue: .main),
            Success(value: Maybe(success: ()), defaultQueue: .global()),
            Success(value: Maybe(success: ()), defaultQueue: .main),
            Success(value: Maybe(failure: NSError()), defaultQueue: .main)
        ]

        // Run from a background thread
        Task {
            _ = all(deferreds).bind { results -> Success in
                XCTAssertEqual(results.count, 4)

                if let failure = results.first(where: { $0.isFailure }) {
                    // We expect one of the results to be a failure
                    expectation.fulfill()
                    return deferMaybe(failure.failureValue!)
                }

                return succeed()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }
}

// MARK: Helper
private extension DeferredTests {
    class AccumulateTestClass {
        class Error: MaybeErrorType {
            var description = "Error"
        }

        let expectation: XCTestExpectation

        init(expectation: XCTestExpectation, accumulateCall: @escaping () -> Success) {
            self.expectation = expectation
            accumulate([accumulateCall]).upon { _ in }
        }

        deinit {
            expectation.fulfill()
        }
    }

    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "Instance should have been deallocated, potential memory leak.",
                file: file,
                line: line
            )
        }
    }
}
