// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

final class TranslationSetting: Setting {
    private weak var settingsDelegate: GeneralSettingsDelegate?
    private let profile: Profile?

    override var accessoryView: UIImageView? {
        guard let theme else { return nil }
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.Translation.title
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    override var status: NSAttributedString? {
        guard let profile else { return nil }
        let isSwitchOn = profile.prefs.boolForKey(PrefsKeys.Settings.translationsFeature) ?? true
        let statusString: String = isSwitchOn ? .Settings.Translation.SettingOn : .Settings.Translation.SettingOff
        return NSAttributedString(string: statusString)
    }

    init(settings: SettingsTableViewController,
         settingsDelegate: GeneralSettingsDelegate?) {
        self.profile = settings.profile
        self.settingsDelegate = settingsDelegate
        let theme = settings.themeManager.getCurrentTheme(for: settings.windowUUID)
        super.init(
            title: NSAttributedString(
                string: .Settings.Translation.Title,
                attributes: [
                    NSAttributedString.Key.foregroundColor: theme.colors.textPrimary
                ]
            )
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.pressedTranslation()
    }
}
