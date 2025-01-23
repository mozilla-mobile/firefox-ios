// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Redux

final class StoreTests: XCTestCase {
    var mockState = MockState()

    override func setUp() {
        super.setUp()
        mockState = MockState()
    }

    func testDispatchBasicAction_mainThread() {
        let store = Store(state: mockState,
                          reducer: MockState.reducer,
                          middlewares: [])

        let action = FakeReduxAction(
            windowUUID: UUID(),
            actionType: FakeReduxActionType.counterIncreased)

        store.dispatch(action)

        XCTAssertEqual(MockState.actionsReduced[0] as? FakeReduxActionType, FakeReduxActionType.counterIncreased)
    }

    func testDispatchMultipleActions_mainThread() {
        let store = Store(state: mockState,
                          reducer: MockState.reducer,
                          middlewares: [])

        let action1 = FakeReduxAction(
            windowUUID: UUID(),
            actionType: FakeReduxActionType.counterIncreased)
        store.dispatch(action1)

        let action2 = FakeReduxAction(
            windowUUID: UUID(),
            actionType: FakeReduxActionType.counterDecreased)
        store.dispatch(action2)

        let action3 = FakeReduxAction(
            windowUUID: UUID(),
            actionType: FakeReduxActionType.increaseCounter)
        store.dispatch(action3)

        XCTAssertEqual(MockState.actionsReduced[0] as? FakeReduxActionType, FakeReduxActionType.counterIncreased)
        XCTAssertEqual(MockState.actionsReduced[1] as? FakeReduxActionType, FakeReduxActionType.counterDecreased)
        XCTAssertEqual(MockState.actionsReduced[2] as? FakeReduxActionType, FakeReduxActionType.increaseCounter)
    }

    func testDispatchBasicAction_backgroundThread() async {
        let expectation = expectation(description: "Wait for actions to run")

        let store = Store(state: mockState,
                          reducer: MockState.reducer,
                          middlewares: [])

        let action = FakeReduxAction(
            windowUUID: UUID(),
            actionType: FakeReduxActionType.counterIncreased)

        Task.detached(priority: .background) {
            store.dispatch(action)
            await MainActor.run {
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation])

        XCTAssertEqual(MockState.actionsReduced[0] as? FakeReduxActionType, FakeReduxActionType.counterIncreased)
    }

    func testDispatchMultipleActions_mixThread() async {
        let expectation = expectation(description: "Wait for actions to run")

        let store = Store(state: mockState,
                          reducer: MockState.reducer,
                          middlewares: [])

        Task.detached(priority: .background) {
            let action1 = FakeReduxAction(
                windowUUID: UUID(),
                actionType: FakeReduxActionType.counterIncreased)
            store.dispatch(action1)
            await MainActor.run {
                expectation.fulfill()
            }
        }

        let action2 = FakeReduxAction(
            windowUUID: UUID(),
            actionType: FakeReduxActionType.counterDecreased)
        store.dispatch(action2)

        let action3 = FakeReduxAction(
            windowUUID: UUID(),
            actionType: FakeReduxActionType.increaseCounter)
        store.dispatch(action3)

        await fulfillment(of: [expectation])

        XCTAssertEqual(MockState.actionsReduced[0] as? FakeReduxActionType, FakeReduxActionType.counterDecreased)
        XCTAssertEqual(MockState.actionsReduced[1] as? FakeReduxActionType, FakeReduxActionType.increaseCounter)
        XCTAssertEqual(MockState.actionsReduced[2] as? FakeReduxActionType, FakeReduxActionType.counterIncreased)
    }

    func testDispatchAction_withMidReduceActions() {
        let store = Store(state: mockState,
                          reducer: MockState.reducer,
                          middlewares: [])

        MockState.runMidReducerActions = true
        MockState.midReducerActions = {
            MockState.runMidReducerActions = false

            let action2 = FakeReduxAction(
                windowUUID: UUID(),
                actionType: FakeReduxActionType.increaseCounter)
            store.dispatch(action2)

            let action3 = FakeReduxAction(
                windowUUID: UUID(),
                actionType: FakeReduxActionType.decreaseCounter)
            store.dispatch(action3)
        }
        let action = FakeReduxAction(
            windowUUID: UUID(),
            actionType: FakeReduxActionType.counterIncreased)

        store.dispatch(action)

        XCTAssertEqual(MockState.actionsReduced[0] as? FakeReduxActionType, FakeReduxActionType.counterIncreased)
        XCTAssertEqual(MockState.actionsReduced[1] as? FakeReduxActionType, FakeReduxActionType.increaseCounter)
        XCTAssertEqual(MockState.actionsReduced[2] as? FakeReduxActionType, FakeReduxActionType.decreaseCounter)
    }
}
