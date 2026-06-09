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
        ) { [weak self] _ in
            guard let self else { return }
            // Instead of passing the updated value here, we are using determining
            // whether the feature should be shown in the middleware so that we use the userPreferencesProvider
            // as the source of truth.
            store.dispatch(
                QuickAnswersAction(
                    windowUUID: self.windowUUID,
                    actionType: QuickAnswersActionType.didSettingsChange
                )
            )
        }
        return SettingSection(children: [enableFeatureSwitch])
    }
}
