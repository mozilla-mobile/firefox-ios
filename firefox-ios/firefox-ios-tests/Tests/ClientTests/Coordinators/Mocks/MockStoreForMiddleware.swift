// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Foundation

/// A mock Store used to test redux middlewares.
///
/// If you need to highly customize this mock to meet your testing needs, you should subclass it and/or make your own mock
/// store implementation (e.g. storing a completion handler for asynchronous middleware actions so you can await expectations
///  in your tests).
class MockStoreForMiddleware<State: StateType>: DefaultDispatchStore {
    private let lock = NSLock()

    var state: State

    /// Records all actions dispatched to the mock store. Check this property to ensure that your middleware correctly
    /// dispatches the right action(s), and the right count of actions, in response to a given action.
    var dispatchedActions: [Redux.Action] = []

    /// Called every time an action is dispatched to the mock store. Used to confirm that a dispatched action completed. This
    /// is useful when the middleware is making an asynchronous call and we want to wait for an expectation to be fulfilled.
    var dispatchCalled: (() -> Void)?

    /// Called when subscriber calls subscribe to the mock store.
    var subscribeCallCount = 0

    init(state: State) {
        self.state = state
    }

    func subscribe<S>(_ subscriber: S) where S: Redux.StoreSubscriber, State == S.SubscriberStateType {
        subscribeCallCount += 1
    }

    func subscribe<SubState, S>(
        _ subscriber: S,
        transform: (
            (
                Redux.Subscription<State>
            ) -> Redux.Subscription<SubState>
        )?
    ) where SubState == S.SubscriberStateType, S: Redux.StoreSubscriber {
        subscribeCallCount += 1
    }

    func unsubscribe<S>(_ subscriber: S) where S: Redux.StoreSubscriber, State == S.SubscriberStateType {
        // TODO: if you need it
    }

    func unsubscribe(_ subscriber: any Redux.StoreSubscriber) {
        // TODO: if you need it
    }

    /// We implemented the lock to ensure that this is thread safe
    /// since actions can be dispatch in concurrent tasks
    func dispatch(_ action: Redux.Action) {
        lock.lock()
        defer { lock.unlock() }
        dispatchedActions.append(action)
        dispatchCalled?()
    }
}
