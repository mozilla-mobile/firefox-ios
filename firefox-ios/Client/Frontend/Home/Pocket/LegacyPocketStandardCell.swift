// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import SiteImageView

// MARK: - LegacyPocketStandardCell
/// A cell used in FxHomeScreen's Pocket section
class LegacyPocketStandardCell: UICollectionViewCell, ReusableCell {
    struct UX {
        static let cellHeight: CGFloat = 112
        static let cellWidth: CGFloat = 350
        static let interItemSpacing = NSCollectionLayoutSpacing.fixed(8)
        static let interGroupSpacing: CGFloat = 8
        static let generalCornerRadius: CGFloat = 12
        static let horizontalMargin: CGFloat = 16
        static let heroImageSize =  CGSize(width: 108, height: 80)
        static let sponsoredIconSize = CGSize(width: 16, height: 16)
        static let sponsoredStackSpacing: CGFloat = 4
    }

    // MARK: - UI Elements
    private var heroImageView: HeroImageView = .build { _ in }

    private lazy var titleLabel: UILabel = .build { title in
        title.adjustsFontForContentSizeCategory = true
        title.font = FXFontStyles.Regular.subheadline.scaledFont()
        title.numberOfLines = 2
    }

    private lazy var bottomTextStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.sponsoredStackSpacing
        stackView.alignment = .fill
        stackView.distribution = .fill
    }

    private lazy var sponsoredStack: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.spacing = UX.sponsoredStackSpacing
        stackView.alignment = .center
        stackView.distribution = .fill
    }

    private lazy var sponsoredLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.text = .FirefoxHomepage.Pocket.Sponsored
    }

    private lazy var sponsoredIcon: UIImageView = .build { image in
        image.image = UIImage(named: StandardImageIdentifiers.Small.sponsoredStar)?.withRenderingMode(.alwaysTemplate)
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.caption1.scaledFont()
    }

    // MARK: - Variables
    private var sponsoredImageCenterConstraint: NSLayoutConstraint?
    private var sponsoredImageFirstBaselineConstraint: NSLayoutConstraint?

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

    override func prepareForReuse() {
        super.prepareForReuse()
        descriptionLabel.text = nil
        titleLabel.text = nil
    }

    // MARK: - Helpers

    func configure(viewModel: PocketStandardCellViewModel, theme: Theme) {
        titleLabel.text = viewModel.title
        descriptionLabel.text = viewModel.description
        accessibilityLabel = viewModel.accessibilityLabel

        let heroImageViewModel = HomepageHeroImageViewModel(urlStringRequest: viewModel.imageURL.absoluteString,
                                                            heroImageSize: UX.heroImageSize)
        heroImageView.setHeroImage(heroImageViewModel)
        sponsoredStack.isHidden = viewModel.shouldHideSponsor
        descriptionLabel.font = viewModel.shouldHideSponsor
        ? FXFontStyles.Regular.caption1.scaledFont()
        : FXFontStyles.Bold.caption1.scaledFont()

        adjustLayout()
        applyTheme(theme: theme)
    }

    private func setupLayout() {
        contentView.addSubviews(titleLabel, heroImageView)
        sponsoredStack.addArrangedSubview(sponsoredIcon)
        sponsoredStack.addArrangedSubview(sponsoredLabel)
        bottomTextStackView.addArrangedSubview(sponsoredStack)
        bottomTextStackView.addArrangedSubview(descriptionLabel)
        contentView.addSubview(bottomTextStackView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.horizontalMargin),
            titleLabel.leadingAnchor.constraint(equalTo: heroImageView.trailingAnchor,
                                                constant: UX.horizontalMargin),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                 constant: -UX.horizontalMargin),

            heroImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                   constant: UX.horizontalMargin),
            heroImageView.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            heroImageView.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),
            heroImageView.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            heroImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor,
                                                  constant: -UX.horizontalMargin),

            // Sponsored
            bottomTextStackView.topAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor, constant: 8),
            bottomTextStackView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bottomTextStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                          constant: -UX.horizontalMargin),
            bottomTextStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                        constant: -UX.horizontalMargin),

            sponsoredIcon.heightAnchor.constraint(equalToConstant: UX.sponsoredIconSize.height),
            sponsoredIcon.widthAnchor.constraint(equalToConstant: UX.sponsoredIconSize.width),
        ])
    }

    private func adjustLayout() {
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory

        // Center favicon on smaller font sizes. On bigger font sizes align with first baseline
        sponsoredImageCenterConstraint?.isActive = !contentSizeCategory.isAccessibilityCategory
        sponsoredImageFirstBaselineConstraint?.isActive = contentSizeCategory.isAccessibilityCategory
    }

    private func setupShadow(theme: Theme) {
        contentView.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
        contentView.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                    cornerRadius: HomepageViewModel.UX.generalCornerRadius).cgPath
        contentView.layer.shadowRadius = HomepageViewModel.UX.shadowRadius
        contentView.layer.shadowOffset = HomepageViewModel.UX.shadowOffset
        contentView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        contentView.layer.shadowOpacity = HomepageViewModel.UX.shadowOpacity
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                    cornerRadius: HomepageViewModel.UX.generalCornerRadius).cgPath
    }
}

// MARK: - Blurrable
extension LegacyPocketStandardCell: Blurrable {
    func adjustBlur(theme: Theme) {
        // Add blur
        if shouldApplyWallpaperBlur {
            contentView.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
            contentView.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
        } else {
            contentView.removeVisualEffectView()
            contentView.backgroundColor = theme.colors.layer5
            setupShadow(theme: theme)
        }
    }
}

// MARK: - ThemeApplicable
extension LegacyPocketStandardCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textSecondary
        sponsoredLabel.textColor = theme.colors.textSecondary
        sponsoredIcon.tintColor = theme.colors.iconSecondary

        adjustBlur(theme: theme)
    }
}
