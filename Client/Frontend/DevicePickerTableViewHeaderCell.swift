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

    private lazy var nameLabel: UILabel = .build { label in
        label.font = UX.tableHeaderTextFont
        label.text = .SendToDevicesListTitle
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.tableHeaderTextPaddingLeft),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        preservesSuperviewLayoutMargins = false
        layoutMargins = .zero
        separatorInset = .zero
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        let colors = theme.colors
        nameLabel.textColor = colors.textSecondary
    }
}
