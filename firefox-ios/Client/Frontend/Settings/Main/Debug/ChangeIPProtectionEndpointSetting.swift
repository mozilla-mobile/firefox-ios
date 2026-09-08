// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared
import IPProtectionKit

final class ChangeIPProtectionEndpointSetting: HiddenSetting {
    private let prefsKey = PrefsKeys.IPProtectionSettings.endpointEnvironment
    private let prefs: Prefs = { return (AppContainer.shared.resolve() as Profile).prefs }()

    override var title: NSAttributedString? {
        guard let theme else { return nil }

        return NSAttributedString(string: "IP Protection Endpoint",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let currentEnvRaw = prefs.stringForKey(prefsKey) ?? IPProtectionEnvironment.prod.rawValue
        let message = """
        Current: \(currentEnvRaw.capitalized)

        Note: App Attest key and cached session should automatically clear when switching environments.
        """
        let alert = UIAlertController(title: "IP Protection Endpoint",
                                      message: message,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Production", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.removeObjectForKey(self.prefsKey)
        }))
        alert.addAction(UIAlertAction(title: "Staging", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.setString(IPProtectionEnvironment.stage.rawValue, forKey: self.prefsKey)
        }))
        alert.addAction(UIAlertAction(title: "Dev", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.setString(IPProtectionEnvironment.dev.rawValue, forKey: self.prefsKey)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        settings.present(alert, animated: true)
    }
}
