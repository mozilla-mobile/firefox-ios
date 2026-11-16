// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class SummaryTitleCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private enum UX {
        static let topPadding: CGFloat = 32.0
        static let bottomPadding: CGFloat = 24.0
        static let horizontalPadding: CGFloat = 44.0
    }

    private let titleLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.title1.scaledFont()
        $0.numberOfLines = 0
        $0.adjustsFontForContentSizeCategory = true
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.topPadding),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                constant: UX.horizontalPadding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                 constant: -UX.horizontalPadding),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.bottomPadding)
        ])
    }

    func configure(text: String?, a11yId: String) {
        titleLabel.text = text
        titleLabel.accessibilityIdentifier = a11yId
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        backgroundColor = .clear
    }
}
