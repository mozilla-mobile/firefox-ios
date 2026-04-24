// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared
import MLPAKit

final class ChangeMLPAEndpointSetting: HiddenSetting {
    private let prefsKey = PrefsKeys.MLPASettings.mlpaEndpointEnvironment
    private let prefs: Prefs = { return (AppContainer.shared.resolve() as Profile).prefs }()

    override var title: NSAttributedString? {
        guard let theme else { return nil }

        return NSAttributedString(string: "MLPA Endpoint",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let currentEnvRaw = prefs.stringForKey(prefsKey) ?? MLPAEnvironment.prod.rawValue
        let message = """
        Current: \(currentEnvRaw.capitalized)
        """
        let alert = UIAlertController(title: "MLPA Endpoint",
                                      message: message,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Production", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.removeObjectForKey(self.prefsKey)
        }))
        alert.addAction(UIAlertAction(title: "Staging", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.setString(MLPAEnvironment.stage.rawValue, forKey: self.prefsKey)
        }))
        alert.addAction(UIAlertAction(title: "Dev", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.setString(MLPAEnvironment.dev.rawValue, forKey: self.prefsKey)
        }))
        settings.present(alert, animated: true)
    }
}
