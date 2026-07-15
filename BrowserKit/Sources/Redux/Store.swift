// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Stores your entire app state in the form of a single data structure.
/// This state can only be modified by dispatching Actions to the store.
/// Whenever the state of the store changes, the store will notify all store subscriber.
@MainActor
public final class Store<State: StateType & Sendable>: DefaultDispatchStore {
    typealias SubscriptionType = SubscriptionWrapper<State>

    private let logger: Logger

    private var reducer: Reducer<State>
    private var middlewares: [Middleware<State>]
    private var subscriptions: Set<SubscriptionType> = []

    private var actionQueue: [(action: Either<Action, ModernAction>, windowUUID: WindowUUID)] = []
    private var isProcessingActions = false

    public var state: State {
        didSet {
            // Remove dead subscribers first to avoid modifying set during iteration
            let deadSubscriptions = subscriptions.filter { $0.subscriber == nil }
            subscriptions.subtract(deadSubscriptions)

            // Now safely iterate through live subscriptions
            subscriptions.forEach {
                $0.newValues(oldState: oldValue, newState: state)
            }
        }
    }

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

    /// Legacy method to dispatch actions to the global store. Eventually will be deprecated and replaced by
    /// `dispatch(_action:forWindowUUID)`, which takes a `ModernAction`.
    public func dispatch(_ action: Action) {
        MainActor.assertIsolated("Expected to be called only on main actor.")
        logger.log("Dispatched action: \(action.debugDescription)", level: .info, category: .redux)

        // We queue and process actions to ensure each single action completely passes through reducers and middlewares
        // before the next action fires.
        actionQueue.append((.legacy(action), action.windowUUID))
        processQueuedActions()
    }

    /// Method to dispatch actions to the global store.
    public func dispatch(_ action: ModernAction, forWindowUUID windowUUID: WindowUUID) {
        MainActor.assertIsolated("Expected to be called only on main actor.")
        logger.log("Dispatched action: \(action.description)", level: .info, category: .redux)

        // We queue and process actions to ensure each single action completely passes through reducers and middlewares
        // before the next action fires.
        actionQueue.append((.modern(action), windowUUID))
        processQueuedActions()
    }

    private func processQueuedActions() {
        guard !isProcessingActions else { return }
        isProcessingActions = true
        while !actionQueue.isEmpty {
            let tuple = actionQueue.removeFirst()
            executeAction(tuple.action, forWindowUUID: tuple.windowUUID)
        }
        isProcessingActions = false
    }

    private func executeAction(_ action: Either<Action, ModernAction>, forWindowUUID windowUUID: WindowUUID) {
        // Each active screen state is given an opportunity to be reduced using the dispatched action
        // (Note: this is true even if the action's UUID differs from the screen's window's UUID).
        // Typically, reducers should compare the action's UUID to the incoming state UUID and skip
        // processing for actions originating in other windows.
        // Note that only reducers for active screens are processed.
        let newState: State
        switch action {
        case .legacy(let legacyAction):
            newState = reducer(state, legacyAction)
        case .modern:
            // TODO: FXIOS-16140 Part 2 - Reducer migration
            // newState = reducer.modernReducer(state, modernAction, windowUUID)
            return
        }

        // Middlewares are all given an opportunity to respond to the action. This is only done once
        // per middleware, regardless of how many active windows or screen states there are. (This
        // differs slightly from reducers, which are called once for each screen.)
        middlewares.forEach { middleware in
            switch action {
            case .legacy(let legacyAction):
                middleware.legacyMiddleware(newState, legacyAction)
            case .modern(let modernAction):
                middleware.modernMiddleware(newState, modernAction, windowUUID)
            }
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
