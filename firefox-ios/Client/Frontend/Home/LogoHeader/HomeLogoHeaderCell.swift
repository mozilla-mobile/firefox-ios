// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import UIKit

class HomeLogoHeaderCell: UICollectionViewCell, ReusableCell {
    private struct UX {
        struct Logo {
            static let iPhoneImageSize: CGFloat = 40
            static let iPadImageSize: CGFloat = 75
            static let iPhoneTopConstant: CGFloat = 32
            static let iPadTopConstant: CGFloat = 70
            static let bottomConstant: CGFloat = -10
        }

        struct TextImage {
            static let iPhoneWidth: CGFloat = 70
            static let iPadWidth: CGFloat = 133
            static let iPhoneLeadingConstant: CGFloat = 9
            static let iPadLeadingConstant: CGFloat = 17
            static let trailingConstant: CGFloat = -15
        }
    }

    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage.OtherButtons

    // MARK: - UI Elements
    private lazy var logoImage: UIImageView = .build { imageView in
        imageView.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall)
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var logoTextImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var containerView: UIView = .build { view in
        view.backgroundColor = .clear
        view.accessibilityIdentifier = a11y.logoID
        view.accessibilityLabel = AppName.shortName.rawValue
        view.isAccessibilityElement = true
        view.accessibilityTraits = .image
    }

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    func setupView() {
        contentView.backgroundColor = .clear
        containerView.addSubview(logoImage)
        containerView.addSubview(logoTextImage)
        contentView.addSubview(containerView)

        // TODO: Felt Privacy - Private mode in Redux to follow
        let isiPadAndPrivate = UIDevice.current.userInterfaceIdiom == .pad && false
        let logoSizeConstant = isiPadAndPrivate ? UX.Logo.iPadImageSize : UX.Logo.iPhoneImageSize
        let topAnchorConstant = isiPadAndPrivate ? UX.Logo.iPadTopConstant : UX.Logo.iPhoneTopConstant
        let textImageWidthConstant = isiPadAndPrivate ? UX.TextImage.iPadWidth : UX.TextImage.iPhoneWidth
        let textImageLeadingAnchorConstant = isiPadAndPrivate ? UX.TextImage.iPadLeadingConstant : UX.TextImage.iPhoneLeadingConstant

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor,
                                               constant: topAnchorConstant),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                  constant: UX.Logo.bottomConstant),

            logoImage.topAnchor.constraint(equalTo: containerView.topAnchor),
            logoImage.widthAnchor.constraint(equalToConstant: logoSizeConstant),
            logoImage.heightAnchor.constraint(equalToConstant: logoSizeConstant),
            logoImage.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            logoImage.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                              constant: UX.Logo.bottomConstant),

            logoTextImage.widthAnchor.constraint(equalToConstant: textImageWidthConstant),
            logoTextImage.heightAnchor.constraint(equalTo: logoImage.heightAnchor),
            logoTextImage.leadingAnchor.constraint(equalTo: logoImage.trailingAnchor,
                                                   constant: textImageLeadingAnchorConstant),
            logoTextImage.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            logoTextImage.centerYAnchor.constraint(equalTo: logoImage.centerYAnchor)
        ])

        if isiPadAndPrivate {
            NSLayoutConstraint.activate([
                containerView.centerXAnchor.constraint(
                    equalTo: contentView.centerXAnchor
                ),
            ])
        } else {
            NSLayoutConstraint.activate([
                containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                containerView.trailingAnchor.constraint(
                    lessThanOrEqualTo: contentView.trailingAnchor,
                    constant: UX.TextImage.trailingConstant),
            ])
        }
    }
}

// MARK: - ThemeApplicable
extension HomeLogoHeaderCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        let wallpaperManager = WallpaperManager()
        if let logoTextColor = wallpaperManager.currentWallpaper.logoTextColor {
            logoTextImage.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoText)
                .withRenderingMode(.alwaysTemplate)
            logoTextImage.tintColor = logoTextColor
        } else {
            logoTextImage.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoText)
                .withRenderingMode(.alwaysTemplate)
            logoTextImage.tintColor = theme.colors.textPrimary
        }
    }
}
