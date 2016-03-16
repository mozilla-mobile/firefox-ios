/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

/// A cell subclass that implements a dynamic height title and subtitle label with
/// a switch control centered on the right side. Unfortunately the default
/// cell subtitle style doesn't support dynamic height calculations for a sublabel.
class BoolSettingTableViewCell: UITableViewCell {
    private lazy var _textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        return label
    }()

    private lazy var _detailTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        return label
    }()

    lazy var switchControl: UISwitch = {
        let control = UISwitch()
        control.onTintColor = UIConstants.ControlTintColor
        return control
    }()

    private lazy var labelContainer = UIView()

    override var textLabel: UILabel {
        return _textLabel
    }

    override var detailTextLabel: UILabel {
        return _detailTextLabel
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        labelContainer.addSubview(_textLabel)
        labelContainer.addSubview(_detailTextLabel)
        contentView.addSubview(labelContainer)
        contentView.addSubview(switchControl)

        // These values may seem random but were chosen to map closely to the default padding/margins 
        // of the subtitle cell style.
        _textLabel.snp_makeConstraints { make in
            make.left.right.equalTo(labelContainer).inset(16)
            make.top.equalTo(labelContainer).inset(8)
        }

        _detailTextLabel.snp_makeConstraints { make in
            make.top.equalTo(_textLabel.snp_bottom).offset(4)
            make.bottom.equalTo(labelContainer).inset(8)
            make.left.right.equalTo(_textLabel)
        }

        labelContainer.snp_makeConstraints { make in
            make.left.top.bottom.equalTo(contentView)
            make.right.equalTo(switchControl.snp_left).inset(16)
        }

        switchControl.snp_makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.right.equalTo(contentView).inset(16)
        }

        // Make sure the switch part of the cell never gets squeezed.
        switchControl.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}