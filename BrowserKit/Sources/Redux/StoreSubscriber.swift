// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol AnyStoreSubscriber: AnyObject {
    func subscribeToRedux()
    func newState(state: Any)
}

/// Subscribers listen for state changes.
/// While all reducers will be called when a action gets dispatched, the subscriber will only be called
/// when an actual state change happens.
public protocol StoreSubscriber: AnyStoreSubscriber {
    associatedtype SubscriberStateType

    /// Updates the subscriber with a new State for its screen state type.
    /// - Parameter state: the changed screen state.
    func newState(state: SubscriberStateType)
}

extension StoreSubscriber {
    public func newState(state: Any) {
        if let typedState = state as? SubscriberStateType {
            newState(state: typedState)
        }
    }
}
