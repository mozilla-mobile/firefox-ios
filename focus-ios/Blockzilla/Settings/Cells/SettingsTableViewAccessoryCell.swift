/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SettingsTableViewAccessoryCell: SettingsTableViewCell {
    var labelText: String? {
        get { return textLabel?.text }
        set {
            textLabel?.text = newValue
        }
    }

    var accessoryLabelText: String? {
        get { return detailTextLabel?.text }
        set {
            detailTextLabel?.text = newValue
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryView = UIImageView(image: UIImage(systemName: "chevron.right"))
        tintColor = .secondaryText.withAlphaComponent(0.3)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
