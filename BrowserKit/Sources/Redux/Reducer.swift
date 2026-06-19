// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Redux state reducers are pure functions. Based on the current state and an `Action`, they return a new state. Reducers
/// are the only place in which the redux app state should be modified.
///
/// Currently our state reducers must implement a legacy reducer and a modern reducer as we migrate from consuming `Action`s
/// to consuming `ModernAction`s.
public typealias Reducer<State> = (legacyReducer: LegacyReducerMethod<State>, modernReducer: ReducerMethod<State>)

public typealias ReducerMethod<State> = @MainActor (State, ModernAction, WindowUUID) -> State
public typealias LegacyReducerMethod<State> = @MainActor (State, Action) -> State
