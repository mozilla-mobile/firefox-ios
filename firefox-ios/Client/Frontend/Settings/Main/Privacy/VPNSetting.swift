// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

// TODO: FXIOS-16876 VPNSetting will get its view model from VPNManager instead of reading prefs and data usage itself
final class VPNSetting: Setting {
    private weak var settingsDelegate: PrivacySettingsDelegate?
    private let userPreferences: UserFeaturePreferring
    private let dataUsage: VPNDataUsage

    override var accessoryView: UIImageView? {
        guard let theme else { return nil }
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.VPN.title
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    override var status: NSAttributedString? {
        let isEnabled = userPreferences.getPreferenceFor(.vpnFeature)
        let statusString: String
        if dataUsage.isLimitReached {
            // TODO: Clear the paused status when the monthly data limit resets
            statusString = .VPN.Settings.StatusPaused
        } else {
            statusString = isEnabled ? .VPN.Settings.StatusOn : .VPN.Settings.StatusOff
        }
        return NSAttributedString(string: statusString)
    }

    init(
        settings: SettingsTableViewController,
        settingsDelegate: PrivacySettingsDelegate?,
        userPreferences: UserFeaturePreferring = AppContainer.shared.resolve(),
        dataUsage: VPNDataUsage = .placeholder
    ) {
        self.settingsDelegate = settingsDelegate
        self.userPreferences = userPreferences
        self.dataUsage = dataUsage
        let theme = settings.themeManager.getCurrentTheme(for: settings.windowUUID)
        super.init(
            title: NSAttributedString(
                string: .VPN.Settings.Title,
                attributes: [
                    NSAttributedString.Key.foregroundColor: theme.colors.textPrimary
                ]
            )
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.pressedVPN()
    }
}
