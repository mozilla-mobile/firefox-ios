/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SettingsTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .gray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal func setupDynamicFont(forLabels labels: [UILabel], addObserver: Bool = false) {
        for label in labels {
            label.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
            label.adjustsFontForContentSizeCategory = true
        }

        NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: nil) { _ in
            self.setupDynamicFont(forLabels: labels)
        }
    }
}
