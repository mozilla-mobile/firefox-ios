// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

class AutoplaySetting: Setting {
    private weak var settingsDelegate: BrowsingSettingsDelegate?
    private let prefs: Prefs

    override var accessoryView: UIImageView? {
        guard let theme else { return nil }
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.Browsing.autoPlay
    }

    override var status: NSAttributedString? {
        return NSAttributedString(string: AutoplayAccessors.getAutoplayAction(prefs).settingTitle)
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(theme: Theme,
         prefs: Prefs,
         settingsDelegate: BrowsingSettingsDelegate?) {
        self.prefs = prefs
        self.settingsDelegate = settingsDelegate
        let color = theme.colors.textPrimary
        let attributes = [NSAttributedString.Key.foregroundColor: color]
        super.init(title: NSAttributedString(string: .Settings.Autoplay.Autoplay, attributes: attributes))
        self.theme = theme
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.pressedAutoPlay()
    }
}
