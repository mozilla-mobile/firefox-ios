// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Common
import Foundation
import Shared
import ComponentLibrary

class ChinaSyncServiceSetting: Setting {
    private weak var settingsDelegate: SharedSettingsDelegate?
    private var prefs: Prefs { return profile.prefs }
    private let prefKey = PrefsKeys.KeyEnableChinaSyncService
    private let profile: Profile

    override var accessoryType: UITableViewCell.AccessoryType { return .none }

    override var hidden: Bool { return !AppInfo.isChinaEdition }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(string: "本地同步服务",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override var status: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(string: "禁用后使用全球服务同步数据",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary])
    }

    init(profile: Profile, settingsDelegate: SharedSettingsDelegate?) {
        self.profile = profile
        self.settingsDelegate = settingsDelegate
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        let control = ThemedSwitch()
        control.applyTheme(theme: theme)
        control.onTintColor = theme.colors.actionPrimary
        control.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        control.isOn = prefs.boolForKey(prefKey) ?? AppInfo.isChinaEdition
        cell.accessoryView = control
        cell.selectionStyle = .none
    }

    @objc
    func switchValueChanged(_ toggle: UISwitch) {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .chinaServerSwitch)
        guard profile.rustFxA.hasAccount() else {
            prefs.setObject(toggle.isOn, forKey: prefKey)
            RustFirefoxAccounts.reconfig(prefs: profile.prefs) { _ in }
            return
        }

        // Show confirmation dialog for the user to sign out of FxA

        let msg = "更改此设置后，再次登录您的帐户" // "Sign-in again to your account after changing this setting"
        let alert = AlertController(title: "", message: msg, preferredStyle: .alert)
        let okString = UIAlertAction(title: .OKString, style: .default) { _ in
            self.prefs.setObject(toggle.isOn, forKey: self.prefKey)
            self.profile.removeAccount()
            RustFirefoxAccounts.reconfig(prefs: self.profile.prefs) { _ in }
        }
        let cancel = UIAlertAction(title: .CancelString, style: .default) { _ in
            toggle.setOn(!toggle.isOn, animated: true)
        }
        alert.addAction(okString)
        alert.addAction(cancel)

        settingsDelegate?.askedToShow(alert: alert)
    }
}
