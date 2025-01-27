// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

/// Show the current version of Firefox
class VersionSetting: Setting {
    private weak var settingsDelegate: DebugSettingsDelegate?

    private var versionString = "\(AppName.shortName) \(AppInfo.appVersion) (\(AppInfo.buildNumber))"

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.Version.title
    }

    init(settingsDelegate: DebugSettingsDelegate) {
        self.settingsDelegate = settingsDelegate
        super.init(title: nil)
    }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(string: versionString,
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.pressedVersion()
    }

    override func onLongPress(_ navigationController: UINavigationController?) {
        UIPasteboard.general.string = versionString
        let alertTitle: String = .SettingsCopyAppVersionAlertTitle
        let alert = AlertController(title: alertTitle, message: nil, preferredStyle: .alert)
        settingsDelegate?.askedToShow(alert: alert)
    }
}
