// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

class DevicePickerTableViewCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let deviceRowTextFont = UIFont.systemFont(ofSize: 16)
        static let deviceRowTextPaddingLeft: CGFloat = 72
        static let deviceRowTextPaddingRight: CGFloat = 50
    }

    var nameLabel: UILabel
    var checked = false {
        didSet {
            self.accessoryType = checked ? .checkmark : .none
        }
    }

    var clientType = ClientType.Mobile {
        didSet {
            self.imageView?.image = UIImage.templateImageNamed(clientType.rawValue)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        nameLabel = UILabel()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(nameLabel)
        nameLabel.font = UX.deviceRowTextFont
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byWordWrapping
        self.tintColor = UIColor.label
        self.preservesSuperviewLayoutMargins = false
        self.selectionStyle = .none
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        nameLabel.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(UX.deviceRowTextPaddingLeft)
            make.centerY.equalTo(self.snp.centerY)
            make.right.equalTo(self.snp.right).offset(-UX.deviceRowTextPaddingRight)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: Theme) {
        nameLabel.textColor = theme.colors.textPrimary
        imageView?.image = imageView?.image?.withRenderingMode(.alwaysTemplate)
        imageView?.tintColor = theme.colors.textPrimary
    }
}
