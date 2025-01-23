// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SiteImageView
import UIKit

class InactiveTabsCell: UICollectionViewListCell, ReusableCell, ThemeApplicable {
    struct UX {
        static let imageSize: CGFloat = 28
        static let labelTopBottomMargin: CGFloat = 11
        static let imageViewLeadingConstant: CGFloat = 16
        static let separatorHeight: CGFloat = 0.5
        static let faviconCornerRadius: CGFloat = 5
    }

    private lazy var selectedView: UIView = .build { _ in }
    private lazy var leftImageView: FaviconImageView = .build { _ in }
    private lazy var bottomSeparatorView: UIView = .build { _ in }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.InactiveTabs.cellLabel
        label.textAlignment = .natural
        label.contentMode = .center
    }

    func configure(with inactiveTabsModel: InactiveTabsModel) {
        setupView()

        titleLabel.text = inactiveTabsModel.title

        // FXIOS-9938 Right now, passing the faviconURL means each of these websites is caching favicon URLs and images based
        // on the full favicon URL path and not the short domain. This can be improved but will require some reworking.
        // For now, the consequence is that Inactive tab favicons have to be downloaded when viewed for the first time.
        var siteResource: SiteResource?
        if let faviconURLString = inactiveTabsModel.favIconURL,
           let faviconURL = URL(string: faviconURLString) {
            siteResource = .remoteURL(url: faviconURL)
        }
        leftImageView.setFavicon(FaviconImageViewModel(siteURLString: inactiveTabsModel.url?.absoluteString,
                                                       siteResource: siteResource,
                                                       faviconCornerRadius: InactiveTabsCell.UX.faviconCornerRadius))
    }

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer2
        contentView.backgroundColor = theme.colors.layer2
        titleLabel.textColor = theme.colors.textPrimary
        bottomSeparatorView.backgroundColor = theme.colors.borderPrimary
        selectedView.backgroundColor = .green
    }

    private func setupView() {
        contentView.addSubview(leftImageView)
        contentView.addSubviews(titleLabel)
        contentView.addSubview(bottomSeparatorView)

        NSLayoutConstraint.activate([
            leftImageView.heightAnchor.constraint(equalToConstant: UX.imageSize),
            leftImageView.widthAnchor.constraint(equalToConstant: UX.imageSize),
            leftImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                   constant: UX.imageViewLeadingConstant),
            leftImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            leftImageView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor,
                                                    constant: -UX.imageViewLeadingConstant),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor,
                                            constant: UX.labelTopBottomMargin),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                               constant: -UX.labelTopBottomMargin),

            bottomSeparatorView.heightAnchor.constraint(equalToConstant: UX.separatorHeight),
            bottomSeparatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomSeparatorView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bottomSeparatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])

        leftImageView.setContentHuggingPriority(.required, for: .vertical)
        selectedBackgroundView = selectedView
    }
}
