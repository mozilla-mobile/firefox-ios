// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

/// Debug-menu setting that overrides the merino WCS base host (e.g. point at
/// a local server). This is for dev/beta only and is exposed via `HiddenSetting`.
final class WorldCupBaseHostOverrideSetting: HiddenSetting {
    private let prefsKey = PrefsKeys.HomepageSettings.WorldCupBaseHost
    private let prefs: Prefs = {
        return (AppContainer.shared.resolve() as Profile).prefs
    }()

    private var override: String? { prefs.stringForKey(prefsKey) }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: "World Cup: Override merino host",
            attributes: [.foregroundColor: theme.colors.textPrimary]
        )
    }

    override var status: NSAttributedString? {
        guard let theme else { return nil }
        let label = override?.isEmpty == false
            ? "Set to \(override ?? "")"
            : "Using default merino host"
        return NSAttributedString(
            string: label,
            attributes: [.foregroundColor: theme.colors.textSecondary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let alert = UIAlertController(
            title: "Override merino host",
            message: "Enter a host (e.g. `https://127.0.0.1:8000/` or `https://my.dev`). Leave empty to use the default.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.text = self.override
            textField.placeholder = "https://merino.services.mozilla.com/"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.keyboardType = .URL
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
            } else {
                self.prefs.setString(value, forKey: self.prefsKey)
            }
        })
        settings.present(alert, animated: true)
    }
}
