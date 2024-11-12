// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

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
    private var actionRunning = false
    private let logger: Logger
    private var actionQueue: [Action] = []
    private var isProcessingActions = false

    public init(state: State,
                reducer: @escaping Reducer<State>,
                middlewares: [Middleware<State>] = [],
                logger: Logger = DefaultLogger.shared) {
        self.state = state
        self.reducer = reducer
        self.middlewares = middlewares
        self.logger = logger
    }

    /// General subscription to app main state
    public func subscribe<S: StoreSubscriber>(_ subscriber: S) where S.SubscriberStateType == State {
        subscribe(subscriber, transform: nil)
    }

    /// Adds support to subscribe to subState parts of the store's state
    public func subscribe<SubState, S: StoreSubscriber>(
        _ subscriber: S,
        transform: ((Subscription<State>) -> Subscription<SubState>)?
    ) where S.SubscriberStateType == SubState {
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
        logger.log("Dispatched action: \(action.displayString())", level: .info, category: .redux)

        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.dispatch(action) }
            return
        }

        actionQueue.append(action)
        processQueuedActions()
    }

    private func processQueuedActions() {
        guard !isProcessingActions else { return }
        isProcessingActions = true
        while !actionQueue.isEmpty {
            let action = actionQueue.removeFirst()
            executeAction(action)
        }
        isProcessingActions = false
    }

    private func executeAction(_ action: Action) {
        // Each active screen state is given an opportunity to be reduced using the dispatched action
        // (Note: this is true even if the action's UUID differs from the screen's window's UUID).
        // Typically, reducers should compare the action's UUID to the incoming state UUID and skip
        // processing for actions originating in other windows.
        // Note that only reducers for active screens are processed.
        let newState = reducer(state, action)

        // Middlewares are all given an opportunity to respond to the action. This is only done once
        // per middleware, regardless of how many active windows or screen states there are. (This
        // differs slightly from reducers, which are called once for each screen.)
        middlewares.forEach { middleware in
            middleware(newState, action)
        }

        state = newState
    }

    private func subscribe<SubState, S: StoreSubscriber>(
        _ subscriber: S,
        mainSubscription: Subscription<State>,
        transformedSubscription: Subscription<SubState>?
    ) {
        let subscriptionWrapper = SubscriptionWrapper(
            originalSubscription: mainSubscription,
            transformedSubscription: transformedSubscription,
            subscriber: subscriber
        )
        subscriptions.update(with: subscriptionWrapper)
        mainSubscription.newValues(oldState: nil, newState: state)
    }
}
