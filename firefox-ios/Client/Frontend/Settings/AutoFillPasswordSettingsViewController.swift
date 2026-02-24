// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Glean

class AutoFillPasswordSettingsViewController: SettingsTableViewController, FeatureFlaggable {
    weak var parentCoordinator: PrivacySettingsDelegate?
    private let relayController: RelayControllerProtocol

    init(profile: Profile,
         relayController: RelayControllerProtocol,
         windowUUID: WindowUUID) {
        self.relayController = relayController
        super.init(style: .grouped, windowUUID: windowUUID)
        self.profile = profile
        self.title = .Settings.AutofillAndPassword.Title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        var sectionItems = [Setting]()

        sectionItems.append(PasswordManagerSetting(settings: self, settingsDelegate: parentCoordinator))
        sectionItems.append(AutofillCreditCardSettings(settings: self, settingsDelegate: parentCoordinator))

        let autofillAddressStatus = AddressLocaleFeatureValidator.isValidRegion(for: SystemLocaleProvider().regionCode())
        if autofillAddressStatus, let profile {
            sectionItems.append(AddressAutofillSetting(theme: themeManager.getCurrentTheme(for: windowUUID),
                                                       profile: profile,
                                                       settingsDelegate: parentCoordinator))
        }

        if relayController.shouldDisplayRelaySettings() {
            sectionItems.append(AutofillRelayMaskSetting(settings: self, settingsDelegate: parentCoordinator))
        }

        return [SettingSection(children: sectionItems)]
    }
}
