// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A protocol that provides the current date for now.
/// FXIOS-9675 Want to extend and pull in logic from Time Constants.
///
/// Useful for injecting a customizable date source, particularly in unit tests.
/// Instead of using `Date()` directly, we should pass in this provider and call `now()`.
public protocol DateProvider {
    func now() -> Date
}

public struct SystemDateProvider: DateProvider {
    public init() { }
    public func now() -> Date {
        return Date()
    }
}
