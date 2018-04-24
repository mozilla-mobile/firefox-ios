/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// MARK: - Common UITableView text styling
extension NSAttributedString {
    static func tableRowTitle(_ string: String, enabled: Bool) -> NSAttributedString {
        let color = enabled ? [NSAttributedStringKey.foregroundColor: SettingsUX.TableViewRowTextColor] : [NSAttributedStringKey.foregroundColor: SettingsUX.TableViewDisabledRowTextColor]
        return NSAttributedString(string: string, attributes: color)
    }
}
