// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

class PasswordManagerSettingsTableViewCell: ThemedTableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PasswordManagerTableViewCell: ThemedTableViewCell {
    private struct UX {
        static let horizontalMargin: CGFloat = 14
    }

    private let breachAlertSize: CGFloat = 24
    lazy var breachAlertImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: StandardImageIdentifiers.Large.warningFill)?
            .withRenderingMode(.alwaysTemplate)
        imageView.isHidden = true
    }

    lazy var breachAlertContainer: UIView = .build { [weak self] view in
        guard let self = self else { return }

        view.addSubview(self.breachAlertImageView)
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    lazy var breachMargin: CGFloat = {
        return breachAlertSize + UX.horizontalMargin * 2
    }()

    lazy var hostnameLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.callout.scaledFont()
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        label.setContentHuggingPriority(.required, for: .vertical)
    }

    lazy var usernameLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
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

    private var inset: UIEdgeInsets = .zero

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(contentStack)
        // Need to override the default background multi-select color to support theming
        multipleSelectionBackgroundView = UIView()
    }

    func configure(inset: UIEdgeInsets) {
        self.inset = inset
        accessoryType = .disclosureIndicator
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
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset.left),

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

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.addSubview(contentStack)
    }

    override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)
        hostnameLabel.textColor = theme.colors.textPrimary
        usernameLabel.textColor = theme.colors.textSecondary
        breachAlertImageView.tintColor = theme.colors.iconCritical
    }
}
