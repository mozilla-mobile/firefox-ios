// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

// TODO: FIXME: FXIOS-16140 will expand on these provider factory methods.

/// Because our current paradigm for middlewares is to strong retain `self` inside our providers, our middleware unit tests
/// will never successfully pass the `trackForMemoryLeaks` check. We can get around this by setting an empty provider on
/// the middleware before the end of each test. A better longterm solution would be to rewrite our providers to avoid strong
/// retain cycles, like by injecting a whole type into the `DefaultDispatchStore` rather than just provider closures.
/// - Returns: Returns an empty provider implementation which does not retain `self`.
public func emptyLegacyMiddlewareMethodFactory<T>() -> Middleware<T> {
    let emptyProvider: Middleware<T> = { _, _ in }

    return emptyProvider
}
