// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
import UIKit

struct JumpBackInCellViewModel {
    let titleText: String
    let descriptionText: String
    var favIconImage: UIImage?
    var heroImage: UIImage?
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
        static let titleFontSize: CGFloat = 15
        static let siteFontSize: CGFloat = 12
        static let heroImageSize =  CGSize(width: 108, height: 80)
        static let fallbackFaviconSize = CGSize(width: 36, height: 36)
        static let websiteImageSize = CGSize(width: 24, height: 24)
    }

    // MARK: - Variables
    var notificationCenter: NotificationProtocol = NotificationCenter.default
    private var websiteIconFirstBaselineConstraint: NSLayoutConstraint?
    private var websiteIconCenterConstraint: NSLayoutConstraint?

    // MARK: - UI Elements

    // contains tabImageContainer and tabContentContainer
    private let tabStack: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.spacing = 16
        stackView.axis = .horizontal
        stackView.alignment = .leading
    }

    // Contains the tabHeroImage and tabFallbackFaviconImage
    private var tabImageContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    let tabHeroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
        imageView.backgroundColor = .clear
    }

    // Used as a fallback if hero image isn't set
    private let tabFallbackFaviconImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = HomepageViewModel.UX.generalIconCornerRadius
        imageView.layer.masksToBounds = true
    }

    private var tabFallbackFaviconBackground: UIView = .build { view in
        view.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
        view.layer.borderWidth = HomepageViewModel.UX.generalBorderWidth
    }

    // contains tabItemTitle and websiteContainer
    private let tabContentContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private let tabItemTitle: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                   size: UX.titleFontSize)
        label.numberOfLines = 2
    }

    // Contains the websiteImage and websiteLabel
    private var websiteContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private let websiteImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
    }

    private var websiteLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .caption1,
                                                                       size: UX.siteFontSize)
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
        tabHeroImage.image = nil
        websiteImage.image = nil
        tabFallbackFaviconImage.image = nil
        websiteLabel.text = nil
        tabItemTitle.text = nil
        setFallBackFaviconVisibility(isHidden: false)

        websiteImage.isHidden = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                    cornerRadius: HomepageViewModel.UX.generalCornerRadius).cgPath
    }

    // MARK: - Helpers

    func configure(viewModel: JumpBackInCellViewModel, theme: Theme) {
        configureImages(viewModel: viewModel)

        tabItemTitle.text = viewModel.titleText
        websiteLabel.text = viewModel.descriptionText
        accessibilityLabel = viewModel.accessibilityLabel
        adjustLayout()

        applyTheme(theme: theme)
    }

    private func configureImages(viewModel: JumpBackInCellViewModel) {
        if viewModel.heroImage == nil {
            // Sets a small favicon in place of the hero image in case there's no hero image
            tabFallbackFaviconImage.image = viewModel.favIconImage

        } else if viewModel.heroImage?.size.width == viewModel.heroImage?.size.height {
            // If hero image is a square use it as a favicon
            tabFallbackFaviconImage.image = viewModel.heroImage

        } else {
            setFallBackFaviconVisibility(isHidden: true)
            tabHeroImage.image = viewModel.heroImage
        }

        websiteImage.image = viewModel.favIconImage
    }

    private func setFallBackFaviconVisibility(isHidden: Bool) {
        tabFallbackFaviconBackground.isHidden = isHidden
        tabFallbackFaviconImage.isHidden = isHidden
    }

    private func setupLayout() {
        tabFallbackFaviconBackground.addSubviews(tabFallbackFaviconImage)
        tabImageContainer.addSubviews(tabHeroImage, tabFallbackFaviconBackground)
        websiteContainer.addSubviews(websiteImage, websiteLabel)
        tabContentContainer.addSubviews(tabItemTitle, websiteContainer)
        tabStack.addArrangedSubview(tabImageContainer)
        tabStack.addArrangedSubview(tabContentContainer)

        contentView.addSubview(tabStack)

        NSLayoutConstraint.activate([
            tabStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            tabStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tabStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tabStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            tabItemTitle.leadingAnchor.constraint(equalTo: tabContentContainer.leadingAnchor),
            tabItemTitle.trailingAnchor.constraint(equalTo: tabContentContainer.trailingAnchor),
            tabItemTitle.topAnchor.constraint(equalTo: tabContentContainer.topAnchor),

            // Image container, hero image and fallback
            tabImageContainer.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            tabImageContainer.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),

            tabHeroImage.topAnchor.constraint(equalTo: tabImageContainer.topAnchor),
            tabHeroImage.leadingAnchor.constraint(equalTo: tabImageContainer.leadingAnchor),
            tabHeroImage.trailingAnchor.constraint(equalTo: tabImageContainer.trailingAnchor),
            tabHeroImage.bottomAnchor.constraint(equalTo: tabImageContainer.bottomAnchor),

            tabFallbackFaviconBackground.centerXAnchor.constraint(equalTo: tabImageContainer.centerXAnchor),
            tabFallbackFaviconBackground.centerYAnchor.constraint(equalTo: tabImageContainer.centerYAnchor),
            tabFallbackFaviconBackground.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            tabFallbackFaviconBackground.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),

            tabFallbackFaviconImage.heightAnchor.constraint(equalToConstant: UX.fallbackFaviconSize.height),
            tabFallbackFaviconImage.widthAnchor.constraint(equalToConstant: UX.fallbackFaviconSize.width),
            tabFallbackFaviconImage.centerXAnchor.constraint(equalTo: tabFallbackFaviconBackground.centerXAnchor),
            tabFallbackFaviconImage.centerYAnchor.constraint(equalTo: tabFallbackFaviconBackground.centerYAnchor),

            websiteImage.topAnchor.constraint(equalTo: websiteContainer.topAnchor),
            websiteImage.leadingAnchor.constraint(equalTo: websiteContainer.leadingAnchor),
            websiteImage.bottomAnchor.constraint(lessThanOrEqualTo: websiteContainer.bottomAnchor),

            websiteLabel.topAnchor.constraint(equalTo: websiteContainer.firstBaselineAnchor),
            websiteLabel.leadingAnchor.constraint(equalTo: websiteImage.trailingAnchor, constant: 8),
            websiteLabel.trailingAnchor.constraint(equalTo: websiteContainer.trailingAnchor),
            websiteLabel.bottomAnchor.constraint(equalTo: websiteContainer.bottomAnchor),

            // Website container, it's image and label
            websiteContainer.topAnchor.constraint(greaterThanOrEqualTo: tabItemTitle.bottomAnchor, constant: 8),
            websiteContainer.leadingAnchor.constraint(equalTo: tabContentContainer.leadingAnchor),
            websiteContainer.trailingAnchor.constraint(equalTo: tabContentContainer.trailingAnchor),
            websiteContainer.bottomAnchor.constraint(equalTo: tabContentContainer.bottomAnchor),

            websiteImage.heightAnchor.constraint(equalToConstant: UX.websiteImageSize.height),
            websiteImage.widthAnchor.constraint(equalToConstant: UX.websiteImageSize.width),

            tabContentContainer.heightAnchor.constraint(greaterThanOrEqualTo: tabImageContainer.heightAnchor)
        ])

        websiteIconCenterConstraint = websiteLabel.centerYAnchor.constraint(equalTo: websiteImage.centerYAnchor).priority(UILayoutPriority(999))
        websiteIconFirstBaselineConstraint = websiteLabel.firstBaselineAnchor.constraint(
            equalTo: websiteImage.bottomAnchor,
            constant: -UX.websiteImageSize.height / 2)

        websiteLabel.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .vertical)

        adjustLayout()
    }

    private func adjustLayout() {
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory

        if contentSizeCategory.isAccessibilityCategory {
            tabStack.axis = .vertical
        } else {
            tabStack.axis = .horizontal
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
        tabItemTitle.textColor = theme.colors.textPrimary
        websiteLabel.textColor = theme.colors.textSecondary
        websiteImage.tintColor = theme.colors.iconPrimary
        tabFallbackFaviconImage.tintColor = theme.colors.iconPrimary
        tabFallbackFaviconBackground.backgroundColor = theme.colors.layer1
        tabFallbackFaviconBackground.layer.borderColor = theme.colors.layer1.cgColor
        adjustBlur(theme: theme)
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
