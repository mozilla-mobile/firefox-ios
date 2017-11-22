/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// MARK: - Common UITableView text styling
extension NSAttributedString {
    convenience init(tableRowTitle string: String, enabled: Bool) {
        let color = enabled ? SettingsUX.TableViewRowTextColor : SettingsUX.TableViewDisabledRowTextColor
        self.init(string: string, attributes: [NSForegroundColorAttributeName : color])
    }
}
