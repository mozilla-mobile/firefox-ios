/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core
import Common

final class NTPLogoCell: UICollectionViewCell, ReusableCell, Themeable {
    static let bottomMargin: CGFloat = 6
    static let width: CGFloat = 144

    private weak var logo: UIImageView!

    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setup() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        let logo = UIImageView(image: .init(named: "ecosiaLogoLaunch")?.withRenderingMode(.alwaysTemplate))
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.clipsToBounds = true
        logo.contentMode = .scaleAspectFit
        logo.isAccessibilityElement = true
        logo.accessibilityIdentifier = AccessibilityIdentifiers.Ecosia.logo
        logo.accessibilityLabel = .localized(.ecosiaLogoAccessibilityLabel)
        contentView.addSubview(logo)
        self.logo = logo

        let bottom = logo.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.bottomMargin)
        bottom.priority = .defaultHigh
        bottom.isActive = true

        logo.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        logo.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        logo.widthAnchor.constraint(equalToConstant: Self.width).isActive = true
        applyTheme()
        listenForThemeChange(contentView)
    }

    func applyTheme() {
        logo.tintColor = .legacyTheme.ecosia.primaryBrand
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
