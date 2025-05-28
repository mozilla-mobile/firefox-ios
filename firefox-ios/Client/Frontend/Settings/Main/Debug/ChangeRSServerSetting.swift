// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

class ChangeRSServerSetting: HiddenSetting {
    private let prefsKey = PrefsKeys.RemoteSettings.useQAStagingServerForRemoteSettings
    private let prefs: Prefs = { return (AppContainer.shared.resolve() as Profile).prefs }()

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        // Not localized for now.
        return NSAttributedString(string: "Remote Settings Server",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let useStaging = (prefs.boolForKey(prefsKey) == true)
        let message = "Current: \(useStaging ? "Staging" : "Production")\n\nChanges take effect on the next app launch."
        let alert = UIAlertController(title: "Remote Settings Server",
                                      message: message,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Production", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.removeObjectForKey(self.prefsKey)
        }))
        alert.addAction(UIAlertAction(title: "Staging", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.setBool(true, forKey: self.prefsKey)
        }))
        settings.present(alert, animated: true)
    }
}
