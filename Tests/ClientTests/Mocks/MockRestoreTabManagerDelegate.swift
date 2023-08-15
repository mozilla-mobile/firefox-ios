// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

final class MockRestoreTabManagerDelegate: RestoreTabManagerDelegate {
    var needsTabRestoreCalled = 0
    var needsNewTabOpenedCalled = 0

    func needsTabRestore() {
        needsTabRestoreCalled += 1
    }

    func needsNewTabOpened() {
        needsNewTabOpenedCalled += 1
    }
}
