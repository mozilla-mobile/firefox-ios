// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Stores your entire app state in the form of a single data structure.
/// This state can only be modified by dispatching Actions to the store.
/// Whenever the state of the store changes, the store will notify all store subscriber.
public class Store<State: StateType>: DefaultDispatchStore {
    typealias SubscriptionType = SubscriptionWrapper<State>

    public var state: State {
        didSet {
            subscriptions.forEach {
                guard $0.subscriber != nil else {
                    subscriptions.remove($0)
                    return
                }

                $0.newValues(oldState: oldValue, newState: state)
            }
        }
    }

    private var reducer: Reducer<State>
    private var middlewares: [Middleware<State>]

    var subscriptions: Set<SubscriptionType> = []

    public init(state: State,
                reducer: @escaping Reducer<State>,
                middlewares: [Middleware<State>] = []) {
        self.state = state
        self.reducer = reducer
        self.middlewares = middlewares
    }

    func buildSubscriptionWrapper(subscription: Subscription<State>,
                                  subscriber: AnyStoreSubscriber) -> SubscriptionWrapper<State> {
        return SubscriptionWrapper(subscription: subscription,
                                   subscriber: subscriber)
    }

    public func subscribe<S: StoreSubscriber>(_ subscriber: S) where S.SubscriberStateType == State {
        let subscription = Subscription<State>()
        subscribe(subscriber, subscription: subscription)
    }

    public func unsubscribe<S: StoreSubscriber>(_ subscriber: S) where S.SubscriberStateType == State {
        if let index = subscriptions.firstIndex(where: { return $0.subscriber === subscriber }) {
            subscriptions.remove(at: index)
        }
    }

    public func dispatch(_ action: Action) {
        dispatch(state, action)
    }

    private func dispatch(_ currentState: State,
                          _ action: Action) {
        let newState = reducer(currentState, action)
        state = newState
    }

    private func subscribe<S: StoreSubscriber>(
        _ subscriber: S, subscription: Subscription<State>) {
        let subscriptionWrapper = buildSubscriptionWrapper(subscription: subscription, subscriber: subscriber)

        subscriptions.update(with: subscriptionWrapper)
        subscription.newValues(oldState: nil, newState: state)
    }
}
