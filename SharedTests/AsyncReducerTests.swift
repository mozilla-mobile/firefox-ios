/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
import Deferred
@testable import Shared

private let timeoutPeriod: TimeInterval = 600

class AsyncReducerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSimpleBehaviour() {
        let expectation = self.expectation(description: #function)
        happyCase(expectation, combine: simpleAdder)
    }

    func testWaitingFillerBehaviour() {
        let expectation = self.expectation(description: #function)
        happyCase(expectation, combine: waitingFillingAdder)
    }

    func testWaitingFillerAppendingBehaviour() {
        let expectation = self.expectation(description: #function)
        appendingCase(expectation, combine: waitingFillingAdder)
    }

    func testFailingCombine() {
        let expectation = self.expectation(description: #function)
        let combine = { (a: Int, b: Int) -> Deferred<Maybe<Int>> in
            if a >= 6 {
                return deferMaybe(TestError())
            }
            return deferMaybe(a + b)
        }
        let reducer = AsyncReducer(initialValue: 0, combine: combine)
        reducer.terminal.upon { res in
            XCTAssert(res.isFailure)
            expectation.fulfill()
        }

        self.append(reducer, items: 1, 2, 3, 4, 5)
        waitForExpectations(timeout: timeoutPeriod, handler: nil)
    }

    func testFailingAppend() {
        let expectation = self.expectation(description: #function)

        let reducer = AsyncReducer(initialValue: 0, combine: simpleAdder)
        reducer.terminal.upon { res in
            XCTAssert(res.isSuccess)
            XCTAssertEqual(res.successValue!, 15)
        }

        self.append(reducer, items: 1, 2, 3, 4, 5)

        delay(0.1) {
            do {
                let _ = try reducer.append(6, 7, 8)
                XCTFail("Can't append to a reducer that's already finished")
            } catch let error {
                XCTAssert(true, "Properly received error on finished reducer \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeoutPeriod, handler: nil)
    }

    func testAccumulation() {
        var addDuring: [String] = ["bar", "baz"]
        var reducer: AsyncReducer<[String: Bool], String>!

        func combine(_ t: [String: Bool], u: String) -> Deferred<Maybe<[String: Bool]>> {
            var out = t
            out[u] = true

            // Pretend that some new work arrived while we were handling this.
            if let nextUp = addDuring.popLast() {
                let _ = try! reducer.append(nextUp)
            }

            return deferMaybe(out)
        }

        // Start with 'foo'.
        reducer = AsyncReducer(initialValue: deferMaybe([:]), combine: combine)
        let _ = try! reducer.append("foo")

        // Wait for the result. We should have handled all three by the time this returns.
        let result = reducer.terminal.value
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(["foo": true, "bar": true, "baz": true], result.successValue!)
    }
}

extension AsyncReducerTests {
    func happyCase(_ expectation: XCTestExpectation, combine: @escaping (Int, Int) -> Deferred<Maybe<Int>>) {
        let reducer = AsyncReducer(initialValue: 0, combine: combine)
        reducer.terminal.upon { res in
            XCTAssert(res.isSuccess)
            XCTAssertEqual(res.successValue!, 15)
            expectation.fulfill()
        }

        self.append(reducer, items: 1, 2, 3, 4, 5)
        waitForExpectations(timeout: timeoutPeriod, handler: nil)
    }

    func appendingCase(_ expectation: XCTestExpectation, combine: @escaping (Int, Int) -> Deferred<Maybe<Int>>) {
        let reducer = AsyncReducer(initialValue: 0, combine: combine)
        reducer.terminal.upon { res in
            XCTAssert(res.isSuccess)
            XCTAssertEqual(res.successValue!, 15)
            expectation.fulfill()
        }

        self.append(reducer, items: 1, 2)

        delay(0.1) {
            self.append(reducer, items: 3, 4, 5)
        }
        waitForExpectations(timeout: timeoutPeriod, handler: nil)
    }

    func append(_ reducer: AsyncReducer<Int, Int>, items: Int...) {
        do {
            let _ = try reducer.append(items)
        } catch let error {
            XCTFail("Append failed with \(error)")
        }
    }
}

class TestError: MaybeErrorType {
    var description = "Error"
}

private let serialQueue = DispatchQueue(label: "com.mozilla.test.serial", attributes: [])
private let concurrentQueue = DispatchQueue(label: "com.mozilla.test.concurrent", attributes: DispatchQueue.Attributes.concurrent)

func delay(_ delay: Double, closure:@escaping () -> Void) {
    concurrentQueue.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

private func simpleAdder(_ a: Int, b: Int) -> Deferred<Maybe<Int>> {
    return deferMaybe(a + b)
}

private func waitingFillingAdder(_ a: Int, b: Int) -> Deferred<Maybe<Int>> {
    let deferred = Deferred<Maybe<Int>>()
    delay(0.1) {
        deferred.fill(Maybe(success: a + b))
    }
    return deferred
}

