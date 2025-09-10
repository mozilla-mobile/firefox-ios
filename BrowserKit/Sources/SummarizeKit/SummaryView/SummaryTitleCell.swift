// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

final class SummaryTitleCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let titleBottomPadding: CGFloat = 20
    }
    private let titleLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.title1.scaledFont()
        $0.adjustsFontForContentSizeCategory = true
        $0.numberOfLines = 0
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.titleBottomPadding)
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
