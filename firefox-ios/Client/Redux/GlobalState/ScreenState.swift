// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Defines the state related to a screen used `AppState` reducer to 
/// retrieve the state for a specific screen. All ScreenStates should
/// have the capability of being associated with a specific window,
/// to ensure screens can be displayed across multiple windows on iPad.
protocol ScreenState {
    var windowUUID: WindowUUID { get }

    /// Returns a default state by clearing any transient state from previous one
    static func defaultState(fromPreviousState state: Self) -> Self
}

extension ScreenState {
    static func defaultState(fromPreviousState state: Self) -> Self {
        // Adding this default implementation so all states are not forced to implement it yet.
        return state
    }
}
