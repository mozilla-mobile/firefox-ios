/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// MARK: - Common UITableView text styling
extension AttributedString {
    static func tableRowTitle(_ string: String) -> AttributedString {
        return AttributedString(string: string, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    static func disabledTableRowTitle(_ string: String) -> AttributedString {
        return AttributedString(string: string, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewDisabledRowTextColor])
    }
}
