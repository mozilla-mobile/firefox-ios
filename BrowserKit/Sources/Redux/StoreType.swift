// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol DispatchingStoreType {
    func dispatch(_ action: Action)
}

public protocol StoreType: DispatchingStoreType {
    associatedtype State

    var state: State { get }

    func subscribe<S: StoreSubscriber>(_ subscriber: S) where S.SubscriberStateType == State
    func unsubscribe<S: StoreSubscriber>(_ subscriber: S) where S.SubscriberStateType == State
}
