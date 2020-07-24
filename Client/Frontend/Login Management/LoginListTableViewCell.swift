/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class LoginListTableViewSettingsCell: ThemedTableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LoginListTableViewCell: ThemedTableViewCell {
    private let breachAlertSize: CGFloat = 24
    lazy var breachAlertImageView: UIImageView = {
        let image = UIImage(named: "Breached Website")
        let imageView = UIImageView(image: image)
        imageView.isHidden = true
        return imageView
    }()
    lazy var breachMargin: CGFloat = {
        return -LoginTableViewCellUX.HorizontalMargin*2
    }()
    var inset: UIEdgeInsets!

    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, inset: UIEdgeInsets) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.inset = inset
        accessoryType = .disclosureIndicator
        contentView.addSubview(breachAlertImageView)
        breachAlertImageView.snp.remakeConstraints { make in
            make.centerY.equalTo(contentView)
            make.trailing.equalTo(contentView.snp.trailing).offset(-LoginTableViewCellUX.HorizontalMargin)
            make.width.height.equalTo(breachAlertSize)
        }
        // Need to override the default background multi-select color to support theming
        self.multipleSelectionBackgroundView = UIView()
        self.applyTheme()
        setConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setConstraints() {
        if (self.detailTextLabel?.text != "") {
            self.textLabel?.snp.remakeConstraints({ make in
                guard let textLabel = self.textLabel else { return }
                make.leading.equalTo(self.snp.leading).offset(inset.left)
                make.trailing.equalTo(breachAlertImageView).offset(breachMargin)
                make.bottom.equalTo(self.snp.centerY)//.offset(-textLabel.frame.height/2)
            })
            self.detailTextLabel?.snp.remakeConstraints({ make in
                guard let detailTextLabel = self.detailTextLabel else { return }
                make.leading.equalToSuperview().offset(inset.left)
                make.trailing.equalTo(breachAlertImageView).offset(breachMargin)
                make.top.equalTo(self.snp.centerY)//.offset(detailTextLabel.frame.height/2)
            })
        } else {
            self.textLabel?.snp.remakeConstraints({ make in
                make.top.equalToSuperview().offset(inset.top)
                make.trailing.equalTo(breachAlertImageView).offset(breachMargin)
                make.bottom.equalToSuperview().offset(inset.bottom)
                make.leading.equalToSuperview().offset(inset.left)
            })
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setConstraints()
    }
}
