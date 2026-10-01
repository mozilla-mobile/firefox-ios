// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Redux middleware providers consume `Action`s and are designed to perform logic with side effects (e.g. API calls,
/// logging, or accessing storage).
/// Currently, our middleware providers must implement a legacy provider and a modern provider as we migrate from consuming
/// legacy `Action`s to the new `ModernAction`s.
public typealias Middleware<State> = (
    legacyMiddleware: LegacyMiddlewareClosure<State>,
    modernMiddleware: MiddlewareClosure<State>
)

public typealias MiddlewareClosure<State> = @MainActor (State, ModernAction, WindowUUID) -> Void
public typealias LegacyMiddlewareClosure<State> = @MainActor (State, Action) -> Void
