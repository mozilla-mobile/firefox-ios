// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

/// Debug-menu setting that overrides the World Cup `/matches` and `/live` poll
/// cadence. Stored as seconds (`Int`). When set, both streams fire on this
/// interval regardless of result type — used to test live behavior against the
/// dev mock without waiting for the production 3- / 15-min cadence. Sibling of
/// `WorldCupBaseHostOverrideSetting`; effective on app restart.
final class WorldCupPollIntervalOverrideSetting: HiddenSetting {
    private let prefsKey = PrefsKeys.HomepageSettings.WorldCupPollInterval
    private let prefs: Prefs = {
        return (AppContainer.shared.resolve() as Profile).prefs
    }()

    private var override: Int32? { prefs.intForKey(prefsKey) }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: "World Cup: Override poll interval (seconds)",
            attributes: [.foregroundColor: theme.colors.textPrimary]
        )
    }

    override var status: NSAttributedString? {
        guard let theme else { return nil }
        let label: String
        if let override, override > 0 {
            label = "Polling every \(override)s (app restart required)"
        } else {
            label = "Using production cadence (15 min matches, 3 min live)"
        }
        return NSAttributedString(
            string: label,
            attributes: [.foregroundColor: theme.colors.textSecondary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let alert = UIAlertController(
            title: "Override poll interval",
            message: "Enter seconds (e.g. `10`). Both /matches and /live will fire on this cadence. Leave empty to restore production defaults. App restart required.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.text = self.override.map { "\($0)" }
            textField.placeholder = "10"
            textField.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.prefs.removeObjectForKey(self.prefsKey)
        })
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self else { return }
            let value = alert.textFields?.first?.text?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if value.isEmpty {
                self.prefs.removeObjectForKey(self.prefsKey)
                return
            }
            guard let seconds = Int32(value), seconds > 0 else {
                self.prefs.removeObjectForKey(self.prefsKey)
                return
            }
            self.prefs.setInt(seconds, forKey: self.prefsKey)
        })
        settings.present(alert, animated: true)
    }
}
