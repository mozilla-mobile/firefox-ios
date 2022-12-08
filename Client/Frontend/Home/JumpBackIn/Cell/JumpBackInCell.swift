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
        static let cellSpacing: CGFloat = 16
        static let titleFontSize: CGFloat = 15
        static let siteFontSize: CGFloat = 12
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

    let heroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
        imageView.backgroundColor = .clear
    }

    // Used as a fallback if hero image isn't set
    private let fallbackFaviconImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = HomepageViewModel.UX.generalIconCornerRadius
        imageView.layer.masksToBounds = true
    }

    private var fallbackFaviconBackground: UIView = .build { view in
        view.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
        view.layer.borderWidth = HomepageViewModel.UX.generalBorderWidth
    }

    // contains itemTitle and websiteContainer
    private let textContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private let itemTitle: UILabel = .build { label in
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
        heroImage.image = nil
        websiteImage.image = nil
        fallbackFaviconImage.image = nil
        websiteLabel.text = nil
        itemTitle.text = nil
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

        itemTitle.text = viewModel.titleText
        websiteLabel.text = viewModel.descriptionText
        accessibilityLabel = viewModel.accessibilityLabel
        adjustLayout()

        applyTheme(theme: theme)
    }

    private func configureImages(viewModel: JumpBackInCellViewModel) {
        if viewModel.heroImage == nil {
            // Sets a small favicon in place of the hero image in case there's no hero image
            fallbackFaviconImage.image = viewModel.favIconImage
        } else if viewModel.heroImage?.size.width == viewModel.heroImage?.size.height {
            // If hero image is a square use it as a favicon
            fallbackFaviconImage.image = viewModel.heroImage
        } else {
            setFallBackFaviconVisibility(isHidden: true)
            heroImage.image = viewModel.heroImage
        }

        websiteImage.image = viewModel.favIconImage
    }

    private func setFallBackFaviconVisibility(isHidden: Bool) {
        fallbackFaviconBackground.isHidden = isHidden
        fallbackFaviconImage.isHidden = isHidden
    }

    private func setupLayout() {
        fallbackFaviconBackground.addSubviews(fallbackFaviconImage)
        imageContainer.addSubviews(heroImage, fallbackFaviconBackground)
        websiteContainer.addSubviews(websiteImage, websiteLabel)
        textContainer.addSubviews(itemTitle, websiteContainer)
        contentStack.addArrangedSubview(imageContainer)
        contentStack.addArrangedSubview(textContainer)

        contentView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.cellSpacing),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.cellSpacing),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.cellSpacing),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.cellSpacing),

            itemTitle.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor),
            itemTitle.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor),
            itemTitle.topAnchor.constraint(equalTo: textContainer.topAnchor),

            // Image container, hero image and fallback
            imageContainer.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            imageContainer.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),

            heroImage.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            heroImage.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            heroImage.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            heroImage.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),

            fallbackFaviconBackground.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            fallbackFaviconBackground.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
            fallbackFaviconBackground.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            fallbackFaviconBackground.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),

            fallbackFaviconImage.heightAnchor.constraint(equalToConstant: UX.fallbackFaviconSize.height),
            fallbackFaviconImage.widthAnchor.constraint(equalToConstant: UX.fallbackFaviconSize.width),
            fallbackFaviconImage.centerXAnchor.constraint(equalTo: fallbackFaviconBackground.centerXAnchor),
            fallbackFaviconImage.centerYAnchor.constraint(equalTo: fallbackFaviconBackground.centerYAnchor),

            websiteImage.topAnchor.constraint(equalTo: websiteContainer.topAnchor),
            websiteImage.leadingAnchor.constraint(equalTo: websiteContainer.leadingAnchor),
            websiteImage.bottomAnchor.constraint(lessThanOrEqualTo: websiteContainer.bottomAnchor),

            websiteLabel.topAnchor.constraint(equalTo: websiteContainer.firstBaselineAnchor),
            websiteLabel.leadingAnchor.constraint(equalTo: websiteImage.trailingAnchor, constant: 8),
            websiteLabel.trailingAnchor.constraint(equalTo: websiteContainer.trailingAnchor),
            websiteLabel.bottomAnchor.constraint(equalTo: websiteContainer.bottomAnchor),

            // Website container, it's image and label
            websiteContainer.topAnchor.constraint(greaterThanOrEqualTo: itemTitle.bottomAnchor, constant: 8),
            websiteContainer.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor),
            websiteContainer.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor),
            websiteContainer.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor),

            websiteImage.heightAnchor.constraint(equalToConstant: UX.websiteIconSize.height),
            websiteImage.widthAnchor.constraint(equalToConstant: UX.websiteIconSize.width),

            textContainer.heightAnchor.constraint(greaterThanOrEqualTo: imageContainer.heightAnchor)
        ])

        websiteIconCenterConstraint = websiteLabel.centerYAnchor.constraint(equalTo: websiteImage.centerYAnchor).priority(UILayoutPriority(999))
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
        websiteImage.tintColor = theme.colors.iconPrimary
        fallbackFaviconImage.tintColor = theme.colors.iconPrimary
        fallbackFaviconBackground.backgroundColor = theme.colors.layer1
        fallbackFaviconBackground.layer.borderColor = theme.colors.layer1.cgColor
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
