// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Ecosia

class DefaultBrowserSetting: Setting {
    override var accessibilityIdentifier: String? { return "DefaultBrowserSettings" }

    init(theme: Theme) {
        /* Ecosia: Update Title
        super.init(
            title: NSAttributedString(
                string: String.DefaultBrowserMenuItem,
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.actionPrimary]
            )
        )
         */
        super.init(title: .init(string: .localized(.setAsDefaultBrowser), attributes: [NSAttributedString.Key.foregroundColor: theme.colors.ecosia.tableViewRowText]))
    }

    // Ecosia: Override cell config to add image
    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        cell.imageView?.image = .init(named: "yourImpact")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        TelemetryWrapper.gleanRecordEvent(category: .action,
                                          method: .open,
                                          object: .settingsMenuSetAsDefaultBrowser)

        // Ecosia: Track default browser setting click
        Analytics.shared.defaultBrowserSettings()

        DefaultApplicationHelper().openSettings()
    }
}
