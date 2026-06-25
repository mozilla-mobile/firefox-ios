// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class LinkActionCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let horizontalPadding: CGFloat = 16.0
        static let verticalPadding: CGFloat = 11.0
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 1
        label.textAlignment = .center
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }

    private func setupLayout() {
        selectionStyle = .default
        accessibilityTraits = .button
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.horizontalPadding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.horizontalPadding),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.verticalPadding),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.verticalPadding)
        ])
    }

    func configure(title: String) {
        titleLabel.text = title
    }

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer5
        titleLabel.textColor = theme.colors.actionPrimary
    }
}
