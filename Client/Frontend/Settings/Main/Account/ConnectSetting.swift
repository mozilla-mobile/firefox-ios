// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

// Sync setting for connecting a Firefox Account. Shown when we don't have an account.
class ConnectSetting: WithoutAccountSetting {
    private weak var settingsDelegate: AccountSettingsDelegate?

    override var accessoryView: UIImageView? {
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: .Settings.Sync.ButtonTitle,
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.ConnectSetting.title
    }

    init(settings: SettingsTableViewController,
         settingsDelegate: AccountSettingsDelegate?) {
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .signIntoSync)
        if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
            settingsDelegate?.pressedConnectSetting()
            return
        }

        let fxaParams = FxALaunchParams(entrypoint: .connectSetting, query: [:])
        let viewController = FirefoxAccountSignInViewController(profile: profile, parentType: .settings, deepLinkParams: fxaParams)
        navigationController?.pushViewController(viewController, animated: true)
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        cell.imageView?.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.logoFirefox)
        cell.imageView?.tintColor = theme.colors.textDisabled
        cell.imageView?.layer.cornerRadius = (cell.imageView?.frame.size.width)! / 2
        cell.imageView?.layer.masksToBounds = true
    }
}
