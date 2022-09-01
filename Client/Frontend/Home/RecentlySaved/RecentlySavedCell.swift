// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

/// A cell used in FxHomeScreen's Recently Saved section. It holds bookmarks and reading list items.
class RecentlySavedCell: UICollectionViewCell, ReusableCell, NotificationThemeable {

    private struct UX {
        static let generalCornerRadius: CGFloat = 12
        static let bookmarkTitleFontSize: CGFloat = 12
        static let generalSpacing: CGFloat = 8
        static let containerSpacing: CGFloat = 16
        static let heroImageSize: CGSize = CGSize(width: 126, height: 82)
        static let shadowRadius: CGFloat = 4
        static let shadowOffset: CGFloat = 2
        static let iconCornerRadius: CGFloat = 4
        static let borderWidth: CGFloat = 0.5
        static let cellCornerRadius: CGFloat = 8
        static let fallbackFaviconSize = CGSize(width: 36, height: 36)
    }

    // MARK: - UI Elements
    private var rootContainer: UIView = .build { view in
        view.backgroundColor = .white
    }

    // Contains the hero image and fallback favicons
    private var imageContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    let heroImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = UX.generalCornerRadius
        imageView.backgroundColor = .systemBackground
    }

    // Used as a fallback if hero image isn't set
    private let fallbackFaviconImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.clear
        imageView.layer.cornerRadius = UX.iconCornerRadius
        imageView.layer.masksToBounds = true
    }

    private var fallbackFaviconBackground: UIView = .build { view in
        view.layer.cornerRadius = UX.cellCornerRadius
        view.layer.borderWidth = UX.borderWidth
    }

    let itemTitle: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body,
                                                                   size: UX.bookmarkTitleFontSize)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
    }

    // MARK: - Variables
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

        setupLayout()
        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged])
        applyTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        heroImageView.image = nil
        fallbackFaviconImage.image = nil
        itemTitle.text = nil
        setFallBackFaviconVisibility(isHidden: false)
        applyTheme()
    }

    func configure(site: Site, heroImage: UIImage?, favIconImage: UIImage?) {
        configureImages(heroImage: heroImage, favIconImage: favIconImage)

        itemTitle.text = site.title
        adjustLayout()
    }

    private func configureImages(heroImage: UIImage?, favIconImage: UIImage?) {
        if heroImage == nil {
            // Sets a small favicon in place of the hero image in case there's no hero image
            fallbackFaviconImage.image = favIconImage
        } else if heroImage?.size.width == heroImage?.size.height {
            // If hero image is a square use it as a favicon
            fallbackFaviconImage.image = heroImage
        } else {
            setFallBackFaviconVisibility(isHidden: true)
            heroImageView.image = heroImage
        }
    }

    private func setFallBackFaviconVisibility(isHidden: Bool) {
        fallbackFaviconBackground.isHidden = isHidden
        fallbackFaviconImage.isHidden = isHidden

        heroImageView.isHidden = !isHidden
    }

    // MARK: - Helpers

    private func setupLayout() {
        rootContainer.layer.cornerRadius = UX.generalCornerRadius
        rootContainer.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                      cornerRadius: UX.generalCornerRadius).cgPath
        rootContainer.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        rootContainer.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
        rootContainer.layer.shadowOffset = CGSize(width: 0, height: UX.shadowOffset)
        rootContainer.layer.shadowRadius = UX.shadowRadius

        fallbackFaviconBackground.addSubviews(fallbackFaviconImage)
        imageContainer.addSubviews(heroImageView, fallbackFaviconBackground)
        rootContainer.addSubviews(imageContainer, itemTitle)
        contentView.addSubview(rootContainer)

        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rootContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rootContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Image container, hero image and fallback

            imageContainer.topAnchor.constraint(equalTo: rootContainer.topAnchor,
                                                constant: UX.containerSpacing),
            imageContainer.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor,
                                                    constant: UX.containerSpacing),
            imageContainer.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor,
                                                     constant: -UX.containerSpacing),
            imageContainer.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            imageContainer.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),

            heroImageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            heroImageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),

            itemTitle.topAnchor.constraint(equalTo: heroImageView.bottomAnchor,
                                           constant: UX.generalSpacing),
            itemTitle.leadingAnchor.constraint(equalTo: heroImageView.leadingAnchor),
            itemTitle.trailingAnchor.constraint(equalTo: heroImageView.trailingAnchor),
            itemTitle.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor,
                                              constant: -UX.generalSpacing),

            fallbackFaviconBackground.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            fallbackFaviconBackground.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
            fallbackFaviconBackground.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            fallbackFaviconBackground.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),

            fallbackFaviconImage.heightAnchor.constraint(equalToConstant: UX.fallbackFaviconSize.height),
            fallbackFaviconImage.widthAnchor.constraint(equalToConstant: UX.fallbackFaviconSize.width),
            fallbackFaviconImage.centerXAnchor.constraint(equalTo: fallbackFaviconBackground.centerXAnchor),
            fallbackFaviconImage.centerYAnchor.constraint(equalTo: fallbackFaviconBackground.centerYAnchor),

            itemTitle.topAnchor.constraint(equalTo: heroImageView.bottomAnchor,
                                           constant: UX.generalSpacing),
            itemTitle.leadingAnchor.constraint(equalTo: heroImageView.leadingAnchor),
            itemTitle.trailingAnchor.constraint(equalTo: heroImageView.trailingAnchor),
            itemTitle.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor,
                                              constant: -UX.generalSpacing)
        ])

        adjustLayout()
    }

    func adjustLayout() {
        rootContainer.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        fallbackFaviconBackground.addBlurEffectWithClearBackgroundAndClipping(using: .systemMaterial)
    }

    func applyTheme() {
        if LegacyThemeManager.instance.currentName == .dark {
            itemTitle.textColor = UIColor.Photon.LightGrey10
            rootContainer.backgroundColor = UIColor.Photon.DarkGrey40
        } else {
            itemTitle.textColor = UIColor.Photon.DarkGrey90
            rootContainer.backgroundColor = .white
        }

        // If blur is disabled set background color
        if UIAccessibility.isReduceTransparencyEnabled {
            fallbackFaviconBackground.backgroundColor = UIColor.Photon.LightGrey20
            rootContainer.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground
        }

        fallbackFaviconBackground.layer.borderColor = UIColor.theme.homePanel.topSitesBackground.cgColor
    }
}

// MARK: - Notifiable
extension RecentlySavedCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default:
            break
        }
    }
}
