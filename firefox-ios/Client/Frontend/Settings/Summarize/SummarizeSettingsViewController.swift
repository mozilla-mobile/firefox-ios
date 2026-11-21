// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

final class SummarizeSettingsViewController: SettingsTableViewController {
    let prefs: Prefs
    private let nimbusUtils: SummarizerNimbusUtils
    private let settingsTelemetry: SettingsTelemetry
    private var pendingSectionUpdate: DispatchWorkItem?

    init(
        prefs: Prefs,
        summarizeNimbusUtils: SummarizerNimbusUtils = DefaultSummarizerNimbusUtils(),
        settingsTelemetry: SettingsTelemetry = SettingsTelemetry(),
        windowUUID: WindowUUID
    ) {
        self.prefs = prefs
        self.nimbusUtils = summarizeNimbusUtils
        self.settingsTelemetry = settingsTelemetry
        super.init(style: .grouped, windowUUID: windowUUID)
        self.title = .Settings.Summarize.Title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var theme: Theme {
        currentTheme()
    }

    override func generateSettings() -> [SettingSection] {
        let summarizeContentEnabled = prefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature) ?? true

        // Shows and hides the gesture section
        // based on the summarize feature being enabled.
        guard summarizeContentEnabled else {
            return [summarizeSection]
        }
        var sections = [summarizeSection]
        if nimbusUtils.isShakeGestureFeatureFlagEnabled() {
            sections.append(gesturesSection)
        }
        if nimbusUtils.isLanguageExpansionEnabled {
            sections.append(languageSection)
        }

        return sections
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
            // Refresh the sections only after the switch animation has settled,
            // and coalesce rapid toggles into a single update. Mutating the table
            // mid-gesture rebuilds the toggle's cell and makes the switch
            // animation glitch; animating the section change (even with .none)
            // makes the iOS 26 switch cancel delivery of rapid subsequent
            // valueChanged events, leaving the prefs and the UI out of sync.
            pendingSectionUpdate?.cancel()
            let update = DispatchWorkItem { [weak self] in
                self?.updateSettingsSections()
            }
            pendingSectionUpdate = update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: update)

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

    private func updateSettingsSections() {
        settings = generateSettings()
        // Reload instead of animating section inserts/deletes: by the time this
        // runs the switch animation has finished, so rebuilding the toggle's cell
        // is invisible, and an unanimated reload does not interfere with the
        // iOS 26 switch's deferred valueChanged delivery.
        tableView.reloadData()
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

    private var languageSection: SettingSection {
        let configuration = nimbusUtils.languageExpansionConfiguration(
            from: FxNimbus.shared.features.summarizerLanguageExpansionFeature.value()
        )
        return SettingSection(
            title: NSAttributedString(string: .Settings.Summarize.LanguageSection.Title),
            children: [
                PickerSetting(
                    selectedValue: configuration.selectedPreference(prefs: prefs),
                    pickerOptions: configuration.settingOptions.map({ $0.toOption() }),
                    accessibilityIdentifier: AccessibilityIdentifiers.Settings.Summarize.languageCell,
                    onOptionSelected: { [weak self] selectedOption in
                        guard let self else { return }
                        let previousOption = configuration.selectedPreference(prefs: prefs)
                        configuration.save(preference: selectedOption, prefs: prefs)
                        settingsTelemetry.changedSetting(
                            PrefsKeys.Summarizer.selectedLanguage,
                            to: selectedOption.saveValue,
                            from: previousOption.saveValue
                        )
                        tableView.reloadData()
                    }
                )
            ]
        )
    }
}
