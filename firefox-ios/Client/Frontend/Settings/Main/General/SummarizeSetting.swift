// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class SummarizeSetting: Setting {
    private weak var settingsDelegate: GeneralSettingsDelegate?

    override var accessoryView: UIImageView? {
        guard let theme else { return nil }
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.Summarize.title
    }

    init(settings: SettingsTableViewController,
         settingsDelegate: GeneralSettingsDelegate?) {
        self.settingsDelegate = settingsDelegate
        let theme = settings.themeManager.getCurrentTheme(for: settings.windowUUID)
        // TODO: FXIOS-12645 - Add from Strings when ready
        let settingTitle = "Summarize Content"
        super.init(
            title: NSAttributedString(
                string: settingTitle,
                attributes: [
                    NSAttributedString.Key.foregroundColor: theme.colors.textPrimary
                ]
            )
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.pressedSummarize()
    }
}
