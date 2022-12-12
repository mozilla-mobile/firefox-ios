// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Common

/// Site Image view support two types of image layout.
/// Any type of image layouts will automatically update the image for you asynchronously
///
/// - Favicon
///     - Can be set through `setFavicon(_ viewModel: SiteImageViewFaviconModel)`
///     - No theming calls needed
/// - Hero image with a favicon fallback. Any time you set a hero image, if it's not found it will default to a favicon image.
///     - Can be set through `setHeroImage(_ viewModel: SiteImageViewHeroImageModel)`
///     - The layout size is set through the properties of SiteImageViewHeroImageModel
///     - Need to setup theme calls through `updateHeroImageTheme(with colors: SiteImageViewColor)`
public class SiteImageView: UIView {
    // MARK: - Properties
    private var uniqueID: UUID?
    private var imageFetcher: SiteImageFetcher = DefaultSiteImageFetcher()

    private lazy var faviconView: UIImageView = .build { imageView in
        imageView.layer.masksToBounds = true
    }

    private lazy var heroImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = .clear
    }

    // Used as a fallback if hero image isn't set
    private lazy var fallbackFaviconImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.layer.masksToBounds = true
    }

    private lazy var fallbackFaviconBackground: UIView = .build { view in }

    // MARK: - Init

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    public func setFavicon(_ viewModel: SiteImageViewFaviconModel) {
        setupFaviconLayout(viewModel: viewModel)
        setURL(viewModel.siteURL, type: viewModel.type)
    }

    public func setHeroImage(_ viewModel: SiteImageViewHeroImageModel) {
        setupHeroImageLayout(viewModel: viewModel)
        setURL(viewModel.siteURL, type: viewModel.type)
    }

    public func updateHeroImageTheme(with colors: SiteImageViewHeroImageColor) {
        fallbackFaviconImageView.tintColor = colors.faviconTintColor
        fallbackFaviconBackground.backgroundColor = colors.faviconBackgroundColor
        fallbackFaviconBackground.layer.borderColor = colors.faviconBorderColor.cgColor
    }

    // MARK: - Update image

    private func setURL(_ siteURL: URL, type: SiteImageType) {
        let id = UUID()
        uniqueID = id
        updateImage(url: siteURL, type: type, id: id)
    }

    private func updateImage(url: URL, type: SiteImageType, id: UUID) {
        Task {
            let imageModel = await imageFetcher.getImage(siteURL: url, type: type, id: id)
            guard uniqueID == imageModel.id else { return }

            switch type {
            case .heroImage:
                setHeroImageImage(imageModel)
            case .favicon:
                setupFaviconImage(imageModel)
            }
        }
    }

    // MARK: - Favicon

    private func setupFaviconImage(_ viewModel: SiteImageModel) {
        faviconView.image = viewModel.faviconImage
    }

    private func setupFaviconLayout(viewModel: SiteImageViewFaviconModel) {
        faviconView.layer.cornerRadius = viewModel.faviconCornerRadius

        addSubviews(faviconView)
        NSLayoutConstraint.activate([
            faviconView.topAnchor.constraint(equalTo: topAnchor),
            faviconView.leadingAnchor.constraint(equalTo: leadingAnchor),
            faviconView.trailingAnchor.constraint(equalTo: trailingAnchor),
            faviconView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - Hero image

    private func setHeroImageImage(_ imageModel: SiteImageModel) {
        if let heroImage = imageModel.heroImage {
            // If hero image is a square use it as a favicon
            guard heroImage.size.width == heroImage.size.height else {
                setFallBackFaviconVisibility(isHidden: true)
                heroImageView.image = heroImage
                return
            }
            setFallBackFaviconVisibility(isHidden: false)
            fallbackFaviconImageView.image = heroImage
        } else if let faviconImage = imageModel.faviconImage {
            setFallBackFaviconVisibility(isHidden: false)
            fallbackFaviconImageView.image = faviconImage
        }
    }

    private func setupHeroImageLayout(viewModel: SiteImageViewHeroImageModel) {
        heroImageView.layer.cornerRadius = viewModel.generalCornerRadius
        fallbackFaviconImageView.layer.cornerRadius = viewModel.faviconCornerRadius
        fallbackFaviconBackground.layer.cornerRadius = viewModel.generalCornerRadius
        fallbackFaviconBackground.layer.borderWidth = viewModel.faviconBorderWidth

        fallbackFaviconBackground.addSubview(fallbackFaviconImageView)
        addSubviews(heroImageView, fallbackFaviconBackground)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: viewModel.heroImageSize.height),
            widthAnchor.constraint(equalToConstant: viewModel.heroImageSize.width),

            heroImageView.topAnchor.constraint(equalTo: topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            heroImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            fallbackFaviconBackground.centerXAnchor.constraint(equalTo: centerXAnchor),
            fallbackFaviconBackground.centerYAnchor.constraint(equalTo: centerYAnchor),
            fallbackFaviconBackground.heightAnchor.constraint(equalToConstant: viewModel.heroImageSize.height),
            fallbackFaviconBackground.widthAnchor.constraint(equalToConstant: viewModel.heroImageSize.width),

            fallbackFaviconImageView.heightAnchor.constraint(equalToConstant: viewModel.fallbackFaviconSize.height),
            fallbackFaviconImageView.widthAnchor.constraint(equalToConstant: viewModel.fallbackFaviconSize.width),
            fallbackFaviconImageView.centerXAnchor.constraint(equalTo: fallbackFaviconBackground.centerXAnchor),
            fallbackFaviconImageView.centerYAnchor.constraint(equalTo: fallbackFaviconBackground.centerYAnchor),
        ])
    }

    private func setFallBackFaviconVisibility(isHidden: Bool) {
        fallbackFaviconBackground.isHidden = isHidden
        fallbackFaviconImageView.isHidden = isHidden
    }
}
