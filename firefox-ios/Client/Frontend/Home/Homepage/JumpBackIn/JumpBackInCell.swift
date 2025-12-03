// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SiteImageView

@MainActor
protocol JumpBackInCellProtocol: ReusableCell {
    func configure(config: JumpBackInTabConfiguration, theme: Theme)
}

/// A cell used in Home page Jump Back In section
final class JumpBackInCell: UICollectionViewCell,
                            JumpBackInCellProtocol,
                            ThemeApplicable,
                            Blurrable {
    struct UX {
        static let generalCornerRadius: CGFloat = 16
        static let cellSpacing: CGFloat = 16
        static let heroImageInsets: CGFloat = 4
        static let heroImageSize =  CGSize(width: 108, height: 80)
        static let fallbackFaviconSize = CGSize(width: 36, height: 36)
        static let websiteIconSize = CGSize(width: 16, height: 16)
        static let contentSpacing: CGFloat = 12
        static let heroImageCornerRadius: CGFloat = 13
    }

    // MARK: - Variables
    var notificationCenter: NotificationProtocol = NotificationCenter.default
    private var websiteIconFirstBaselineConstraint: NSLayoutConstraint?
    private var websiteIconCenterConstraint: NSLayoutConstraint?

    // MARK: - UI Elements

    private let imageContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private let heroImage: HeroImageView = .build()

    private let textContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private let itemTitle: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private let websiteContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private let websiteImage: FaviconImageView = .build()

    private let websiteLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.font = FXFontStyles.Regular.caption2.scaledFont()
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.JumpBackIn.itemCell

        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        websiteLabel.text = nil
        itemTitle.text = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.layer.shadowPath = UIBezierPath(
            roundedRect: contentView.bounds,
            cornerRadius: UX.generalCornerRadius
        ).cgPath
    }

    // MARK: - Helpers

    func configure(config: JumpBackInTabConfiguration, theme: Theme) {
        let heroImageViewModel = HomepageHeroImageViewModel(urlStringRequest: config.siteURL,
                                                            generalCornerRadius: UX.heroImageCornerRadius,
                                                            heroImageSize: UX.heroImageSize)
        heroImage.setHeroImage(heroImageViewModel)

        let faviconViewModel = FaviconImageViewModel(siteURLString: config.siteURL)
        websiteImage.setFavicon(faviconViewModel)

        itemTitle.text = config.titleText
        websiteLabel.text = config.descriptionText
        accessibilityLabel = config.accessibilityLabel

        applyTheme(theme: theme)
    }

    private func setupLayout() {
        contentView.addSubview(imageContainer)
        contentView.addSubview(textContainer)

        imageContainer.addSubview(heroImage)

        textContainer.addSubview(itemTitle)
        textContainer.addSubview(websiteContainer)

        websiteContainer.addSubview(websiteImage)
        websiteContainer.addSubview(websiteLabel)

        NSLayoutConstraint.activate([
            imageContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.heroImageInsets),
            imageContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.heroImageInsets),
            imageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.heroImageInsets),
            imageContainer.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),

            heroImage.topAnchor.constraint(greaterThanOrEqualTo: imageContainer.topAnchor),
            heroImage.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            heroImage.bottomAnchor.constraint(lessThanOrEqualTo: imageContainer.bottomAnchor),
            heroImage.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),
            heroImage.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),

            textContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            textContainer.leadingAnchor.constraint(equalTo: imageContainer.trailingAnchor, constant: UX.contentSpacing),
            textContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            itemTitle.topAnchor.constraint(equalTo: textContainer.topAnchor),
            itemTitle.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor),
            itemTitle.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor),

            websiteContainer.topAnchor.constraint(greaterThanOrEqualTo: itemTitle.bottomAnchor, constant: 16),
            websiteContainer.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor),
            websiteContainer.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor),
            websiteContainer.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor),

            websiteImage.centerYAnchor.constraint(equalTo: websiteLabel.centerYAnchor),
            websiteImage.leadingAnchor.constraint(equalTo: websiteContainer.leadingAnchor),
            websiteImage.widthAnchor.constraint(equalToConstant: UX.websiteIconSize.width),
            websiteImage.heightAnchor.constraint(equalToConstant: UX.websiteIconSize.height),

            websiteLabel.topAnchor.constraint(equalTo: websiteContainer.topAnchor),
            websiteLabel.leadingAnchor.constraint(equalTo: websiteImage.trailingAnchor, constant: 8),
            websiteLabel.trailingAnchor.constraint(equalTo: websiteContainer.trailingAnchor),
            websiteLabel.bottomAnchor.constraint(equalTo: websiteContainer.bottomAnchor),
        ])

        let heroImageCenterY = heroImage.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor)
        heroImageCenterY.priority = .defaultLow
        heroImageCenterY.isActive = true

        let preferredContentSpacing = websiteContainer.topAnchor.constraint(equalTo: itemTitle.bottomAnchor, constant: 16)
        preferredContentSpacing.priority = .defaultLow
        preferredContentSpacing.isActive = true
    }

    private func setupShadow(theme: Theme) {
        contentView.layer.cornerRadius = UX.generalCornerRadius
        contentView.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                    cornerRadius: UX.generalCornerRadius).cgPath
        contentView.layer.shadowRadius = HomepageUX.shadowRadius
        contentView.layer.shadowOffset = HomepageUX.shadowOffset
        contentView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        contentView.layer.shadowOpacity = HomepageUX.shadowOpacity
    }

    // MARK: - Blurrable
    func adjustBlur(theme: Theme) {
        if shouldApplyWallpaperBlur {
            contentView.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
            contentView.layer.cornerRadius = UX.generalCornerRadius
        } else {
            contentView.removeVisualEffectView()
            contentView.backgroundColor = theme.colors.layer5
            setupShadow(theme: theme)
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        itemTitle.textColor = theme.colors.textPrimary
        websiteLabel.textColor = theme.colors.textSecondary
        adjustBlur(theme: theme)
        let heroImageColors = HeroImageViewColor(faviconTintColor: theme.colors.iconPrimary,
                                                 faviconBackgroundColor: theme.colors.layer1,
                                                 faviconBorderColor: theme.colors.layer1)
        heroImage.updateHeroImageTheme(with: heroImageColors)
    }
}
