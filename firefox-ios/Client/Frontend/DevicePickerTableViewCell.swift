// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

class DevicePickerTableViewCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let deviceRowTextFont = UIFont.systemFont(ofSize: 16)
        static let deviceRowTextPaddingLeft: CGFloat = 60
        static let deviceRowTextPaddingRight: CGFloat = 20
        static let deviceRowTopMargin: CGFloat = 0
        static let deviceRowLeadingMargin: CGFloat = 16
        static let deviceRowBottomMargin: CGFloat = 0
        static let deviceRowTrailingMargin: CGFloat = 0
    }

    private lazy var nameLabel: UILabel = .build { label in
        label.font = UX.deviceRowTextFont
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
    }

    var checked = false {
        didSet {
            self.accessoryType = checked ? .checkmark : .none
        }
    }

    var clientType = ClientType.Mobile {
        didSet {
            self.imageView?.image = UIImage.templateImageNamed(clientType.imageName)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(nameLabel)
        setupLayout()
        self.tintColor = UIColor.label
        self.preservesSuperviewLayoutMargins = false
        self.selectionStyle = .none
    }

    private func setupLayout() {
        NSLayoutConstraint.activate(
            [
                nameLabel.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: UX.deviceRowTextPaddingLeft
                ),
                nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                nameLabel.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -UX.deviceRowTextPaddingRight
                )
            ]
        )
    }

    func configureCell(_ text: String, _ clientType: ClientType) {
        nameLabel.text = text
        self.clientType = clientType
        directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: UX.deviceRowTopMargin,
            leading: UX.deviceRowLeadingMargin,
            bottom: UX.deviceRowBottomMargin,
            trailing: UX.deviceRowTrailingMargin
        )
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: Theme) {
        let colors = theme.colors
        nameLabel.textColor = colors.textPrimary
        imageView?.image = imageView?.image?.withRenderingMode(.alwaysTemplate)
        imageView?.tintColor = colors.textPrimary
        backgroundColor = colors.layer2
        tintColor = colors.textPrimary
    }
}
