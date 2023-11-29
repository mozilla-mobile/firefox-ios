// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import UIKit

class HomeLogoHeaderCell: UICollectionViewCell, ReusableCell {
    private struct UX {
        static let iPadAdjustment: CGFloat = -40
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
        imageView.accessibilityIdentifier = a11y.logoImage
    }

    private lazy var logoTextImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIdentifier = a11y.logoText
        imageView.accessibilityLabel = AppName.shortName.rawValue
        imageView.isAccessibilityElement = true
    }

    private lazy var containerView: UIView = .build { view in
        view.backgroundColor = .clear
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

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: isiPadAndPrivate ? UX.Logo.iPadTopConstant : UX.Logo.iPhoneTopConstant),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                  constant: UX.Logo.bottomConstant),

            logoImage.topAnchor.constraint(equalTo: containerView.topAnchor),
            logoImage.widthAnchor.constraint(equalToConstant: logoSizeConstant),
            logoImage.heightAnchor.constraint(equalToConstant: logoSizeConstant),
            logoImage.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            logoImage.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                              constant: UX.Logo.bottomConstant),

            logoTextImage.widthAnchor.constraint(
                equalToConstant: isiPadAndPrivate ? UX.TextImage.iPadWidth : UX.TextImage.iPhoneWidth),
            logoTextImage.heightAnchor.constraint(equalTo: logoImage.heightAnchor),
            logoTextImage.leadingAnchor.constraint(
                equalTo: logoImage.trailingAnchor,
                constant: isiPadAndPrivate ? UX.TextImage.iPadLeadingConstant : UX.TextImage.iPhoneLeadingConstant),
            logoTextImage.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            logoTextImage.centerYAnchor.constraint(equalTo: logoImage.centerYAnchor)
        ])

        if isiPadAndPrivate {
            NSLayoutConstraint.activate([
                containerView.centerXAnchor.constraint(
                    equalTo: contentView.centerXAnchor,
                    constant: UX.iPadAdjustment
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
