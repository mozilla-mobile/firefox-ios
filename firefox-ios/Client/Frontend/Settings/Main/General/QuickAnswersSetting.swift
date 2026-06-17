// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

final class QuickAnswersSetting: Setting, UserFeaturePreferenceProvider {
    private weak var settingsDelegate: GeneralSettingsDelegate?
    private let profile: Profile?

    override var accessoryView: UIImageView? {
        guard let theme else { return nil }
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.QuickAnswers.title
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    override var status: NSAttributedString? {
        let isSwitchOn = userPreferences.getPreferenceFor(.quickAnswers)
        // TODO: - FXIOS-14720 Add Strings
        let statusString: String = isSwitchOn ? "On" : "Off"
        return NSAttributedString(string: statusString)
    }

    init(settings: SettingsTableViewController,
         settingsDelegate: GeneralSettingsDelegate?) {
        self.profile = settings.profile
        self.settingsDelegate = settingsDelegate
        let theme = settings.themeManager.getCurrentTheme(for: settings.windowUUID)
        // TODO: - FXIOS-14720 Add Strings
        super.init(
            title: NSAttributedString(
                string: "Quick Answers",
                attributes: [
                    NSAttributedString.Key.foregroundColor: theme.colors.textPrimary
                ]
            )
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.pressedQuickAnswers()
    }
}
