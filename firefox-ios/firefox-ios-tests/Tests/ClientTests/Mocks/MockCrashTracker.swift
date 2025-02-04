// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class MockCrashTracker: CrashTracker {
    var mockHasCrashed = false
    var updateDataCalled = 0
    var hasCrashedInLast3DaysCalled = 0

    var hasCrashedInLast3Days: Bool {
        hasCrashedInLast3DaysCalled += 1
        return mockHasCrashed
    }

    func updateData(currentDate: Date) {
        updateDataCalled += 1
    }
}
