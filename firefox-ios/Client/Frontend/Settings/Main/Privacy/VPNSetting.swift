// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

@available(iOS 17.0, *)
final class VPNSetting: Setting {
    private weak var settingsDelegate: PrivacySettingsDelegate?
    private let vpnManager: VPNManager

    override var accessoryView: UIImageView? {
        guard let theme else { return nil }
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.VPN.title
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    override var status: NSAttributedString? {
        let statusString: String
        if vpnManager.isLimitReached {
            // TODO: Clear the paused status when the monthly data limit resets
            statusString = .VPN.Settings.StatusPaused
        } else {
            statusString = vpnManager.isRunning ? .VPN.Settings.StatusOn : .VPN.Settings.StatusOff
        }
        return NSAttributedString(string: statusString)
    }

    init(
        settings: SettingsTableViewController,
        settingsDelegate: PrivacySettingsDelegate?,
        vpnManager: VPNManager = AppContainer.shared.resolve()
    ) {
        self.settingsDelegate = settingsDelegate
        self.vpnManager = vpnManager
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
