// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class DevicePickerTableViewHeaderCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let tableHeaderTextFont = UIFont.systemFont(ofSize: 16)
        static let tableHeaderTextPaddingLeft: CGFloat = 20
    }

    let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(nameLabel)
        nameLabel.font = UX.tableHeaderTextFont
        nameLabel.text = .SendToDevicesListTitle

        nameLabel.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(contentView).offset(UX.tableHeaderTextPaddingLeft)
            make.centerY.equalTo(contentView)
            make.right.equalTo(contentView)
        }

        preservesSuperviewLayoutMargins = false
        layoutMargins = .zero
        separatorInset = .zero
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        nameLabel.textColor = theme.colors.textSecondary
    }
}
