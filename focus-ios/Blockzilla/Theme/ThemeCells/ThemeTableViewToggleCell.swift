/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class ThemeTableViewToggleCell: UITableViewCell {
    var toggle = UISwitch()
    weak var delegate: SystemThemeDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let backgroundColorView = UIView()
        selectedBackgroundView = backgroundColorView
        textLabel?.numberOfLines = 0
        textLabel?.text = UIConstants.strings.useSystemTheme
        textLabel?.textColor = .primaryText
        layoutMargins = UIEdgeInsets.zero
        toggle.onTintColor = .accent
        toggle.tintColor = .darkGray
        toggle.addTarget(self, action: #selector(toggleSwitched(_:)), for: .valueChanged)
        accessoryView = PaddedSwitch(switchView: toggle)
        selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func toggleSwitched(_ sender: UISwitch) {
    delegate?.didEnableSystemTheme(sender.isOn)
    }
}
