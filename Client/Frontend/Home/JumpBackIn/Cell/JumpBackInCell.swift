// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
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
class JumpBackInCell: BlurrableCollectionViewCell, ReusableCell {

    struct UX {
        static let interItemSpacing = NSCollectionLayoutSpacing.fixed(8)
        static let interGroupSpacing: CGFloat = 8
        static let generalCornerRadius: CGFloat = 12
        static let titleFontSize: CGFloat = 16
        static let siteFontSize: CGFloat = 12
        static let stackViewShadowRadius: CGFloat = 4
        static let stackViewShadowOffset: CGFloat = 2
        static let heroImageSize =  CGSize(width: 108, height: 80)
        static let fallbackFaviconSize = CGSize(width: 36, height: 36)
        static let faviconSize = CGSize(width: 24, height: 24)
    }

    private var faviconCenterConstraint: NSLayoutConstraint?
    private var faviconFirstBaselineConstraint: NSLayoutConstraint?

    // MARK: - UI Elements
    let heroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = UX.generalCornerRadius
        imageView.backgroundColor = .clear
    }

    private let itemTitle: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .headline,
                                                                   size: UX.titleFontSize)
        label.numberOfLines = 2
    }

    // Contains the faviconImage and descriptionLabel
    private var descriptionContainer: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.spacing = 8
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
    }

    let faviconImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = UX.generalCornerRadius
    }

    private let descriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1,
                                                                   size: UX.siteFontSize)
        label.textColor = .label
    }

    // Used as a fallback if hero image isn't set
    private let fallbackFaviconImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.clear
        imageView.layer.cornerRadius = TopSiteItemCell.UX.iconCornerRadius
        imageView.layer.masksToBounds = true
    }

    private var fallbackFaviconBackground: UIView = .build { view in
        view.layer.cornerRadius = TopSiteItemCell.UX.cellCornerRadius
        view.layer.borderWidth = TopSiteItemCell.UX.borderWidth
    }

    // Contains the hero image and fallback favicons
    private var imageContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    // MARK: - Variables
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.JumpBackIn.itemCell

        applyTheme()
        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged,
                                       .WallpaperDidChange])
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
        faviconImage.image = nil
        fallbackFaviconImage.image = nil
        descriptionLabel.text = nil
        itemTitle.text = nil
        setFallBackFaviconVisibility(isHidden: false)
        applyTheme()

        faviconImage.isHidden = false
        descriptionContainer.addArrangedViewToTop(faviconImage)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                    cornerRadius: UX.generalCornerRadius).cgPath
    }

    // MARK: - Helpers

    func configure(viewModel: JumpBackInCellViewModel) {
        configureImages(viewModel: viewModel)

        itemTitle.text = viewModel.titleText
        descriptionLabel.text = viewModel.descriptionText
        accessibilityLabel = viewModel.accessibilityLabel
        adjustLayout()
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

        faviconImage.image = viewModel.favIconImage
    }

    private func setFallBackFaviconVisibility(isHidden: Bool) {
        fallbackFaviconBackground.isHidden = isHidden
        fallbackFaviconImage.isHidden = isHidden
    }

    private func setupLayout() {
        setupShadow()

        fallbackFaviconBackground.addSubviews(fallbackFaviconImage)
        imageContainer.addSubviews(heroImage, fallbackFaviconBackground)
        descriptionContainer.addArrangedSubview(faviconImage)
        descriptionContainer.addArrangedSubview(descriptionLabel)
        contentView.addSubviews(itemTitle, imageContainer, descriptionContainer)

        NSLayoutConstraint.activate([
            itemTitle.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            itemTitle.leadingAnchor.constraint(equalTo: imageContainer.trailingAnchor, constant: 16),
            itemTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Image container, hero image and fallback
            imageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            imageContainer.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            imageContainer.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),
            imageContainer.topAnchor.constraint(equalTo: itemTitle.topAnchor),
            imageContainer.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16),

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

            // Description container, it's image and label
            descriptionContainer.topAnchor.constraint(greaterThanOrEqualTo: itemTitle.bottomAnchor, constant: 8),
            descriptionContainer.leadingAnchor.constraint(equalTo: itemTitle.leadingAnchor),
            descriptionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descriptionContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            faviconImage.heightAnchor.constraint(equalToConstant: UX.faviconSize.height),
            faviconImage.widthAnchor.constraint(equalToConstant: UX.faviconSize.width),
        ])

        faviconCenterConstraint = descriptionLabel.centerYAnchor.constraint(equalTo: faviconImage.centerYAnchor).priority(UILayoutPriority(999))
        faviconFirstBaselineConstraint = descriptionLabel.firstBaselineAnchor.constraint(equalTo: faviconImage.bottomAnchor,
                                                                                         constant: -UX.faviconSize.height / 2)

        descriptionLabel.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .vertical)
    }

    private func adjustLayout() {
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory

        // Center favicon on smaller font sizes. On bigger font sizes align with first baseline
        faviconCenterConstraint?.isActive = !contentSizeCategory.isAccessibilityCategory
        faviconFirstBaselineConstraint?.isActive = contentSizeCategory.isAccessibilityCategory

        // Add blur
        if shouldApplyWallpaperBlur {
            contentView.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            contentView.removeVisualEffectView()
            contentView.backgroundColor = LegacyThemeManager.instance.currentName == .dark ?
            UIColor.Photon.DarkGrey40 : .white
            setupShadow()
        }
    }

    private func setupShadow() {
        contentView.layer.cornerRadius = UX.generalCornerRadius
        contentView.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                    cornerRadius: UX.generalCornerRadius).cgPath
        contentView.layer.shadowRadius = UX.stackViewShadowRadius
        contentView.layer.shadowOffset = CGSize(width: 0, height: UX.stackViewShadowOffset)
        contentView.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        contentView.layer.shadowOpacity = 0.12
    }
}

// MARK: - Theme
extension JumpBackInCell: NotificationThemeable {
    func applyTheme() {
        if LegacyThemeManager.instance.currentName == .dark {
            [itemTitle, descriptionLabel].forEach { $0.textColor = UIColor.Photon.LightGrey10 }
            faviconImage.tintColor = UIColor.Photon.LightGrey10
            fallbackFaviconImage.tintColor = UIColor.Photon.LightGrey10
            fallbackFaviconBackground.backgroundColor = UIColor.Photon.DarkGrey60
        } else {
            [itemTitle, descriptionLabel].forEach { $0.textColor = UIColor.Photon.DarkGrey90 }
            faviconImage.tintColor = UIColor.Photon.DarkGrey90
            fallbackFaviconImage.tintColor = UIColor.Photon.DarkGrey90
            fallbackFaviconBackground.backgroundColor = UIColor.Photon.LightGrey10
        }

        fallbackFaviconBackground.layer.borderColor = UIColor.theme.homePanel.topSitesBackground.cgColor
        adjustLayout()
    }
}

// MARK: - Notifiable
extension JumpBackInCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        ensureMainThread { [weak self] in
            switch notification.name {
            case .DisplayThemeChanged,
                    .WallpaperDidChange:
                self?.applyTheme()
            default: break
            }
        }
    }
}
