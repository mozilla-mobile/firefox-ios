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
        let imageView = UIImageView(image: BreachAlertsManager.icon)
        imageView.isHidden = true
        return imageView
    }()
    lazy var breachAlertContainer: UIView = {
        let view = UIView()
        view.addSubview(breachAlertImageView)
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return view
    }()
    lazy var breachMargin: CGFloat = {
        return breachAlertSize+LoginTableViewCellUX.HorizontalMargin*2
    }()

    let hostnameLabel = UILabel()
    let usernameLabel = UILabel()
    private lazy var hostnameContainer: UIView = {
        let view = UIView()
        view.addSubview(hostnameLabel)
        return view
    }()
    private lazy var usernameContainer: UIView = {
        let view = UIView()
        view.addSubview(usernameLabel)
        return view
    }()
    private lazy var textStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [hostnameContainer, usernameContainer])
        stack.axis = .vertical
        return stack
    }()
    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [textStack, breachAlertContainer])
        stack.axis = .horizontal
        return stack
    }()

    var inset: UIEdgeInsets!

    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, inset: UIEdgeInsets) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.inset = inset
        accessoryType = .disclosureIndicator
        contentView.addSubview(contentStack)
        // Need to override the default background multi-select color to support theming
        self.multipleSelectionBackgroundView = UIView()
        self.hostnameLabel.textColor = UIColor.theme.tableView.rowText
        self.usernameLabel.textColor = self.detailTextColor
        self.applyTheme()
        setConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setConstraints() {
        self.contentStack.snp.remakeConstraints { make in
            make.top.bottom.trailing.equalTo(contentView)
            make.left.equalTo(contentView).inset(self.inset.left)
        }
        self.hostnameLabel.snp.remakeConstraints { make in
            make.bottom.equalTo(self.contentStack.snp.centerY)
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualTo(self.textStack.snp.trailing)
        }
        self.usernameLabel.snp.remakeConstraints { make in
            make.top.equalTo(self.contentStack.snp.centerY)
        }
        self.breachAlertImageView.snp.remakeConstraints { make in
            make.width.height.equalTo(breachAlertSize)
            make.center.equalTo(self.breachAlertContainer.snp.center)
        }
        self.breachAlertContainer.snp.remakeConstraints { make in
            make.width.equalTo(breachMargin)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setConstraints()
    }
}
