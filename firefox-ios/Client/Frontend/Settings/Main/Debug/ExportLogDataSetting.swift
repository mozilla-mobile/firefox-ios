// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

class ExportLogDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        guard let theme else { return nil }
        // Not localized for now.
        return NSAttributedString(
            string: "Copy log files to app container",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        DefaultLogger.shared.copyLogsToDocuments()
    }
}
