// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class StudiesToggleSetting: BoolSetting {
    private weak var settingsDelegate: SupportSettingsDelegate?

    init(prefs: Prefs,
         delegate: SettingsDelegate?,
         theme: Theme,
         settingsDelegate: SupportSettingsDelegate?) {
        let statusText = NSMutableAttributedString()
        statusText.append(NSAttributedString(string: .SettingsStudiesToggleMessage,
                                             attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary]))
        statusText.append(NSAttributedString(string: " "))
        statusText.append(NSAttributedString(string: .SettingsStudiesToggleLink,
                                             attributes: [NSAttributedString.Key.foregroundColor: theme.colors.actionPrimary]))

        self.settingsDelegate = settingsDelegate
        super.init(
            prefs: prefs,
            prefKey: AppConstants.prefStudiesToggle,
            defaultValue: true,
            attributedTitleText: NSAttributedString(string: .SettingsStudiesToggleTitle),
            attributedStatusText: statusText,
            settingDidChange: {
                Experiments.setStudiesSetting($0)
            }
        )
        // We make sure to set this on initialization, in case the setting is turned off
        // in which case, we would to make sure that users are opted out of experiments
        Experiments.setStudiesSetting(prefs.boolForKey(AppConstants.prefStudiesToggle) ?? true)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.StudiesToggle.title
    }

    override var url: URL? {
        return SupportUtils.URLForTopic("ios-studies")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
            settingsDelegate?.askedToOpen(url: url, withTitle: title)
            return
        }

        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}
