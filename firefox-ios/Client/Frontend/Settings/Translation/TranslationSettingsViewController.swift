// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

final class TranslationSettingsViewController: SettingsTableViewController {
    let prefs: Prefs
    init(prefs: Prefs, windowUUID: WindowUUID) {
        self.prefs = prefs
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
            prefs: prefs,
            theme: theme,
            prefKey: PrefsKeys.Settings.translationsFeature,
            defaultValue: true,
            titleText: .Settings.Translation.ToggleTitle
        ) { [weak self] _ in
            guard let self else { return }
            store.dispatch(
                ToolbarAction(
                    translationConfiguration: TranslationConfiguration(prefs: self.prefs, state: .inactive),
                    windowUUID: self.windowUUID,
                    actionType: ToolbarActionType.didTranslationSettingsChange
                )
            )
        }
        return SettingSection(
            title: NSAttributedString(
                string: .Settings.Translation.SectionTitle
            ),
            children: [enableFeatureSwitch]
        )
    }
}
