// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

final class SummarizeSettingsViewController: SettingsTableViewController, FeatureFlaggable {
    let prefs: Prefs
    private let nimbusUtils: SummarizerNimbusUtils

    init(
        prefs: Prefs,
        summarizeNimbusUtils: SummarizerNimbusUtils = DefaultSummarizerNimbusUtils(),
        windowUUID: WindowUUID
    ) {
        self.prefs = prefs
        self.nimbusUtils = summarizeNimbusUtils
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
        let summarizeContentEnabled = prefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature) ?? true
        let shakeFeatureFlag = nimbusUtils.isShakeGestureFeatureFlagEnabled()

        // Shows and hides the gesture section
        // based on the summarize feature being enabled
        // and shake gesture feature flag is true
        guard summarizeContentEnabled && shakeFeatureFlag else { return [summarizeSection] }

        return [summarizeSection, gesturesSection]
    }

    private var summarizeSection: SettingSection {
        let summarizeContentSetting = BoolSetting(
            prefs: prefs,
            theme: theme,
            prefKey: PrefsKeys.Summarizer.summarizeContentFeature,
            defaultValue: true,
            titleText: .Settings.Summarize.SummarizePagesTitle
        ) { [weak self] isOn in
            guard let self else { return }
            // Reload sections to hide and show gesture section
            // depending if summarize content setting toggle is On or Off
            self.settings = self.generateSettings()
            self.tableView.reloadData()

            store.dispatch(
                ToolbarAction(
                    canSummarize: isOn,
                    windowUUID: self.windowUUID,
                    actionType: ToolbarActionType.didSummarizeSettingsChange
                )
            )
        }
        return SettingSection(
            title: nil,
            footerTitle: NSAttributedString(
                string: .Settings.Summarize.FooterTitle
            ),
            children: [summarizeContentSetting]
        )
    }

    private var gesturesSection: SettingSection {
        let shakeGestureSetting = BoolSetting(
            prefs: prefs,
            theme: theme,
            prefKey: PrefsKeys.Summarizer.shakeGestureEnabled,
            defaultValue: true,
            titleText: .Settings.Summarize.GesturesSection.ShakeGestureTitle
        )
        return SettingSection(
            title: NSAttributedString(
                string: .Settings.Summarize.GesturesSection.Title
            ),
            footerTitle: NSAttributedString(
                string: .Settings.Summarize.GesturesSection.FooterTitle
            ),
            children: [shakeGestureSetting]
        )
    }
}
