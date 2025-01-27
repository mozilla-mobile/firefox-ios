// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class SentryIDSetting: HiddenSetting {
    private weak var settingsDelegate: SharedSettingsDelegate?
    private let deviceAppHash = UserDefaults(
        suiteName: AppInfo.sharedContainerIdentifier
    )?.string(forKey: "SentryDeviceAppHash")

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: "Sentry ID \(deviceAppHash ?? "(null)")",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    init(settings: SettingsTableViewController,
         settingsDelegate: SharedSettingsDelegate) {
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        copyAppDeviceIDAndPresentAlert(by: navigationController)
    }

    private func copyAppDeviceIDAndPresentAlert(by navigationController: UINavigationController?) {
        UIPasteboard.general.string = deviceAppHash
        let alertTitle: String = .SettingsCopyAppVersionAlertTitle
        let alert = AlertController(title: alertTitle, message: nil, preferredStyle: .alert)

        settingsDelegate?.askedToShow(alert: alert)
    }
}
