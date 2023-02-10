// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class MockOverlayModeManager: DefaultOverlayModeManager {
    var leaveOverlayModeCallCount = 0
    var enterOverlayModeCallCount = 0

    override func leaveOverlayMode(didCancel cancel: Bool) {
        leaveOverlayModeCallCount += 1
        super.leaveOverlayMode(didCancel: cancel)
    }

    override func enterOverlayMode(_ locationText: String?, pasted: Bool, search: Bool) {
        enterOverlayModeCallCount += 1
        super.enterOverlayMode(locationText, pasted: pasted, search: search)
    }
}
