// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import UIKit
import Account

class HomeLogoHeaderCell: UICollectionViewCell, ReusableCell {
    private struct UX {
        struct Logo {
            static let iPhoneImageSize: CGFloat = 40
            static let iPadImageSize: CGFloat = 75

            static func logoSizeConstant(for iPadSetup: Bool) -> CGFloat {
                iPadSetup ? UX.Logo.iPadImageSize : UX.Logo.iPhoneImageSize
            }
        }

        struct TextImage {
            static let iPhoneWidth: CGFloat = 70
            static let iPadWidth: CGFloat = 133
            static let iPhoneLeadingConstant: CGFloat = 9
            static let iPadLeadingConstant: CGFloat = 17
            static let trailingConstant: CGFloat = -15

            static func textImageWidthConstant(for iPadSetup: Bool) -> CGFloat {
                iPadSetup ? UX.TextImage.iPadWidth : UX.TextImage.iPhoneWidth
            }

            static func textImageSpacing(for iPadSetup: Bool) -> CGFloat {
                iPadSetup ? UX.TextImage.iPadLeadingConstant : UX.TextImage.iPhoneLeadingConstant
            }
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

    private lazy var containerView: UIStackView = .build { view in
        view.backgroundColor = .clear
        view.accessibilityIdentifier = a11y.logoID
        view.accessibilityLabel = AppName.shortName.rawValue
        view.isAccessibilityElement = true
        view.accessibilityTraits = .image
    }

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    func configure(with showiPadSetup: Bool) {
        setupView(with: showiPadSetup)
    }

    private func setupView(with showiPadSetup: Bool) {
        contentView.backgroundColor = .clear
        containerView.addArrangedSubview(logoImage)
        containerView.addArrangedSubview(logoTextImage)
        contentView.addSubview(containerView)

        containerView.spacing = UX.TextImage.textImageSpacing(for: showiPadSetup)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        setupConstraints(for: showiPadSetup)
    }

    private var logoConstraints = [NSLayoutConstraint]()

    private func setupConstraints(for iPadSetup: Bool) {
        NSLayoutConstraint.deactivate(logoConstraints)
        logoConstraints = [
            logoImage.widthAnchor.constraint(equalToConstant: UX.Logo.logoSizeConstant(for: iPadSetup)),
            logoImage.heightAnchor.constraint(equalToConstant: UX.Logo.logoSizeConstant(for: iPadSetup)),
            logoTextImage.widthAnchor.constraint(equalToConstant: UX.TextImage.textImageWidthConstant(for: iPadSetup)),
            logoTextImage.heightAnchor.constraint(equalTo: logoImage.heightAnchor),
        ]

        if iPadSetup {
            logoConstraints.append(
                containerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
            )
        } else {
            logoConstraints.append(
                containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
            )
        }
        NSLayoutConstraint.activate(logoConstraints)
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
