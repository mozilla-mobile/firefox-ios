// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class MockSettingsFlowDelegate: SettingsFlowDelegate, GeneralSettingsDelegate {
    var showDevicePassCodeCalled = 0
    var showCreditCardSettingsCalled = 0
    var didFinishShowingSettingsCalled = 0
    var showExperimentsCalled = 0

    // MARK: SettingsFlowDelegate

    func showDevicePassCode() {
        showDevicePassCodeCalled += 1
    }

    func showCreditCardSettings() {
        showCreditCardSettingsCalled += 1
    }

    func didFinishShowingSettings() {
        didFinishShowingSettingsCalled += 1
    }

    func showExperiments() {
        showExperimentsCalled += 1
    }

    // MARK: GeneralSettingsDelegate

    func pressedHome() {}

    func pressedMailApp() {}

    func pressedNewTab() {}

    func pressedSearchEngine() {}

    func pressedSiri() {}

    func pressedToolbar() {}

    func pressedTabs() {}

    func pressedTheme() {}
}
