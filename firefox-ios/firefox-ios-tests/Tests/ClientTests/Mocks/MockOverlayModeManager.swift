// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class MockOverlayModeManager: DefaultOverlayModeManager {
    var leaveOverlayModeCallCount = 0
    var enterOverlayModeCallCount = 0
    var cancelEditingCallCount = 0
    var stubbedInOverlayMode: Bool?

    override var inOverlayMode: Bool {
        return stubbedInOverlayMode ?? super.inOverlayMode
    }

    override func openSearch(with pasteContent: String) {
        enterOverlayModeCallCount += 1
        super.openSearch(with: pasteContent)
    }

    override func openNewTab(url: URL?, newTabSettings: NewTabPage) {
        enterOverlayModeCallCount += 1
        super.openNewTab(url: url, newTabSettings: newTabSettings)
    }

    override func finishEditing(shouldCancelLoading: Bool) {
        leaveOverlayModeCallCount += 1
        super.finishEditing(shouldCancelLoading: shouldCancelLoading)
    }

    override func cancelEditing(shouldCancelLoading: Bool) {
        cancelEditingCallCount += 1
        super.cancelEditing(shouldCancelLoading: shouldCancelLoading)
    }

    override func switchTab(shouldCancelLoading: Bool) {
        leaveOverlayModeCallCount += 1
        super.switchTab(shouldCancelLoading: shouldCancelLoading)
    }
}
