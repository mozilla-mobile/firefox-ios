// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@MainActor
final class SubscriptionWrapper<State>: @MainActor Hashable {
    private let originalSubscription: Subscription<State>
    weak var subscriber: AnyStoreSubscriber?
    private let objectIdentifier: ObjectIdentifier

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.objectIdentifier)
    }

    init<T>(originalSubscription: Subscription<State>,
            transformedSubscription: Subscription<T>?,
            subscriber: AnyStoreSubscriber) {
        self.originalSubscription = originalSubscription
        self.subscriber = subscriber
        self.objectIdentifier = ObjectIdentifier(subscriber)

        if let transformedSubscription = transformedSubscription {
            transformedSubscription.observer = { [unowned self] _, newState in
                self.subscriber?.newState(state: newState as Any)
            }
        } else {
            originalSubscription.observer = { [unowned self] _, newState in
                self.subscriber?.newState(state: newState as Any)
            }
        }
    }

    func newValues(oldState: State, newState: State) {
        originalSubscription.newValues(oldState: oldState, newState: newState)
    }

    static func == (left: SubscriptionWrapper<State>,
                    right: SubscriptionWrapper<State>) -> Bool {
        return left.objectIdentifier == right.objectIdentifier
    }
}

@MainActor
public final class Subscription<State> {
    public var observer: (@MainActor (State?, State) -> Void)?

    init() {}

    init(sink: @escaping (@MainActor @escaping (State?, State) -> Void) -> Void) {
        sink { old, new in
            self.newValues(oldState: old, newState: new)
        }
    }

    func newValues(oldState: State?, newState: State) {
        self.observer?(oldState, newState)
    }

    public func select<Substate>(_ selector: @escaping (State) -> Substate) -> Subscription<Substate> {
        return Subscription<Substate> { sink in
            self.observer = { oldState, newState in
                sink(oldState.map(selector) ?? nil, selector(newState))
            }
        }
    }

    /// Skips notifications when the new state is equal to the previous state.
    /// This prevents unnecessary view updates when state hasn't actually changed.
    /// - Parameter areEqual: A closure that returns true if two states should be considered equal
    /// - Returns: A new Subscription that only notifies when state actually changes
    public func skipRepeats(_ areEqual: @escaping (State, State) -> Bool) -> Subscription<State> {
        return Subscription<State> { sink in
            self.observer = { oldState, newState in
                // If we have an old state and it's equal to the new state, skip notification
                if let oldState = oldState, areEqual(oldState, newState) {
                    return
                }
                sink(oldState, newState)
            }
        }
    }
}

extension Subscription where State: Equatable {
    /// Convenience method that skips notifications when state is unchanged.
    /// Uses the Equatable conformance of the State type.
    /// - Returns: A new Subscription that only notifies when state actually changes
    public func skipRepeats() -> Subscription<State> {
        return skipRepeats(==)
    }
}
