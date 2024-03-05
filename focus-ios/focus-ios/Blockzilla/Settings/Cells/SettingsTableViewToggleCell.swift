/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SettingsTableViewToggleCell: SettingsTableViewCell {
    private let newLabel = SmartLabel()
    var navigationController: UINavigationController?

    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, toggle: BlockerToggle) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupDynamicFont(forLabels: [newLabel], addObserver: true)

        newLabel.numberOfLines = 0
        newLabel.text = toggle.label

        textLabel?.numberOfLines = 0
        textLabel?.text = toggle.label

        newLabel.textColor = .primaryText
        textLabel?.textColor = .primaryText
        layoutMargins = UIEdgeInsets.zero

        accessoryView = PaddedSwitch(switchView: toggle.toggle)
        selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
