// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Defines the entire application state including the UI state and any model state that you used in the app.
/// This state is stored inside of the `Store`, then you have views and other subscribers that will get notified
/// every single time that state updates into the entire app.
public protocol StateType: Sendable, Equatable {
    /// Returns a default State by clearing any transient data from previous one.
    ///
    /// All the state properties that have a default value into the initializer should be restore to default.
    static func defaultState(from state: Self) -> Self

    /// Resets transient fields via `defaultState(from:)`, preserving everything else. Call first in a
    /// `.copy()` chain, before field-specific overrides. If a field's reset behavior is handler-dependent
    /// (e.g. `toast` in `BrowserViewControllerState`), add `.copy(field: state.field)` after this call
    /// wherever it should be preserved.
    func resetTransientState() -> Self
}

extension StateType {
    /// Gives every conforming state `resetTransientState()` for free, rather than a hand-written implementation per type.
    /// This makes `defaultState(from:)` the single source of truth for reseting the transient state.
    /// As such, `defaultState(from:)` must accurately describe what those transient fields are.
    public func resetTransientState() -> Self {
        return Self.defaultState(from: self)
    }
}
