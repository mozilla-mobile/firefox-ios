// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Redux `Middleware` provides a third-party extension point between dispatching an `Action`,
/// and the moment it reaches the `Reducer` Middleware produces side effects or uses dependencies and
/// is the best place to put logger, API calls or access storage.
public typealias DispatchFunction = (Action) -> Void
public typealias Middleware<State> = (State, Action) -> Void
