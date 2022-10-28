// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

/// A cell used in FxHomeScreen's Recently Saved section. It holds bookmarks and reading list items.
class RecentlySavedCell: UICollectionViewCell, ReusableCell {

    private struct UX {
        static let bookmarkTitleFontSize: CGFloat = 12
        static let containerSpacing: CGFloat = 16
        static let heroImageSize: CGSize = CGSize(width: 126, height: 82)
        static let fallbackFaviconSize = CGSize(width: 36, height: 36)
        static let generalSpacing: CGFloat = 8
    }

    // MARK: - UI Elements
    private var rootContainer: UIView = .build { view in
        view.backgroundColor = .clear
        view.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
    }

    // Contains the hero image and fallback favicons
    private var imageContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    let heroImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
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

    let itemTitle: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body,
                                                                   size: UX.bookmarkTitleFontSize)
        label.adjustsFontForContentSizeCategory = true
    }

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        heroImageView.image = nil
        fallbackFaviconImage.image = nil
        itemTitle.text = nil
        setFallBackFaviconVisibility(isHidden: false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        rootContainer.layer.shadowPath = UIBezierPath(roundedRect: rootContainer.bounds,
                                                      cornerRadius: HomepageViewModel.UX.generalCornerRadius).cgPath
    }

    func configure(viewModel: RecentlySavedCellViewModel, theme: Theme) {
        configureImages(heroImage: viewModel.heroImage, favIconImage: viewModel.favIconImage)

        itemTitle.text = viewModel.site.title
        applyTheme(theme: theme)
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
        contentView.backgroundColor = .clear

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
    }

    private func setupShadow(theme: Theme) {
        rootContainer.layer.shadowPath = UIBezierPath(roundedRect: rootContainer.bounds,
                                                      cornerRadius: HomepageViewModel.UX.generalCornerRadius).cgPath

        rootContainer.layer.shadowColor = theme.colors.shadowDefault.cgColor
        rootContainer.layer.shadowOpacity = HomepageViewModel.UX.shadowOpacity
        rootContainer.layer.shadowOffset = HomepageViewModel.UX.shadowOffset
        rootContainer.layer.shadowRadius = HomepageViewModel.UX.shadowRadius
    }
}

// MARK: - ThemeApplicable
extension RecentlySavedCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        itemTitle.textColor = theme.colors.textPrimary
        fallbackFaviconBackground.backgroundColor = theme.colors.layer1
        fallbackFaviconBackground.layer.borderColor = theme.colors.layer1.cgColor

        adjustBlur(theme: theme)
    }
}

// MARK: - Blurrable
extension RecentlySavedCell: Blurrable {
    func adjustBlur(theme: Theme) {
        // If blur is disabled set background color
        if shouldApplyWallpaperBlur {
            rootContainer.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            rootContainer.removeVisualEffectView()
            rootContainer.backgroundColor = theme.colors.layer5
            setupShadow(theme: theme)
        }
    }
}
