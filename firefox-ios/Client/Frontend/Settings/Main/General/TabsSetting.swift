// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

// TODO: Laurie - to delete
class TabsSetting: Setting {
    private weak var settingsDelegate: BrowsingSettingsDelegate?

    override var accessoryView: UIImageView? {
        guard let theme else { return nil }
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.Tabs.title
    }

    init(theme: Theme,
         settingsDelegate: BrowsingSettingsDelegate?) {
        self.settingsDelegate = settingsDelegate
        super.init(
            title: NSAttributedString(
                string: .Settings.SectionTitles.TabsTitle,
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
            )
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
//        settingsDelegate?.pressedTabs()
    }
}
