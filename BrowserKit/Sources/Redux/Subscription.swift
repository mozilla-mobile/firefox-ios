// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class SubscriptionWrapper<State>: Hashable {
    private let subscription: Subscription<State>
    weak var subscriber: AnyStoreSubscriber?
    private let objectIdentifier: ObjectIdentifier

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.objectIdentifier)
    }

    init(subscription: Subscription<State>,
         subscriber: AnyStoreSubscriber) {
        self.subscription = subscription
        self.subscriber = subscriber
        self.objectIdentifier = ObjectIdentifier(subscriber)

        subscription.observer = { [unowned self] _, newState in
            self.subscriber?.newState(state: newState as Any)
        }
    }

    func newValues(oldState: State, newState: State) {
        self.subscription.newValues(oldState: oldState, newState: newState)
    }

    static func == (left: SubscriptionWrapper<State>,
                    right: SubscriptionWrapper<State>) -> Bool {
        return left.objectIdentifier == right.objectIdentifier
    }
}

public class Subscription<State> {
    public var observer: ((State?, State) -> Void)?

    init() {}

    public init(sink: @escaping (@escaping (State?, State) -> Void) -> Void) {
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
}
