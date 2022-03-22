/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

extension ClosedRange {
    func clamp(_ value: Bound) -> Bound {
        return Swift.min(self.upperBound, Swift.max(self.lowerBound, value))
    }
}
