// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Provide pure functions, that based on the current `Action` and the current app `State`,
/// create a new app state. `Reducers` are the only place in which the application state should be modified.
public typealias Reducer<State> = (State, Action) -> State
