// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

protocol RestoreAlertCreator {
    /// Builds the Alert view that asks the user if they wish to restore their tabs after a crash.
    /// - Parameters:
    ///   - okayCallback: Okay option handler
    ///   - noCallback: No option handler
    /// - Returns: UIAlertController for asking the user to restore tabs after a crash
    func restoreTabsAlert(okayCallback: @escaping () -> Void,
                          noCallback: @escaping () -> Void) -> UIAlertController
}

struct DefaultRestoreAlertCreator: RestoreAlertCreator {
    func restoreTabsAlert(okayCallback: @escaping () -> Void,
                          noCallback: @escaping () -> Void) -> UIAlertController {
        let titleString = String(format: .Alerts.RestoreTabs.Title,
                                 AppName.shortName.rawValue)

        let alert = UIAlertController(
            title: titleString,
            message: .Alerts.RestoreTabs.Message,
            preferredStyle: .alert
        )

        let noOption = UIAlertAction(
            title: .Alerts.RestoreTabs.ButtonNo,
            style: .cancel,
            handler: { _ in
                noCallback()
            }
        )

        let okayOption = UIAlertAction(
            title: .Alerts.RestoreTabs.ButtonYes,
            style: .default,
            handler: { _ in
                okayCallback()
            }
        )

        alert.addAction(okayOption)
        alert.addAction(noOption)
        return alert
    }
}
