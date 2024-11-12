// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

@testable import Client

/// A mock Store used to test redux middlewares.
///
/// You should subclass and/or make your own mock store implementation if you need to highly customize it to meet the needs
/// of testing a particular middleware. (e.g. storing a completion handler for asynchronous middleware actions so you can
/// await expectations in your tests)
class MockStoreForMiddleware<State: StateType>: DefaultDispatchStore {
    var state: State

    /// Stores the number of times dispatch is called, and the actions with which it is called. Use to ensure that your
    /// middleware correctly dispatches the right actions in response to a given action.
    var dispatchCalled: (numberOfTimes: Int, withActions: [Redux.Action]) = (0, [])

    init(state: State) {
        self.state = state
    }

    func subscribe<S>(_ subscriber: S) where S: Redux.StoreSubscriber, State == S.SubscriberStateType {
        // TODO if you need it
    }

    func subscribe<SubState, S>(
        _ subscriber: S,
        transform: (
            (
                Redux.Subscription<State>
            ) -> Redux.Subscription<SubState>
        )?
    ) where SubState == S.SubscriberStateType, S: Redux.StoreSubscriber {
        // TODO if you need it
    }

    func unsubscribe<S>(_ subscriber: S) where S: Redux.StoreSubscriber, State == S.SubscriberStateType {
        // TODO if you need it
    }

    func unsubscribe(_ subscriber: any Redux.StoreSubscriber) {
        // TODO if you need it
    }

    func dispatch(_ action: Redux.Action) {
        var dispatchActions = dispatchCalled.withActions
        dispatchActions.append(action)

        dispatchCalled = (dispatchCalled.numberOfTimes + 1, dispatchActions)
    }
}
