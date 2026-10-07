// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

final class AdBlockerExceptionsSetting: Setting {
    private weak var settingsDelegate: BrowsingSettingsDelegate?
    private let exceptionsStorage: AdBlockerExceptionsStorageProtocol

    override var accessoryView: UIImageView? {
        guard let theme else { return nil }
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.Browsing.AdBlockerExceptions.settingRow
    }

    override var status: NSAttributedString? {
        return NSAttributedString(string: "\(exceptionsStorage.count)")
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(theme: Theme,
         settingsDelegate: BrowsingSettingsDelegate?,
         exceptionsStorage: AdBlockerExceptionsStorageProtocol = AdBlockerExceptionsStorage.shared) {
        self.settingsDelegate = settingsDelegate
        self.exceptionsStorage = exceptionsStorage
        let attributes = [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        super.init(
            title: NSAttributedString(
                string: String.Settings.Browsing.Exceptions.Title,
                attributes: attributes
            )
        )
        self.theme = theme
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.pressedAdBlockerExceptions()
    }
}
