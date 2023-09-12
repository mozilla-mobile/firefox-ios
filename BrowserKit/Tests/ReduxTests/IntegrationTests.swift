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

    override func setUp() {
        super.setUp()
        fakeViewController = FakeReduxViewController()
    }

    override func tearDown() {
        super.tearDown()
        fakeViewController = nil
    }

    func testDispatchStore() {
        fakeViewController.increaseCounter()

        XCTAssertEqual(fakeViewController.counter, 1)
    }
}
