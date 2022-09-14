// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import UIKit

class HomeLogoHeaderCell: UICollectionViewCell, ReusableCell {
    private struct UX {
        static let logoImageSize: CGFloat = 40
        static let textImageWidth: CGFloat = 165.5
        static let textImageHeight: CGFloat = 17.5
    }

    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage.OtherButtons

    // MARK: - UI Elements
    lazy var logoImage: UIImageView = .build { imageView in
        imageView.image = UIImage(imageLiteralResourceName: "fxHomeHeaderLogoBall")
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIdentifier = a11y.logoImage
    }

    lazy var logoTextImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIdentifier = a11y.logoText
    }

    // MARK: - Variables
    var notificationCenter: NotificationProtocol = NotificationCenter.default
    private var userDefaults: UserDefaults = UserDefaults.standard

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        applyTheme()
        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - UI Setup
    func setupView() {
        contentView.backgroundColor = .clear
        contentView.addSubview(logoImage)
        contentView.addSubview(logoTextImage)

        NSLayoutConstraint.activate([
            logoImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            logoImage.widthAnchor.constraint(equalToConstant: UX.logoImageSize),
            logoImage.heightAnchor.constraint(equalToConstant: UX.logoImageSize),
            logoImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            logoImage.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            logoTextImage.widthAnchor.constraint(equalToConstant: UX.textImageWidth),
            logoTextImage.heightAnchor.constraint(equalToConstant: UX.textImageHeight),
            logoTextImage.leadingAnchor.constraint(equalTo: logoImage.trailingAnchor, constant: 9),
            logoTextImage.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -15),
            logoTextImage.centerYAnchor.constraint(equalTo: logoImage.centerYAnchor)
        ])
    }
}

// MARK: - Theme
extension HomeLogoHeaderCell: NotificationThemeable {
    func applyTheme() {
        let wallpaperManager = WallpaperManager()
        if let logoTextColor = wallpaperManager.currentWallpaper.logoTextColor {
            logoTextImage.image = UIImage(imageLiteralResourceName: "fxHomeHeaderLogoText")
                .withRenderingMode(.alwaysTemplate)
            logoTextImage.tintColor = logoTextColor
        } else {
            logoTextImage.image = UIImage(imageLiteralResourceName: "fxHomeHeaderLogoText")
                .withRenderingMode(.alwaysTemplate)
            logoTextImage.tintColor = LegacyThemeManager.instance.current.homePanel.topSiteHeaderTitle
        }
    }
}

// MARK: - Notifiable
extension HomeLogoHeaderCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}
