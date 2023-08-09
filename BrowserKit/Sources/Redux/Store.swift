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
    private var subscriptions: Set<SubscriptionType> = []

    public init(state: State,
                reducer: @escaping Reducer<State>,
                middlewares: [Middleware<State>] = []) {
        self.state = state
        self.reducer = reducer
        self.middlewares = middlewares
    }

    /// General subscription to app main state
    public func subscribe<S: StoreSubscriber>(_ subscriber: S) where S.SubscriberStateType == State {
        subscribe(subscriber, transform: nil)
    }

    /// Adds support to subscribe to subState parts of the store's state
    public func subscribe<SubState, S: StoreSubscriber>(_ subscriber: S,
                                                        transform: ((Subscription<State>) -> Subscription<SubState>)?) where S.SubscriberStateType == SubState {
        let originalSubscription = Subscription<State>()
        let transformedSubscription = transform?(originalSubscription)
        subscribe(subscriber, mainSubscription: originalSubscription, transformedSubscription: transformedSubscription)
    }

    public func unsubscribe(_ subscriber: any StoreSubscriber) {
        if let index = subscriptions.firstIndex(where: { return $0.subscriber === subscriber }) {
            subscriptions.remove(at: index)
        }
    }

    public func unsubscribe<S: StoreSubscriber>(_ subscriber: S) where S.SubscriberStateType == State {
        if let index = subscriptions.firstIndex(where: { return $0.subscriber === subscriber }) {
            subscriptions.remove(at: index)
        }
    }

    public func dispatch(_ action: Action) {
        let newState = reducer(state, action)

        middlewares.forEach { middleware in
            middleware(newState, action)
        }

        state = newState
    }

    private func subscribe<SubState, S: StoreSubscriber>(_ subscriber: S,
                                                         mainSubscription: Subscription<State>,
                                                         transformedSubscription: Subscription<SubState>?) {
        let subscriptionWrapper = SubscriptionWrapper(originalSubscription: mainSubscription,
                                                      transformedSubscription: transformedSubscription,
                                                      subscriber: subscriber)
        subscriptions.update(with: subscriptionWrapper)
        mainSubscription.newValues(oldState: nil, newState: state)
    }
}
