// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

final class VPNSetting: Setting {
    private weak var settingsDelegate: PrivacySettingsDelegate?
    private let profile: Profile?
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
        // TODO: - Figure out how we tell if the VPN is on, for now use the VPN settings toggle.
        let isEnabled = profile?.prefs.boolForKey(PrefsKeys.VPNSettings.isEnabled) ?? false
        let statusString: String
        if !isEnabled {
            statusString = .VPN.Settings.StatusOff
        } else if dataUsage.isLimitReached {
            statusString = .VPN.Settings.StatusPaused
        } else {
            statusString = .VPN.Settings.StatusOn
        }
        return NSAttributedString(string: statusString)
    }

    init(
        settings: SettingsTableViewController,
        settingsDelegate: PrivacySettingsDelegate?,
        dataUsage: VPNDataUsage = VPNDataUsage(usedDataInGB: 2.3, dataLimitInGB: 5)
    ) {
        self.settingsDelegate = settingsDelegate
        self.profile = settings.profile
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
