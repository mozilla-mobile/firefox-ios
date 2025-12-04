// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import SiteImageView

@MainActor
protocol BookmarksCellProtocol: ReusableCell where Self: UIView {
    func configure(config: BookmarkConfiguration, theme: Theme)
}

/// A cell used in homepage's Bookmarks section.
final class BookmarksCell: UICollectionViewCell, BookmarksCellProtocol, ThemeApplicable, Blurrable {
    private struct UX {
        static let containerSpacing: CGFloat = 4
        static let heroImageSize = CGSize(width: 126, height: 68)
        static let generalSpacing: CGFloat = 8
        static let contentSpacing: CGFloat = 4
        static let generalCornerRadius: CGFloat = 16
        static let heroImageCornerRadius: CGFloat = 13
    }

    // MARK: - UI Elements
    private var rootContainer: UIView = .build { view in
        view.backgroundColor = .clear
        view.layer.cornerRadius = UX.generalCornerRadius
    }

    private var heroImageView: HeroImageView = .build { _ in }

    let titleContainer: UIView = .build()

    let itemTitle: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
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
        contentView.layer.shadowPath = UIBezierPath(
            roundedRect: contentView.bounds,
            cornerRadius: UX.generalCornerRadius).cgPath
    }

    func configure(config: BookmarkConfiguration, theme: Theme) {
        let heroImageViewModel = HomepageHeroImageViewModel(
            urlStringRequest: config.site.url,
            generalCornerRadius: UX.heroImageCornerRadius,
            heroImageSize: UX.heroImageSize
        )
        heroImageView.setHeroImage(heroImageViewModel)
        itemTitle.text = config.site.title
        accessibilityLabel = config.accessibilityLabel
        applyTheme(theme: theme)
    }

    // MARK: - Helpers

    private func setupLayout() {
        contentView.backgroundColor = .clear
        titleContainer.addSubview(itemTitle)
        rootContainer.addSubviews(heroImageView, titleContainer)
        contentView.addSubview(rootContainer)

        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rootContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rootContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            heroImageView.topAnchor.constraint(equalTo: rootContainer.topAnchor, constant: UX.containerSpacing),
            heroImageView.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor, constant: UX.containerSpacing),
            heroImageView.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor, constant: -UX.containerSpacing),
            heroImageView.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            heroImageView.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),

            titleContainer.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: UX.contentSpacing),
            titleContainer.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor, constant: UX.generalSpacing),
            titleContainer.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor, constant: -UX.generalSpacing),
            titleContainer.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor, constant: -UX.generalSpacing),

            itemTitle.topAnchor.constraint(equalTo: titleContainer.topAnchor),
            itemTitle.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
            itemTitle.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor),
            itemTitle.bottomAnchor.constraint(lessThanOrEqualTo: titleContainer.bottomAnchor)
        ])
    }

    private func setupShadow(theme: Theme) {
        contentView.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                    cornerRadius: UX.generalCornerRadius).cgPath

        contentView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        contentView.layer.shadowOpacity = HomepageUX.shadowOpacity
        contentView.layer.shadowOffset = HomepageUX.shadowOffset
        contentView.layer.shadowRadius = HomepageUX.shadowRadius
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        itemTitle.textColor = theme.colors.textPrimary
        let heroImageColors = HeroImageViewColor(faviconTintColor: theme.colors.iconPrimary,
                                                 faviconBackgroundColor: theme.colors.layer1,
                                                 faviconBorderColor: theme.colors.layer1)
        heroImageView.updateHeroImageTheme(with: heroImageColors)

        adjustBlur(theme: theme)
    }

    // MARK: - Blurrable
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
