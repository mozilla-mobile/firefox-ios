// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class SearchBarSetting: Setting {
    let viewModel: SearchBarSettingsViewModel

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return AccessibilityIdentifiers.Settings.SearchBar.searchBarSetting }

    override var status: NSAttributedString {
        return NSAttributedString(string: viewModel.searchBarTitle )
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(settings: SettingsTableViewController) {
        self.viewModel = SearchBarSettingsViewModel(prefs: settings.profile.prefs)
        super.init(title: NSAttributedString(string: viewModel.title,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = SearchBarSettingsViewController(viewModel: viewModel)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
