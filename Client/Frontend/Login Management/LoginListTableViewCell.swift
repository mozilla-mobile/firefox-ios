/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class LoginListTableViewCell: ThemedTableViewCell {
    lazy var breachAlertImageView: UIImageView = {
        let image = UIImage(named: "Breached Website")
        let imageView = UIImageView(image: image)
        imageView.isHidden = true
        return imageView
    }()
    let breachAlertSize: CGFloat = 24

    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, inset: UIEdgeInsets) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        contentView.addSubview(breachAlertImageView)
        breachAlertImageView.snp.remakeConstraints { make in
            make.centerY.equalTo(contentView)
            make.trailing.equalTo(contentView.snp.trailing).offset(-LoginTableViewCellUX.HorizontalMargin)
            make.width.equalTo(breachAlertSize)
            make.height.equalTo(breachAlertSize)
        }

        textLabel?.snp.remakeConstraints({ make in
            make.leading.equalTo(contentView).offset(inset.left)
            make.trailing.equalTo(breachAlertImageView.snp.leading).offset(-LoginTableViewCellUX.HorizontalMargin/2)
            make.top.equalTo(inset.top)
            make.centerY.equalTo(contentView)
            if let detailTextLabel = self.detailTextLabel {
                make.bottom.equalTo(detailTextLabel.snp.top)
                make.top.equalTo(contentView.snp.top).offset(LoginTableViewCellUX.HorizontalMargin)
            }
        })

        // Need to override the default background multi-select color to support theming
        self.multipleSelectionBackgroundView = UIView()
        self.applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
