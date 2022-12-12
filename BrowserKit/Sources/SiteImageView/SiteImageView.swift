// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Common

public class SiteImageView: UIView {
    // MARK: - Properties
    private var uniqueID: UUID?
    private var imageFetcher: SiteImageFetcher = DefaultSiteImageFetcher()

    // Contains the heroImage and fallbackFaviconImage
    private var imageContainer: UIView = .build { view in
        view.backgroundColor = .clear
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

    public func setViewModel(_ viewModel: SiteImageViewModel) {
        setupLayout(viewModel: viewModel)
        setURL(viewModel.siteURL, type: viewModel.type)
    }

    public func updateTheme(with colors: SiteImageViewColor) {
        fallbackFaviconImageView.tintColor = colors.faviconTintColor
        fallbackFaviconBackground.backgroundColor = colors.faviconBackgroundColor
        fallbackFaviconBackground.layer.borderColor = colors.faviconBorderColor.cgColor
    }

    // MARK: - Private

    private func setURL(_ siteURL: URL, type: SiteImageType) {
        let id = UUID()
        uniqueID = id
        updateImage(url: siteURL, type: type, id: id)
    }

    private func updateImage(url: URL, type: SiteImageType, id: UUID) {
        Task {
            let imageModel = await imageFetcher.getImage(siteURL: url, type: type, id: id)
            guard uniqueID == imageModel.id else { return }
            setImage(imageModel: imageModel)
        }
    }

    private func setImage(imageModel: SiteImageModel) {
        if let heroImage = imageModel.heroImage {
            setHeroImage(heroImage)
        } else if let faviconImage = imageModel.faviconImage {
            setFallBackFaviconVisibility(isHidden: false)
            fallbackFaviconImageView.image = faviconImage
        }
    }

    private func setHeroImage(_ heroImage: UIImage) {
        // If hero image is a square use it as a favicon
        if heroImage.size.width == heroImage.size.height {
            setFallBackFaviconVisibility(isHidden: false)
            fallbackFaviconImageView.image = heroImage
        } else {
            setFallBackFaviconVisibility(isHidden: true)
            heroImageView.image = heroImage
        }
    }

    private func setFallBackFaviconVisibility(isHidden: Bool) {
        fallbackFaviconBackground.isHidden = isHidden
        fallbackFaviconImageView.isHidden = isHidden
    }

    private func setupLayout(viewModel: SiteImageViewModel) {
        heroImageView.layer.cornerRadius = viewModel.generalCornerRadius
        fallbackFaviconImageView.layer.cornerRadius = viewModel.faviconCornerRadius
        fallbackFaviconBackground.layer.cornerRadius = viewModel.generalCornerRadius
        fallbackFaviconBackground.layer.borderWidth = viewModel.faviconBorderWidth

        fallbackFaviconBackground.addSubview(fallbackFaviconImageView)
        addSubviews(heroImageView, fallbackFaviconBackground)

        NSLayoutConstraint.activate([
            imageContainer.heightAnchor.constraint(equalToConstant: viewModel.heroImageSize.height),
            imageContainer.widthAnchor.constraint(equalToConstant: viewModel.heroImageSize.width),

            heroImageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            heroImageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),

            fallbackFaviconBackground.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            fallbackFaviconBackground.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
            fallbackFaviconBackground.heightAnchor.constraint(equalToConstant: viewModel.heroImageSize.height),
            fallbackFaviconBackground.widthAnchor.constraint(equalToConstant: viewModel.heroImageSize.width),

            fallbackFaviconImageView.heightAnchor.constraint(equalToConstant: viewModel.fallbackFaviconSize.height),
            fallbackFaviconImageView.widthAnchor.constraint(equalToConstant: viewModel.fallbackFaviconSize.width),
            fallbackFaviconImageView.centerXAnchor.constraint(equalTo: fallbackFaviconBackground.centerXAnchor),
            fallbackFaviconImageView.centerYAnchor.constraint(equalTo: fallbackFaviconBackground.centerYAnchor),
        ])
    }
}
