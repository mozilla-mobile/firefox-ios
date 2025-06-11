// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// A mock used to test logic that use the current date.
class MockDateProvider: DateProvider {
    private let fixedDate: Date
    init(fixedDate: Date) {
        self.fixedDate = fixedDate
    }
    func now() -> Date {
        return fixedDate
    }
}
