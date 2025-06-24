// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import SiteImageView

/// The standard cell used in homepage pocket section
class StoryCell: UICollectionViewCell, ReusableCell, ThemeApplicable, Blurrable {
    struct UX {
        static let cellCornerRadius: CGFloat = 16
        static let thumbnailImageSize = CGSize(width: 62, height: 62)
        static let thumbnailCornerRadius: CGFloat = 12
        static let thumbnailVerticalMargin: CGFloat = 4
        static let descriptionVerticalMargin: CGFloat = 8
        static let descriptionLeadingSpacing: CGFloat = 12
        static let descriptionTrailingMargin: CGFloat = 8
        static let horizontalMargin: CGFloat = 4
    }

    // MARK: - UI Elements
    private var thumbnailImageView: HeroImageView = .build { _ in }

    private lazy var titleLabel: UILabel = .build { title in
        title.adjustsFontForContentSizeCategory = true
        title.font = FXFontStyles.Regular.footnote.scaledFont()
        title.numberOfLines = 2
    }

    private lazy var sponsoredLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.caption2.scaledFont()
        label.text = .FirefoxHomepage.Pocket.Sponsored
    }

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.Pocket.itemCell

        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                    cornerRadius: UX.cellCornerRadius).cgPath
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        accessibilityLabel = nil
    }

    // MARK: - Helpers

    func configure(story: PocketStoryConfiguration, theme: Theme) {
        titleLabel.text = story.title
        accessibilityLabel = story.accessibilityLabel

        let heroImageViewModel = HomepageHeroImageViewModel(urlStringRequest: story.imageURL.absoluteString,
                                                            generalCornerRadius: UX.thumbnailCornerRadius,
                                                            faviconCornerRadius: UX.thumbnailCornerRadius,
                                                            heroImageSize: UX.thumbnailImageSize)
        thumbnailImageView.setHeroImage(heroImageViewModel)
        sponsoredLabel.isHidden = story.shouldHideSponsor

        applyTheme(theme: theme)
    }

    private func setupLayout() {
        contentView.layer.cornerRadius = UX.cellCornerRadius

        contentView.addSubviews(thumbnailImageView, titleLabel, sponsoredLabel)

        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.horizontalMargin),
            thumbnailImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: UX.thumbnailImageSize.width),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: UX.thumbnailImageSize.height),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.descriptionVerticalMargin),
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor,
                                                constant: UX.descriptionLeadingSpacing),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                 constant: -UX.descriptionTrailingMargin),

            sponsoredLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor,
                                                    constant: UX.descriptionLeadingSpacing),
            sponsoredLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                     constant: -UX.descriptionTrailingMargin),
            sponsoredLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                   constant: -UX.descriptionVerticalMargin)
        ])
    }

    private func setupShadow(theme: Theme) {
        contentView.layer.shadowRadius = HomepageViewModel.UX.shadowRadius
        contentView.layer.shadowOffset = HomepageViewModel.UX.shadowOffset
        contentView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        contentView.layer.shadowOpacity = HomepageViewModel.UX.shadowOpacity
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        sponsoredLabel.textColor = theme.colors.textPrimary

        adjustBlur(theme: theme)
    }

    // MARK: - Blurrable
    func adjustBlur(theme: Theme) {
        // Add blur
        if shouldApplyWallpaperBlur {
            contentView.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
            contentView.layer.cornerRadius = UX.cellCornerRadius
        } else {
            contentView.removeVisualEffectView()
            contentView.backgroundColor = theme.colors.layer5
            setupShadow(theme: theme)
        }
    }
}
