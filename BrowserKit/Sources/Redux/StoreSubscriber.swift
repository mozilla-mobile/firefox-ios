// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Subscribers listen for state changes.
///  While all reducers will be called when a action gets dispatched, the subscriber will only be called when an actual state change happens.
public protocol StoreSubscriber {
    func newState(state: StateType)
}
