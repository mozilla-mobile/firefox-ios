// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

final class TranslationSettingsViewController: SettingsTableViewController {
    init(windowUUID: WindowUUID) {
        super.init(style: .grouped, windowUUID: windowUUID)
        self.title = .Settings.Translation.Title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var theme: Theme {
        themeManager.getCurrentTheme(for: windowUUID)
    }

    override func generateSettings() -> [SettingSection] {
        return [translationSection]
    }

    private var translationSection: SettingSection {
        let enableFeatureSwitch = BoolSetting(
            with: .translation,
            titleText: NSAttributedString(
                string: .Settings.Translation.ToggleTitle,
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
            )
        )
        return SettingSection(
            title: NSAttributedString(
                string: .Settings.Translation.SectionTitle
            ),
            children: [enableFeatureSwitch]
        )
    }
}
