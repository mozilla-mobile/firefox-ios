// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
@testable import Client

class MockGeneralSettingsDelegate: GeneralSettingsDelegate {
    var pressedAIControlsCalled = false

    func pressedCustomizeAppIcon() {}

    func pressedHome() {}

    func pressedNewTab() {}

    func pressedSearchEngine() {}

    func pressedSiri() {}

    func pressedAIControls() {
        pressedAIControlsCalled = true
    }

    func pressedToolbar() {}

    func pressedTheme() {}

    func pressedBrowsing() {}

    func pressedSummarize() {}

    func pressedTranslation() {}

    func pressedAutoFillsPasswords() {}
}
