// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Provide pure functions, that based on the current `Action` and the current app `State`,
/// create a new app state. `Reducers` are the only place in which the application state should be modified.
/// Currently, our state reducers must implement a legacy reducer and a modern reducer as we migrate from consuming
/// legacy `Action`s to the new `ModernAction`s.
public typealias Reducer<State> = (legacyReducer: LegacyReducerMethod<State>, modernReducer: ReducerMethod<State>)

public typealias ReducerMethod<State> = @MainActor (State, ModernAction, WindowUUID) -> State
public typealias LegacyReducerMethod<State> = @MainActor (State, Action) -> State
