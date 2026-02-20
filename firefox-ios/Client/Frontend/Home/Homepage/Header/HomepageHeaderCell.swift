// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common
import Shared

// Header for the homepage in both normal and private mode
// Contains the firefox logo and the private browsing shortcut button
class HomepageHeaderCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    enum UX {
        static let iPhoneTopConstant: CGFloat = 16
        static let iPadTopConstant: CGFloat = 54
        static let circleSize = CGRect(width: 40, height: 40)

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

    static func contentWidth(for showiPadSetup: Bool) -> CGFloat {
        return UX.Logo.logoSizeConstant(for: showiPadSetup)
        + UX.TextImage.textImageSpacing(for: showiPadSetup)
        + UX.TextImage.textImageWidthConstant(for: showiPadSetup)
    }

    private var headerState: HeaderState?
    private var hasConfiguredView = false

    private lazy var stackContainer: UIStackView = .build { stackView in
        stackView.axis = .horizontal
    }

    private lazy var logoContainerView: UIView = .build()

    private lazy var logoStackView: UIStackView = .build { view in
        view.backgroundColor = .clear
        view.accessibilityIdentifier = a11y.logoID
        view.accessibilityLabel = AppName.shortName.rawValue
        view.isAccessibilityElement = true
        view.accessibilityTraits = .image
    }

    private lazy var logoImage: UIImageView = .build { imageView in
        imageView.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall)
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var logoTextImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupView(with showiPadSetup: Bool) {
        if !hasConfiguredView {
            contentView.backgroundColor = .clear
            logoStackView.addArrangedSubview(logoImage)
            logoStackView.addArrangedSubview(logoTextImage)

            logoContainerView.addSubview(logoStackView)
            stackContainer.addArrangedSubview(logoContainerView)
            contentView.addSubview(stackContainer)

            NSLayoutConstraint.activate([
                logoStackView.topAnchor.constraint(equalTo: logoContainerView.topAnchor),
                logoStackView.bottomAnchor.constraint(equalTo: logoContainerView.bottomAnchor)
            ])

            hasConfiguredView = true
        }

        logoStackView.spacing = UX.TextImage.textImageSpacing(for: showiPadSetup)

        setupConstraints(for: showiPadSetup)
        setupLogoConstraints(for: showiPadSetup)
    }

    private var headerConstraints = [NSLayoutConstraint]()
    private var logoConstraints = [NSLayoutConstraint]()

    private func setupConstraints(for iPadSetup: Bool) {
        NSLayoutConstraint.deactivate(headerConstraints)
        let topAnchorConstant = iPadSetup ? UX.iPadTopConstant : UX.iPhoneTopConstant
        headerConstraints = [
            stackContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topAnchorConstant),
            stackContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).priority(.defaultLow),

            logoContainerView.centerYAnchor.constraint(equalTo: stackContainer.centerYAnchor)
        ]

        NSLayoutConstraint.activate(headerConstraints)
    }

    private func setupLogoConstraints(for iPadSetup: Bool) {
        NSLayoutConstraint.deactivate(logoConstraints)
        logoConstraints = [
            logoImage.widthAnchor.constraint(equalToConstant: UX.Logo.logoSizeConstant(for: iPadSetup)),
            logoImage.heightAnchor.constraint(equalToConstant: UX.Logo.logoSizeConstant(for: iPadSetup)),
            logoTextImage.widthAnchor.constraint(equalToConstant: UX.TextImage.textImageWidthConstant(for: iPadSetup)),
            logoTextImage.heightAnchor.constraint(equalTo: logoImage.heightAnchor)
        ]

        if iPadSetup {
            logoConstraints.append(
                logoStackView.centerXAnchor.constraint(equalTo: logoContainerView.centerXAnchor)
            )
        } else {
            logoConstraints.append(
                logoStackView.leadingAnchor.constraint(equalTo: logoContainerView.leadingAnchor)
            )
        }
        NSLayoutConstraint.activate(logoConstraints)
    }

    func configure(headerState: HeaderState) {
        self.headerState = headerState
        setupView(with: headerState.showiPadSetup)
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        // TODO: FXIOS-10851 This can be moved to the new homescreen wallpaper fetching redux
        let wallpaperManager = WallpaperManager()
        let browserViewType = store.state.screenState(
            BrowserViewControllerState.self,
            for: .browserViewController,
            window: currentWindowUUID
        )?.browserViewType

        if let logoTextColor = wallpaperManager.currentWallpaper.logoTextColor, browserViewType != .privateHomepage {
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
