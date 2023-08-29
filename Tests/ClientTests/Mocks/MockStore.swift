// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

@testable import Client

public class MockStore<State: StateType>: DefaultDispatchStore {
    public var state: State {
        didSet {
            print("YRD newState \(state)")
        }
    }

    private var reducer: Reducer<State>
    private var middlewares: [Middleware<State>]

    public init(state: State,
                reducer: @escaping Reducer<State>,
                middlewares: [Middleware<State>] = []) {
        self.state = state
        self.reducer = reducer
        self.middlewares = middlewares
    }

    public func subscribe<S: StoreSubscriber>(_ subscriber: S) where S.SubscriberStateType == State {
    }

    public func subscribe<SubState, S: StoreSubscriber>(_ subscriber: S,
                                                        transform: ((Subscription<State>) -> Subscription<SubState>)?) where S.SubscriberStateType == SubState {
    }

    public func unsubscribe<S: StoreSubscriber>(_ subscriber: S) where S.SubscriberStateType == State {
    }

    public func unsubscribe(_ subscriber: any StoreSubscriber) {
    }

    public func dispatch(_ action: Action) {
        print("YRD dispatch \(action)")
    }
}
