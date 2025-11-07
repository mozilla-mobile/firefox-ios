// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class ResetSearchEnginePrefsSetting: HiddenSetting {
    override var title: NSAttributedString? {
        guard let theme else { return nil }
        // Not localized for now.
        return NSAttributedString(string: "Reset Search Engine Prefs",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        // Reset all search engine prefs
        let searchEngineManager: SearchEnginesManager = AppContainer.shared.resolve()
        searchEngineManager.resetPrefs()

        // Provide courtesy message
        let alert = UIAlertController(title: "Search Preferences Reset",
                                      message: "Please quit & relaunch Firefox for changes to take effect.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        settings.present(alert, animated: true)
    }
}
