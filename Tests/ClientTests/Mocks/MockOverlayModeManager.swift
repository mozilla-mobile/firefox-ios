// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class MockOverlayModeManager: OverlayModeManager {
    var inOverlayMode = false
    var leaveOverlayModeCallCount = 0
    var enterOverlayModeCallCount = 0

    func leaveOverlayMode(didCancel cancel: Bool) {
        leaveOverlayModeCallCount += 1
        inOverlayMode = false
    }

    func enterOverlayMode(_ locationText: String?, pasted: Bool, search: Bool) {
        enterOverlayModeCallCount += 1
        inOverlayMode = true
    }
}
