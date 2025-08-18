// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

class ChangeRSServerSetting: HiddenSetting {
    private let prefsKey = PrefsKeys.RemoteSettings.remoteSettingsEnvironment
    private let prefs: Prefs = { return (AppContainer.shared.resolve() as Profile).prefs }()

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        // Not localized for now.
        return NSAttributedString(string: "Remote Settings Server",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let currentEnvRaw = prefs.stringForKey(prefsKey) ?? RemoteSettingsEnvironment.prod.rawValue
        let message = """
        Current: \(currentEnvRaw.capitalized)

        Changes take effect on the next app launch.

        To switch to Staging and reset ordering prefs for Consolidated Search, choose the SEC Reset option.
        """
        let alert = UIAlertController(title: "Remote Settings Server",
                                      message: message,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Production", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.removeObjectForKey(self.prefsKey)
        }))
        alert.addAction(UIAlertAction(title: "Staging", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.setString(RemoteSettingsEnvironment.stage.rawValue, forKey: self.prefsKey)
        }))
        alert.addAction(UIAlertAction(title: "Staging + SEC Reset", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.setString(RemoteSettingsEnvironment.stage.rawValue, forKey: self.prefsKey)
            let searchManager: SearchEnginesManager = AppContainer.shared.resolve()
            searchManager.resetPrefs()
        }))
        alert.addAction(UIAlertAction(title: "Dev", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.setString(RemoteSettingsEnvironment.dev.rawValue, forKey: self.prefsKey)
        }))
        settings.present(alert, animated: true)
    }
}
