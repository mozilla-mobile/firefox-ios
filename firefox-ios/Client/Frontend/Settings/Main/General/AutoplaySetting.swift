// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

class AutoplaySetting: Setting {
    private weak var settingsDelegate: GeneralSettingsDelegate?
    private let prefs: Prefs?

    override var accessoryView: UIImageView? {
        guard let theme else { return nil }
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    // TODO: Laurie - a11y identifier
    override var accessibilityIdentifier: String? { return "AutoplaySettings" }

    override var status: NSAttributedString? {
        guard let prefs else { return nil }
        return NSAttributedString(string: AutoplayAccessors.getAutoplayAction(prefs).settingTitle)
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(settings: SettingsTableViewController, settingsDelegate: GeneralSettingsDelegate?) {
        self.prefs = settings.profile?.prefs
        self.settingsDelegate = settingsDelegate
        let color = settings.themeManager.getCurrentTheme(for: settings.windowUUID).colors.textPrimary
        let attributes = [NSAttributedString.Key.foregroundColor: color]
        super.init(title: NSAttributedString(string: .Settings.Autoplay.Autoplay, attributes: attributes))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.pressedAutoPlay()
    }
}
