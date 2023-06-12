// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class TabsSetting: Setting {
    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "TabsSetting" }

    init(theme: Theme) {
        super.init(title: NSAttributedString(string: .Settings.SectionTitles.TabsTitle,
                                             attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = TabsSettingsViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
}
