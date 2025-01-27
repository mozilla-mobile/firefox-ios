// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import SiteImageView
import Shared

/// A cell used in FxHomeScreen's Bookmarks section.
class BookmarksCell: UICollectionViewCell, ReusableCell {
    private struct UX {
        static let containerSpacing: CGFloat = 16
        static let heroImageSize = CGSize(width: 126, height: 82)
        static let generalSpacing: CGFloat = 8
    }

    // MARK: - UI Elements
    private var rootContainer: UIView = .build { view in
        view.backgroundColor = .clear
        view.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
    }

    private var heroImageView: HeroImageView = .build { _ in }

    let itemTitle: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.adjustsFontForContentSizeCategory = true
    }

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.Bookmarks.itemCell

        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        itemTitle.text = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        rootContainer.layer.shadowPath = UIBezierPath(roundedRect: rootContainer.bounds,
                                                      cornerRadius: HomepageViewModel.UX.generalCornerRadius).cgPath
    }

    func configure(viewModel: BookmarksCellViewModel, theme: Theme) {
        let heroImageViewModel = HomepageHeroImageViewModel(urlStringRequest: viewModel.site.url,
                                                            heroImageSize: UX.heroImageSize)
        heroImageView.setHeroImage(heroImageViewModel)
        itemTitle.text = viewModel.site.title
        accessibilityLabel = viewModel.accessibilityLabel
        applyTheme(theme: theme)
    }

    // MARK: - Helpers

    private func setupLayout() {
        contentView.backgroundColor = .clear
        rootContainer.addSubviews(heroImageView, itemTitle)
        contentView.addSubview(rootContainer)

        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rootContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rootContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            heroImageView.topAnchor.constraint(equalTo: rootContainer.topAnchor,
                                               constant: UX.containerSpacing),
            heroImageView.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor,
                                                   constant: UX.containerSpacing),
            heroImageView.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor,
                                                    constant: -UX.containerSpacing),
            heroImageView.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            heroImageView.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),

            itemTitle.topAnchor.constraint(equalTo: heroImageView.bottomAnchor,
                                           constant: UX.generalSpacing),
            itemTitle.leadingAnchor.constraint(equalTo: heroImageView.leadingAnchor),
            itemTitle.trailingAnchor.constraint(equalTo: heroImageView.trailingAnchor),
            itemTitle.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor,
                                              constant: -UX.generalSpacing),
        ])
    }

    private func setupShadow(theme: Theme) {
        rootContainer.layer.shadowPath = UIBezierPath(roundedRect: rootContainer.bounds,
                                                      cornerRadius: HomepageViewModel.UX.generalCornerRadius).cgPath

        rootContainer.layer.shadowColor = theme.colors.shadowDefault.cgColor
        rootContainer.layer.shadowOpacity = HomepageViewModel.UX.shadowOpacity
        rootContainer.layer.shadowOffset = HomepageViewModel.UX.shadowOffset
        rootContainer.layer.shadowRadius = HomepageViewModel.UX.shadowRadius
    }
}

// MARK: - ThemeApplicable
extension BookmarksCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        itemTitle.textColor = theme.colors.textPrimary
        let heroImageColors = HeroImageViewColor(faviconTintColor: theme.colors.iconPrimary,
                                                 faviconBackgroundColor: theme.colors.layer1,
                                                 faviconBorderColor: theme.colors.layer1)
        heroImageView.updateHeroImageTheme(with: heroImageColors)

        adjustBlur(theme: theme)
    }
}

// MARK: - Blurrable
extension BookmarksCell: Blurrable {
    func adjustBlur(theme: Theme) {
        // If blur is disabled set background color
        if shouldApplyWallpaperBlur {
            rootContainer.layoutIfNeeded()
            rootContainer.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            rootContainer.removeVisualEffectView()
            rootContainer.backgroundColor = theme.colors.layer5
            setupShadow(theme: theme)
        }
    }
}
