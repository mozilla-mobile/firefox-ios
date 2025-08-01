// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

final class SummarizeSettingsViewController: SettingsTableViewController, FeatureFlaggable {
    let prefs: Prefs
    init(prefs: Prefs, windowUUID: WindowUUID) {
        self.prefs = prefs
        super.init(style: .grouped, windowUUID: windowUUID)
        self.title = .Settings.Summarize.Title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var theme: Theme {
        themeManager.getCurrentTheme(for: windowUUID)
    }

    override func generateSettings() -> [SettingSection] {
        return [summarizeContentSettingSection]
    }

    private var summarizeContentSettingSection: SettingSection {
        let summarizeContentSetting = BoolSetting(
            prefs: prefs,
            theme: theme,
            prefKey: PrefsKeys.Summarizer.summarizeContentFeature,
            defaultValue: true,
            titleText: .Settings.Summarize.SummarizeContentTitle
        )
        return SettingSection(title: nil, children: [summarizeContentSetting])
    }
}
