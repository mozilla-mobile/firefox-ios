// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SiteImageView
import UIKit

class InactiveTabsCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    struct UX {
        static let imageSize: CGFloat = 28
        static let labelTopBottomMargin: CGFloat = 11
        static let titleFontSize: CGFloat = 14
        static let imageViewLeadingConstant: CGFloat = 16
        static let separatorHeight: CGFloat = 0.5
    }

    private lazy var selectedView: UIView = .build { _ in }
    private lazy var leftImageView: FaviconImageView = .build { _ in }
    private lazy var bottomSeparatorView: UIView = .build { _ in }
    private lazy var containerView: UIView = .build { _ in }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .caption1,
            size: UX.titleFontSize)
        label.textAlignment = .natural
        label.contentMode = .center
    }

    func configure(text: String) {
        setupView()

        titleLabel.text = text
        leftImageView.image = UIImage(systemName: "globe")
    }

    func applyTheme(theme: Theme) {
        containerView.backgroundColor = theme.colors.layer2
        titleLabel.textColor = theme.colors.textPrimary
        backgroundColor = theme.colors.layer2
        bottomSeparatorView.backgroundColor = theme.colors.borderPrimary
        selectedView.backgroundColor = .green
    }

    private func setupView() {
        containerView.addSubviews(titleLabel)
        containerView.addSubviews(bottomSeparatorView)
        containerView.addSubview(leftImageView)

        contentView.addSubview(containerView)
        bringSubviewToFront(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            leftImageView.heightAnchor.constraint(equalToConstant: UX.imageSize),
            leftImageView.widthAnchor.constraint(equalToConstant: UX.imageSize),
            leftImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                   constant: UX.imageViewLeadingConstant),
            leftImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            leftImageView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor,
                                                    constant: -UX.imageViewLeadingConstant),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor,
                                            constant: UX.labelTopBottomMargin),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                               constant: -UX.labelTopBottomMargin),

            bottomSeparatorView.heightAnchor.constraint(equalToConstant: UX.separatorHeight),
            bottomSeparatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            bottomSeparatorView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bottomSeparatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])

        leftImageView.setContentHuggingPriority(.required, for: .vertical)
        selectedBackgroundView = selectedView
    }
}
