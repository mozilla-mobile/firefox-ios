// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

/// Opens the SUMO page in a new tab
class OpenSupportPageSetting: Setting {
    private weak var settingsDelegate: SupportSettingsDelegate?

    init(delegate: SettingsDelegate?,
         theme: Theme,
         settingsDelegate: SupportSettingsDelegate?) {
        self.settingsDelegate = settingsDelegate
        super.init(title: NSAttributedString(string: .AppSettingsHelp,
                                             attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]),
                   delegate: delegate)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        if CoordinatorFlagManager.isSettingsCoordinatorEnabled,
           let url = URL(string: "https://support.mozilla.org/products/ios") {
            settingsDelegate?.pressedOpenSupportPage(url: url)
            return
        }

        navigationController?.dismiss(animated: true) {
            if let url = URL(string: "https://support.mozilla.org/products/ios") {
                self.delegate?.settingsOpenURLInNewTab(url)
            }
        }
    }
}
