// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Redux

@MainActor
final class StoreModernActionTests: XCTestCase {
    var mockState = MockState()
    let fakeWindowUUID = UUID()

    override func setUp() async throws {
        try await super.setUp()
        mockState = MockState()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        MockState.modernActionsReduced = []
    }

    func testDispatchBasicAction() throws {
        let store = Store(
            state: mockState,
            reducer: MockState.reducer,
            middlewares: [])

        let testAction = FakeReduxModernAction.counterIncreased(counterValue: 1)

        store.dispatch(testAction, forWindowUUID: fakeWindowUUID)

        guard MockState.modernActionsReduced.count == 1 else {
            XCTFail("Expected 1 action fired")
            return
        }

        let recordedAction = try XCTUnwrap(
            MockState.modernActionsReduced.first?.0 as? FakeReduxModernAction
        )
        let recordedActionWindowUUID = try XCTUnwrap(
            MockState.modernActionsReduced.first?.1
        )
        XCTAssertEqual(recordedAction, testAction)
        XCTAssertEqual(recordedActionWindowUUID, fakeWindowUUID)
    }

    func testDispatchMultipleActions() throws {
        let store = Store(
            state: mockState,
            reducer: MockState.reducer,
            middlewares: [])

        let testAction1 = FakeReduxModernAction.counterIncreased(counterValue: 13)
        let testAction2 = FakeReduxModernAction.counterDecreased(counterValue: 12)
        let testAction3 = FakeReduxModernAction.counterIncreased(counterValue: 11)

        store.dispatch(testAction1, forWindowUUID: fakeWindowUUID)
        store.dispatch(testAction2, forWindowUUID: fakeWindowUUID)
        store.dispatch(testAction3, forWindowUUID: fakeWindowUUID)

        guard MockState.modernActionsReduced.count == 3 else {
            XCTFail("Expected 3 actions fired")
            return
        }

        let recordedAction1 = try XCTUnwrap(
            MockState.modernActionsReduced[0].0 as? FakeReduxModernAction
        )
        let recordedAction1WindowUUID = try XCTUnwrap(
            MockState.modernActionsReduced[0].1
        )

        let recordedAction2 = try XCTUnwrap(
            MockState.modernActionsReduced[1].0 as? FakeReduxModernAction
        )
        let recordedAction2WindowUUID = try XCTUnwrap(
            MockState.modernActionsReduced[1].1
        )

        let recordedAction3 = try XCTUnwrap(
            MockState.modernActionsReduced[2].0 as? FakeReduxModernAction
        )
        let recordedAction3WindowUUID = try XCTUnwrap(
            MockState.modernActionsReduced[2].1
        )

        XCTAssertEqual(recordedAction1, testAction1)
        XCTAssertEqual(recordedAction2, testAction2)
        XCTAssertEqual(recordedAction3, testAction3)

        XCTAssertEqual(recordedAction1WindowUUID, fakeWindowUUID)
        XCTAssertEqual(recordedAction2WindowUUID, fakeWindowUUID)
        XCTAssertEqual(recordedAction3WindowUUID, fakeWindowUUID)
    }
}
