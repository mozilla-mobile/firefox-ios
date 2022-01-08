// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import UIKit

struct FxHomeHorizontalCellUX {
    static let cellHeight: CGFloat = 112
    static let cellWidth: CGFloat = 350
    static let interItemSpacing = NSCollectionLayoutSpacing.fixed(8)
    static let interGroupSpacing: CGFloat = 8
    static let generalCornerRadius: CGFloat = 12
    // TODO: Limiting font size to xxLarge until we use compositional layout in all Firefox HomePage. Should be AX5.
    static let titleFontSize: CGFloat = 19 // Style subheadline - xxLarge
    static let siteFontSize: CGFloat = 16 // Style caption1 - xxLarge
    static let stackViewShadowRadius: CGFloat = 4
    static let stackViewShadowOffset: CGFloat = 2
    static let heroImageSize =  CGSize(width: 108, height: 80)
    static let fallbackFaviconSize = CGSize(width: 56, height: 56)
    static let faviconSize = CGSize(width: 24, height: 24)
}

struct FxHomeHorizontalCellViewModel {
    let titleText: String
    let descriptionText: String
    let tag: Int
    var hasFavicon: Bool // Pocket has no favicon
    var favIconImage: UIImage? = nil
    var heroImage: UIImage?
}

// MARK: - FxHomeHorizontalCell
/// A cell used in FxHomeScreen's Jump Back In and Pocket sections
class FxHomeHorizontalCell: UICollectionViewCell, ReusableCell {

    // MARK: - UI Elements
    let heroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = FxHomeHorizontalCellUX.generalCornerRadius
        imageView.backgroundColor = .clear
    }

    private let itemTitle: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                   maxSize: FxHomeHorizontalCellUX.titleFontSize)
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
        imageView.layer.cornerRadius = FxHomeHorizontalCellUX.generalCornerRadius
    }

    private let descriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1,
                                                                   maxSize: FxHomeHorizontalCellUX.siteFontSize)
        label.textColor = .label
    }

    // Used as a fallback if hero image isn't set
    let fallbackFaviconImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.clear
        imageView.layer.cornerRadius = TopSiteCellUX.iconCornerRadius
        imageView.layer.masksToBounds = true
    }

    private var fallbackFaviconBackground: UIView = .build { view in
        view.layer.cornerRadius = TopSiteCellUX.cellCornerRadius
        view.layer.borderWidth = TopSiteCellUX.borderWidth
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = TopSiteCellUX.shadowRadius
        view.backgroundColor = UIColor.theme.homePanel.shortcutBackground
        view.layer.borderColor = TopSiteCellUX.borderColor.cgColor
        view.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        view.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
    }

    // Contains the hero image and fallback favicons
    private var imageContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

        applyTheme()
        setupObservers()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
    }

    // MARK: - Helpers

    func configure(viewModel: FxHomeHorizontalCellViewModel) {
        tag = viewModel.tag
        itemTitle.text = viewModel.titleText
        descriptionLabel.text = viewModel.descriptionText
        heroImage.image = viewModel.heroImage

        if viewModel.hasFavicon {
            faviconImage.image = viewModel.favIconImage
        } else {
            descriptionContainer.removeArrangedSubview(faviconImage)
            faviconImage.image = nil
        }
    }

    func setFallBackFaviconVisibility(isHidden: Bool) {
        fallbackFaviconBackground.isHidden = isHidden
        fallbackFaviconImage.isHidden = isHidden
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotifications), name: .DisplayThemeChanged, object: nil)
    }

    private func setupLayout() {
        contentView.layer.cornerRadius = FxHomeHorizontalCellUX.generalCornerRadius
        contentView.layer.shadowRadius = FxHomeHorizontalCellUX.stackViewShadowRadius
        contentView.layer.shadowOffset = CGSize(width: 0, height: FxHomeHorizontalCellUX.stackViewShadowOffset)
        contentView.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        contentView.layer.shadowOpacity = 0.12

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
            imageContainer.heightAnchor.constraint(equalToConstant: FxHomeHorizontalCellUX.heroImageSize.height),
            imageContainer.widthAnchor.constraint(equalToConstant: FxHomeHorizontalCellUX.heroImageSize.width),
            imageContainer.topAnchor.constraint(equalTo: itemTitle.topAnchor),
            imageContainer.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor, constant: -16),

            heroImage.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            heroImage.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            heroImage.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            heroImage.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),

            fallbackFaviconBackground.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            fallbackFaviconBackground.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
            fallbackFaviconBackground.heightAnchor.constraint(equalToConstant: FxHomeHorizontalCellUX.heroImageSize.height),
            fallbackFaviconBackground.widthAnchor.constraint(equalToConstant: FxHomeHorizontalCellUX.heroImageSize.width),

            fallbackFaviconImage.heightAnchor.constraint(equalToConstant: FxHomeHorizontalCellUX.fallbackFaviconSize.height),
            fallbackFaviconImage.widthAnchor.constraint(equalToConstant: FxHomeHorizontalCellUX.fallbackFaviconSize.width),
            fallbackFaviconImage.centerXAnchor.constraint(equalTo: fallbackFaviconBackground.centerXAnchor),
            fallbackFaviconImage.centerYAnchor.constraint(equalTo: fallbackFaviconBackground.centerYAnchor),

            // Description container, it's image and label
            descriptionContainer.topAnchor.constraint(greaterThanOrEqualTo: itemTitle.bottomAnchor, constant: 8),
            descriptionContainer.leadingAnchor.constraint(equalTo: itemTitle.leadingAnchor),
            descriptionContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            descriptionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            faviconImage.heightAnchor.constraint(equalToConstant: FxHomeHorizontalCellUX.faviconSize.height),
            faviconImage.widthAnchor.constraint(equalToConstant: FxHomeHorizontalCellUX.faviconSize.width),

            descriptionLabel.centerYAnchor.constraint(equalTo: faviconImage.centerYAnchor),
        ])
    }

    @objc private func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}

extension FxHomeHorizontalCell: NotificationThemeable {
    func applyTheme() {
        if LegacyThemeManager.instance.currentName == .dark {
            [itemTitle, descriptionLabel].forEach { $0.textColor = UIColor.Photon.LightGrey10 }
            faviconImage.tintColor = UIColor.Photon.LightGrey10
            fallbackFaviconImage.tintColor = UIColor.Photon.LightGrey10
        } else {
            [itemTitle, descriptionLabel].forEach { $0.textColor = UIColor.Photon.DarkGrey90 }
            faviconImage.tintColor = UIColor.Photon.DarkGrey90
            fallbackFaviconImage.tintColor = UIColor.Photon.DarkGrey90
        }

        fallbackFaviconBackground.backgroundColor = UIColor.theme.homePanel.shortcutBackground
        fallbackFaviconBackground.layer.borderColor = TopSiteCellUX.borderColor.cgColor
        fallbackFaviconBackground.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        fallbackFaviconBackground.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
        contentView.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground
    }
}
