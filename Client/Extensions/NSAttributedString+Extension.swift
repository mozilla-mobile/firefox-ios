// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

// MARK: - Common UITableView text styling
extension NSAttributedString {
    static func tableRowTitle(_ string: String, theme: Theme, enabled: Bool) -> NSAttributedString {
        let color = enabled ? [NSAttributedString.Key.foregroundColor: theme.colors.tableViewRowText] : [NSAttributedString.Key.foregroundColor: theme.colors.tableViewDisabledRowText]
        return NSAttributedString(string: string, attributes: color)
    }
}
