// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

final class SummaryBrandCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let logoSize: CGFloat = 16.0
        static let subViewsSidePadding: CGFloat = 6.0
        static let brandLabelLeadingPadding: CGFloat = 8.0
        static let containerViewBottomPadding: CGFloat = 16.0
    }

    private let logoImageView: UIImageView = .build {
        $0.contentMode = .scaleAspectFit
        $0.adjustsImageSizeForAccessibilityContentSizeCategory = true
    }
    private let containerView: UIView = .build()
    private let brandLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.caption2.scaledFont()
        $0.numberOfLines = 1
        $0.adjustsFontForContentSizeCategory = true
        $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
        $0.showsLargeContentViewer = true
        $0.isUserInteractionEnabled = true
        $0.addInteraction(UILargeContentViewerInteraction())
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        contentView.addSubview(containerView)
        containerView.addSubviews(logoImageView, brandLabel)

        logoImageView.setContentCompressionResistancePriority(.required, for: .vertical)
        logoImageView.setContentHuggingPriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                  constant: -UX.containerViewBottomPadding),

            logoImageView.widthAnchor.constraint(equalToConstant: UX.logoSize),
            logoImageView.heightAnchor.constraint(equalToConstant: UX.logoSize),
            logoImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: UX.subViewsSidePadding),
            logoImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            brandLabel.topAnchor.constraint(equalTo: containerView.topAnchor,
                                            constant: UX.subViewsSidePadding),
            brandLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                               constant: -UX.subViewsSidePadding),
            brandLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor,
                                                constant: UX.brandLabelLeadingPadding),
            brandLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                 constant: -UX.subViewsSidePadding),
        ])

        containerView.layoutIfNeeded()
        containerView.layer.cornerRadius = containerView.bounds.height / 2
    }

    func configure(text: String, textA11yId: String, logo: UIImage?, logoA11yId: String) {
        brandLabel.text = text
        brandLabel.accessibilityIdentifier = textA11yId
        logoImageView.image = logo
        logoImageView.accessibilityIdentifier = logoA11yId
        setNeedsLayout()
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        containerView.backgroundColor = theme.colors.actionSecondaryDisabled
        brandLabel.textColor = theme.colors.textSecondary
        backgroundColor = .clear
    }
}
