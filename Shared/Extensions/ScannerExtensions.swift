/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension Scanner {
    public func scanUnsignedLongLong() -> UInt64? {
        var value: UInt64 = 0
        if scanUnsignedLongLong(&value) {
            return value
        }
        return nil
    }

    public func scanLongLong() -> Int64? {
        var value: Int64 = 0
        if scanInt64(&value) {
            return value
        }
        return nil
    }

    public func scanDouble() -> Double? {
        var value: Double = 0
        if scanDouble(&value) {
            return value
        }
        return nil
    }
}
