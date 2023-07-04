// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class MockSettingsFlowDelegate: SettingsFlowDelegate, GeneralSettingsDelegate, PrivacySettingsDelegate,
                                AccountSettingsDelegate, SupportSettingsDelegate {
    var showDevicePassCodeCalled = 0
    var showCreditCardSettingsCalled = 0
    var didFinishShowingSettingsCalled = 0
    var showExperimentsCalled = 0
    var showPasswordManagerCalled = 0

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

    func showPasswordManager(shouldShowOnboarding: Bool) {
        showPasswordManagerCalled += 1
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

    // MARK: PrivacySettingsDelegate

    func pressedCreditCard() {}

    func pressedClearPrivateData() {}

    func pressedContentBlocker() {}

    func pressedPasswords() {}

    func pressedNotifications() {}

    func askedToOpen(url: URL?, withTitle title: NSAttributedString?) {}

    // MARK: AccountSettingsDelegate

    func pressedConnectSetting() {}

    func pressedAdvancedAccountSetting() {}

    func pressedToShowSyncContent() {}

    func pressedToShowFirefoxAccount() {}

    // MARK: SupportSettingsDelegate

    func pressedOpenSupportPage(url: URL) {}
}
