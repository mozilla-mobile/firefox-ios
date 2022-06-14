// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import UIKit

fileprivate struct LogoViewUX {
    static let imageHeight: CGFloat = 40
    static let imageWidth: CGFloat = 214.74
}

class FxHomeLogoHeaderCell: UICollectionViewCell, ReusableCell {
    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage.OtherButtons

    // MARK: - UI Elements
    lazy var logoButton: ActionButton = .build { button in
        button.setTitle("", for: .normal)
        button.backgroundColor = .clear
        button.accessibilityIdentifier = a11y.logoButton
        button.accessibilityLabel = .Settings.Homepage.Wallpaper.AccessibilityLabels.FxHomepageWallpaperButton
    }

    // MARK: - Variables
    var notificationCenter: NotificationCenter = NotificationCenter.default
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
        contentView.addSubview(logoButton)

        NSLayoutConstraint.activate([
            logoButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            logoButton.widthAnchor.constraint(equalToConstant: LogoViewUX.imageWidth),
            logoButton.heightAnchor.constraint(equalToConstant: LogoViewUX.imageHeight),
            logoButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            logoButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    func configure(onTapAction: ((UIButton) -> Void)?) {
        logoButton.touchUpAction = onTapAction
    }
}

// MARK: - Theme
extension FxHomeLogoHeaderCell: NotificationThemeable {
    func applyTheme() {
        let resourceName = "fxHomeHeaderLogo"
        let resourceNameDark = "fxHomeHeaderLogo_dark"
        let imageString = LegacyThemeManager.instance.currentName == .dark ? resourceNameDark : resourceName
        logoButton.setImage(UIImage(imageLiteralResourceName: imageString), for: .normal)
    }
}

// MARK: - Notifiable
extension FxHomeLogoHeaderCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}
