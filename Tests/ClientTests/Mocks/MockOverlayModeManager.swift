// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class MockOverlayModeManager: DefaultOverlayModeManager {
    var leaveOverlayModeCallCount = 0
    var enterOverlayModeCallCount = 0

    override func openSearch(with pasteContent: String) {
        enterOverlayModeCallCount += 1
        super.openSearch(with: pasteContent)
    }

    override func openNewTab(_ locationText: String?, url: URL?) {
        enterOverlayModeCallCount += 1
        super.openNewTab(locationText, url: url)
    }

    override func finishEdition(shouldCancelLoading: Bool) {
        leaveOverlayModeCallCount += 1
        super.finishEdition(shouldCancelLoading: shouldCancelLoading)
    }

    override func switchTab(shouldCancelLoading: Bool) {
        leaveOverlayModeCallCount += 1
        super.switchTab(shouldCancelLoading: shouldCancelLoading)
    }
}
