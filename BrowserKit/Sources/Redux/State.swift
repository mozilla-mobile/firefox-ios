// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Defines the entire application state including the UI state and any model state that you used in the app.
/// This state is stored inside of the `Store`, then you have views and other subscribers that will get notified
/// every single time that state updates into the entire app.
public protocol StateType {
    /// Returns a default State by clearing any transient data from previous one.
    ///
    /// All the state properties that have a default value into the initializer should be restore to default.
    static func defaultState(from state: Self) -> Self
}
