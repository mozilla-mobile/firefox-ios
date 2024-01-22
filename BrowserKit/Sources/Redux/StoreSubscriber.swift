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
/// when an actual state change happens. See also: notes below in `newState(state: Any)`
public protocol StoreSubscriber: AnyStoreSubscriber {
    associatedtype SubscriberStateType

    /// Updates the subscriber with a new State for its screen state type.
    /// - Parameter state: the changed screen state.
    func newState(state: SubscriberStateType)

    /// Provides a hook that Subscribers may use to pre-filter State updates.
    /// This is mandatory since it is critical in order to ensure state changes
    /// for identical Screen types are not incorrectly sent to different windows.
    /// Before sending `newState()`, the Subscriber will first be asked if it is
    /// interested in the given State. A Subscriber will typically check whether
    /// the incoming State has a matching WindowUUID.
    ///
    /// Allowing Redux to update the same screen across multiple windows is also
    /// facilitated by the inverse; Subscribers, if they wish to allow Actions
    /// on other windows to update their own state, may simply return true here
    /// and they will receive all screen state updates for their given type.
    /// - Parameter state: the state update that is incoming.
    /// - Returns: return true if the
    func validateState(state: SubscriberStateType) -> Bool
}

extension StoreSubscriber {
    public func newState(state: Any) {
        if let typedState = state as? SubscriberStateType {
            if validateState(state: typedState) {
                newState(state: typedState)
            }
        }
    }
}
