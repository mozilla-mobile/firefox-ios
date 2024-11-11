// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class MockSettingsFlowDelegate: SettingsFlowDelegate,
                                GeneralSettingsDelegate,
                                PrivacySettingsDelegate,
                                AccountSettingsDelegate,
                                AboutSettingsDelegate,
                                SupportSettingsDelegate {
    var showDevicePassCodeCalled = 0
    var showCreditCardSettingsCalled = 0
    var didFinishShowingSettingsCalled = 0
    var showExperimentsCalled = 0
    var showPasswordManagerCalled = 0
    var savedShouldShowOnboarding = false
    var showQRCodeCalled = 0

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

    func showFirefoxSuggest() {}

    func openDebugTestTabs(count: Int) {}

    func showDebugFeatureFlags() { }

    func showPasswordManager(shouldShowOnboarding: Bool) {
        savedShouldShowOnboarding = shouldShowOnboarding
        showPasswordManagerCalled += 1
    }

    func showQRCode(delegate: QRCodeViewControllerDelegate) {
        showQRCodeCalled += 1
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

    func pressedAddressAutofill() {}

    func askedToOpen(url: URL?, withTitle title: NSAttributedString?) {}

    // MARK: AccountSettingsDelegate

    func pressedConnectSetting() {}

    func pressedAdvancedAccountSetting() {}

    func pressedToShowSyncContent() {}

    func pressedToShowFirefoxAccount() {}

    // MARK: AboutSettingsDelegate

    func pressedRateApp() {}

    func pressedLicense(url: URL, title: NSAttributedString) {}

    func pressedYourRights(url: URL, title: NSAttributedString) {}

    // MARK: SupportSettingsDelegate

    func pressedOpenSupportPage(url: URL) {}
}
