// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

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
    lazy var breachAlertImageView: UIImageView = .build { imageView in
        imageView.image = BreachAlertsManager.icon
        imageView.isHidden = true
    }

    lazy var breachAlertContainer: UIView = .build { [weak self] view in
        guard let self = self else { return }

        view.addSubview(self.breachAlertImageView)
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    lazy var breachMargin: CGFloat = {
        return breachAlertSize + LoginTableViewCellUX.HorizontalMargin * 2
    }()

    lazy var hostnameLabel: UILabel = .build { label in
        label.textColor = UIColor.theme.tableView.rowText
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .left
        label.numberOfLines = 1
        label.setContentHuggingPriority(.required, for: .vertical)
    }

    lazy var usernameLabel: UILabel = .build { label in
        label.textColor = UIColor.theme.tableView.rowDetailText
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .left
        label.numberOfLines = 1
    }

    private lazy var textStack: UIStackView = .build { [weak self] stack in
        guard let self = self else { return }

        stack.addArrangedSubview(self.hostnameLabel)
        stack.addArrangedSubview(self.usernameLabel)
        stack.axis = .vertical
        stack.isLayoutMarginsRelativeArrangement = true
        stack.spacing = 8
        stack.layoutMargins = .init(top: 8, left: 0, bottom: 8, right: 0)
    }

    private lazy var contentStack: UIStackView = .build { [weak self] stack in
        guard let self = self else { return }

        stack.addArrangedSubview(self.textStack)
        stack.addArrangedSubview(self.breachAlertContainer)
        stack.axis = .horizontal
    }

    private let inset: UIEdgeInsets

    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, inset: UIEdgeInsets) {
        self.inset = inset
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        contentView.addSubview(contentStack)
        // Need to override the default background multi-select color to support theming
        multipleSelectionBackgroundView = UIView()
        applyTheme()
        setConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentStack.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: inset.left),

            breachAlertImageView.widthAnchor.constraint(equalToConstant: breachAlertSize),
            breachAlertImageView.heightAnchor.constraint(equalToConstant: breachAlertSize),
            breachAlertImageView.centerYAnchor.constraint(equalTo: breachAlertContainer.centerYAnchor),
            breachAlertImageView.centerXAnchor.constraint(equalTo: breachAlertContainer.centerXAnchor),
            breachAlertContainer.widthAnchor.constraint(equalToConstant: breachMargin)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setConstraints()
    }
}
