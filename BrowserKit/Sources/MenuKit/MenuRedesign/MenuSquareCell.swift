// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

// TODO: FXIOS-12302 Create the UI for different accessibility sizes, for horizontal options section
final class MenuSquareCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let iconSize: CGFloat = 20
        static let backgroundIconViewCornerRadius: CGFloat = 12
        static let horizontalMargin: CGFloat = 6
        static let verticalMargin: CGFloat = 6
    }

    // MARK: - UI Elements
    private var backgroundIconView: UIView = .build()

    private var icon: UIImageView = .build()

    private var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption2.scaledFont()
        label.numberOfLines = 1
        label.textAlignment = .center
    }

    // MARK: - Properties
    var model: MenuElement?

    // MARK: - Initializers
    func configureCellWith(model: MenuElement) {
        self.model = model
        self.titleLabel.text = model.title
        self.icon.image = UIImage(named: model.iconName)?.withRenderingMode(.alwaysTemplate)
        self.backgroundIconView.layer.cornerRadius = UX.backgroundIconViewCornerRadius
        self.isAccessibilityElement = true
        self.isUserInteractionEnabled = !model.isEnabled ? false : true
        self.accessibilityIdentifier = model.a11yId
        self.accessibilityLabel = model.a11yLabel
        self.accessibilityHint = model.a11yHint
        self.accessibilityTraits = .button
        setupView()
    }

    private func setupView() {
        self.addSubview(backgroundIconView)
        self.addSubview(titleLabel)
        self.backgroundIconView.addSubview(icon)
        NSLayoutConstraint.activate([
            backgroundIconView.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundIconView.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: UX.horizontalMargin),
            backgroundIconView.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: -UX.horizontalMargin),

            icon.centerYAnchor.constraint(equalTo: backgroundIconView.centerYAnchor),
            icon.centerXAnchor.constraint(equalTo: backgroundIconView.centerXAnchor),
            icon.widthAnchor.constraint(equalToConstant: UX.iconSize),
            icon.heightAnchor.constraint(equalToConstant: UX.iconSize),

            titleLabel.topAnchor.constraint(equalTo: backgroundIconView.bottomAnchor, constant: UX.verticalMargin),
            titleLabel.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: UX.horizontalMargin),
            titleLabel.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: -UX.horizontalMargin),
            titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    // MARK: - Theme Applicable
    func applyTheme(theme: Theme) {
        backgroundColor = .clear
        backgroundIconView.backgroundColor = theme.colors.layer2
        icon.tintColor = theme.colors.iconPrimary
        titleLabel.textColor = theme.colors.textPrimary
    }
}
