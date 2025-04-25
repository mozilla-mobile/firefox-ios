// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

class SearchSetting: Setting {
    private let searchEnginesManager: SearchEnginesManagerProvider
    private weak var settingsDelegate: GeneralSettingsDelegate?

    override var accessoryView: UIImageView? {
        guard let theme else { return nil }
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    override var status: NSAttributedString? {
        return NSAttributedString(
            string: searchEnginesManager.defaultEngine?.shortName ?? ""
        )
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.Search.title
    }

    init(settingsDelegate: GeneralSettingsDelegate?,
         searchEnginesManager: SearchEnginesManagerProvider,
         theme: Theme) {
        self.searchEnginesManager = searchEnginesManager
        self.settingsDelegate = settingsDelegate
        super.init(
            title: NSAttributedString(
                string: .AppSettingsSearch,
                attributes: [
                    NSAttributedString.Key.foregroundColor: theme.colors.textPrimary
                ]
            )
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.pressedSearchEngine()
    }
}
