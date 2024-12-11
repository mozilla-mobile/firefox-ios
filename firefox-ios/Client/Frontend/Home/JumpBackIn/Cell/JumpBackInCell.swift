// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SiteImageView
import Common
import Shared

struct JumpBackInCellViewModel {
    let titleText: String
    let descriptionText: String
    let siteURL: String
    var accessibilityLabel: String {
        return "\(titleText), \(descriptionText)"
    }
}

// MARK: - JumpBackInCell
/// A cell used in Home page Jump Back In section
class JumpBackInCell: UICollectionViewCell, ReusableCell {
    struct UX {
        static let interItemSpacing = NSCollectionLayoutSpacing.fixed(8)
        static let interGroupSpacing: CGFloat = 8
        static let generalCornerRadius: CGFloat = 12
        static let cellSpacing: CGFloat = 16
        static let heroImageSize =  CGSize(width: 108, height: 80)
        static let fallbackFaviconSize = CGSize(width: 36, height: 36)
        static let websiteIconSize = CGSize(width: 24, height: 24)
    }

    // MARK: - Variables
    var notificationCenter: NotificationProtocol = NotificationCenter.default
    private var websiteIconFirstBaselineConstraint: NSLayoutConstraint?
    private var websiteIconCenterConstraint: NSLayoutConstraint?

    // MARK: - UI Elements

    // contains imageContainer and textContainer
    private let contentStack: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.spacing = 16
        stackView.axis = .horizontal
        stackView.alignment = .leading
    }

    // Contains the heroImage and fallbackFaviconImage
    private var imageContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private var heroImage: HeroImageView = .build { _ in }
    private let websiteImage: FaviconImageView = .build { _ in }

    // contains itemTitle and websiteContainer
    private let textContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private let itemTitle: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 2
    }

    // Contains the websiteImage and websiteLabel
    private var websiteContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private var websiteLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        label.font = FXFontStyles.Bold.caption1.scaledFont()
        label.textColor = .label
    }

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.JumpBackIn.itemCell

        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        websiteLabel.text = nil
        itemTitle.text = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                    cornerRadius: HomepageViewModel.UX.generalCornerRadius).cgPath
    }

    // MARK: - Helpers

    func configure(viewModel: JumpBackInCellViewModel, theme: Theme) {
        let heroImageViewModel = HomepageHeroImageViewModel(urlStringRequest: viewModel.siteURL,
                                                            heroImageSize: UX.heroImageSize)
        heroImage.setHeroImage(heroImageViewModel)

        let faviconViewModel = FaviconImageViewModel(siteURLString: viewModel.siteURL)
        websiteImage.setFavicon(faviconViewModel)

        itemTitle.text = viewModel.titleText
        websiteLabel.text = viewModel.descriptionText
        accessibilityLabel = viewModel.accessibilityLabel
        adjustLayout()

        applyTheme(theme: theme)
    }

    private func setupLayout() {
        imageContainer.addSubviews(heroImage)
        textContainer.addSubviews(itemTitle, websiteContainer)
        websiteContainer.addSubviews(websiteImage, websiteLabel)
        contentStack.addArrangedSubview(imageContainer)
        contentStack.addArrangedSubview(textContainer)
        contentView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.cellSpacing),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.cellSpacing),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.cellSpacing),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.cellSpacing),

            // Image container, hero image
            heroImage.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            heroImage.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),

            heroImage.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            heroImage.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            heroImage.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            heroImage.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),

            itemTitle.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor),
            itemTitle.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor),
            itemTitle.topAnchor.constraint(equalTo: textContainer.topAnchor),

            websiteLabel.topAnchor.constraint(equalTo: websiteContainer.firstBaselineAnchor),
            websiteLabel.leadingAnchor.constraint(equalTo: websiteImage.trailingAnchor, constant: 8),
            websiteLabel.trailingAnchor.constraint(equalTo: websiteContainer.trailingAnchor),
            websiteLabel.bottomAnchor.constraint(equalTo: websiteContainer.bottomAnchor, constant: -4),

            // Website container, it's image and label
            websiteContainer.topAnchor.constraint(greaterThanOrEqualTo: itemTitle.bottomAnchor, constant: 8),
            websiteContainer.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor),
            websiteContainer.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor),
            websiteContainer.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor),

            websiteImage.heightAnchor.constraint(equalToConstant: UX.websiteIconSize.height),
            websiteImage.widthAnchor.constraint(equalToConstant: UX.websiteIconSize.width),
            websiteImage.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor),

            textContainer.heightAnchor.constraint(greaterThanOrEqualTo: imageContainer.heightAnchor)
        ])

        websiteIconCenterConstraint = websiteLabel.centerYAnchor.constraint(
            equalTo: websiteImage.centerYAnchor
        ).priority(UILayoutPriority(999))
        websiteIconFirstBaselineConstraint = websiteLabel.firstBaselineAnchor.constraint(
            equalTo: websiteImage.bottomAnchor,
            constant: -UX.websiteIconSize.height / 2)

        websiteLabel.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .vertical)

        adjustLayout()
    }

    private func adjustLayout() {
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory

        if contentSizeCategory.isAccessibilityCategory {
            contentStack.axis = .vertical
        } else {
            contentStack.axis = .horizontal
        }

        // Center favicon on smaller font sizes. On bigger font sizes align with first baseline
        websiteIconCenterConstraint?.isActive = !contentSizeCategory.isAccessibilityCategory
        websiteIconFirstBaselineConstraint?.isActive = contentSizeCategory.isAccessibilityCategory
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
}

// MARK: - ThemeApplicable
extension JumpBackInCell: ThemeApplicable {
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

// MARK: - Blurrable
extension JumpBackInCell: Blurrable {
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

// MARK: - Notifiable
extension JumpBackInCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        ensureMainThread { [weak self] in
            switch notification.name {
            case .DynamicFontChanged:
                self?.adjustLayout()
            default: break
            }
        }
    }
}
