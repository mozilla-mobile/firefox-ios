// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Redux

// Global state used in FakeReduxViewController.
@MainActor
var store: Store<FakeReduxState>!

@MainActor
final class ReduxIntegrationTests: XCTestCase {
    let initialCountValue = 8

    var fakeReduxViewController: FakeReduxViewController!
    var mockState: FakeReduxState!
    var mockMiddleware: FakeReduxMiddleware!

    override func setUp() async throws {
        try await super.setUp()

        mockState = FakeReduxState()
        mockMiddleware = FakeReduxMiddleware()
        mockMiddleware.generateInitialCountValue = {
            return self.initialCountValue
        }

        store = Store(state: mockState,
                      reducer: FakeReduxState.reducer,
                      middlewares: [mockMiddleware.fakeProvider])

        // Initialize the VC after store and middleware are set up
        fakeReduxViewController = createAndLoadViewController()
    }

    // This test will fail if actions are not completely processed before the next action is fired (i.e. action queuing).
    func testDispatchStore_IncreaseCounter() {
        fakeReduxViewController.increaseCounter()

        XCTAssertEqual(fakeReduxViewController.receivedStateCounterValue, initialCountValue + 1)
    }

    // This test will fail if actions are not completely processed before the next action is fired (i.e. action queuing).
    func testDispatchStore_DecreaseCounter() {
        fakeReduxViewController.decreaseCounter()

        XCTAssertEqual(fakeReduxViewController.receivedStateCounterValue, initialCountValue - 1)
    }

    func testDispatchStore_SetPrivateMode() {
        let expectedResult = true
        fakeReduxViewController.setPrivateMode(to: expectedResult)

        XCTAssertEqual(fakeReduxViewController.isInPrivateMode, expectedResult)
    }

    func testDispatchStore_TogglePrivateMode() {
        let expectedResult = false
        fakeReduxViewController.setPrivateMode(to: true)
        fakeReduxViewController.setPrivateMode(to: expectedResult)

        XCTAssertEqual(fakeReduxViewController.isInPrivateMode, expectedResult)
    }

    // MARK: - Helper functions

    private func createAndLoadViewController() -> FakeReduxViewController {
        let fakeViewController = FakeReduxViewController()
        fakeViewController.view.setNeedsLayout()

        return fakeViewController
    }
}
