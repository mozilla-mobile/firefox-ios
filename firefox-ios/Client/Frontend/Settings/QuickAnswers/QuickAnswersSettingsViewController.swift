// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

final class QuickAnswersSettingsViewController: SettingsTableViewController {
    let prefs: Prefs
    init(prefs: Prefs, windowUUID: WindowUUID) {
        self.prefs = prefs
        super.init(style: .grouped, windowUUID: windowUUID)
        // TODO: - FXIOS-14720 Add Strings
        self.title = "Quick Answers"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var theme: Theme {
        themeManager.getCurrentTheme(for: windowUUID)
    }

    override func generateSettings() -> [SettingSection] {
        return [quickAnswersSection]
    }

    private var quickAnswersSection: SettingSection {
        let enableFeatureSwitch = BoolSetting(
            prefs: prefs,
            theme: theme,
            prefKey: PrefsKeys.Settings.quickAnswersFeature,
            defaultValue: true,
            // TODO: - FXIOS-14720 Add Strings
            titleText: "Quick Answers"
        ) { _ in
            // TODO: FXIOS-15577 - Dispatch action to show or hide quick answers feature
        }
        return SettingSection(children: [enableFeatureSwitch])
    }
}
