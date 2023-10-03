// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Redux
let store = Store(state: FakeReduxState(),
                  reducer: FakeReduxState.reducer,
                  middlewares: [FakeReduxMiddleware().fakeProvider])

final class IntegrationTests: XCTestCase {
    var fakeViewController: FakeReduxViewController!
    var expectedValue: Int!

    override func setUp() {
        super.setUp()
        fakeViewController = FakeReduxViewController()
        fakeViewController.view.setNeedsLayout()
    }

    override func tearDown() {
        super.tearDown()
        fakeViewController = nil
    }

    func testDispatchStore_IncreaseCounter() {
        getExpectedValue(shouldIncrease: true)
        fakeViewController.increaseCounter()

        // Needed to wait for Redux action handled async in main thread
        let expectation = self.expectation(description: "Redux integration test")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
            let intValue = Int(self.fakeViewController.label.text ?? "0")
            XCTAssertEqual(intValue, self.expectedValue)
        }
        waitForExpectations(timeout: 1)
    }

    func testDispatchStore_DecreaseCounter() {
        getExpectedValue(shouldIncrease: false)
        fakeViewController.decreaseCounter()

        // Needed to wait for Redux action handled async in main thread
        let expectation = self.expectation(description: "Redux integration test")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
            let intValue = Int(self.fakeViewController.label.text ?? "0")
            XCTAssertEqual(intValue, self.expectedValue)
        }
        waitForExpectations(timeout: 1)
    }

    private func getExpectedValue(shouldIncrease: Bool) {
        // Needed to wait for Redux action handled async in main thread
        let expectation = self.expectation(description: "Redux integration test")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
            self.expectedValue = store.state.counter
            if shouldIncrease {
                self.expectedValue += 1
            } else {
                self.expectedValue -= 1
            }
        }
        waitForExpectations(timeout: 1)
    }
}
