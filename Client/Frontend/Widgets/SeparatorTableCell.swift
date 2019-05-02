/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SeparatorTableCell: UITableViewCell {
    override var textLabel: UILabel? {
        return nil
    }

    override var detailTextLabel: UILabel? {
        return nil
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none
        self.indentationWidth = 0
        self.separatorInset = .zero
        self.layoutMargins = .zero
        self.backgroundColor = UIColor.theme.tableView.rowBackground    // So we get a gentle white and grey stripe.
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
