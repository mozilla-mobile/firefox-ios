// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

// TODO: FXIOS-12302 Create the UI for different accessibility sizes, for horizontal options section
final class MenuSquareView: UIView, ThemeApplicable {
    private struct UX {
        static let iconSize: CGFloat = 24
        static let backgroundViewCornerRadius: CGFloat = 12
        static let horizontalMargin: CGFloat = 6
        static let contentViewSpacing: CGFloat = 4
        static let contentViewTopMargin: CGFloat = 12
        static let contentViewBottomMargin: CGFloat = 8
        static let contentViewHorizontalMargin: CGFloat = 4
    }

    // MARK: - UI Elements
    private var backgroundContentView: UIView = .build()

    private var contentStackView: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.spacing = UX.contentViewSpacing
        stack.distribution = .fillProportionally
    }

    private var icon: UIImageView = .build { view in
        view.contentMode = .scaleAspectFit
    }

    private var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption2.scaledFont()
        label.numberOfLines = 1
        label.textAlignment = .center
    }

    // MARK: - Properties
    var model: MenuElement?

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not yet supported")
    }

    func configureCellWith(model: MenuElement) {
        self.model = model
        self.titleLabel.text = model.title
        self.icon.image = UIImage(named: model.iconName)?.withRenderingMode(.alwaysTemplate)
        self.backgroundContentView.layer.cornerRadius = UX.backgroundViewCornerRadius
        self.isAccessibilityElement = true
        self.isUserInteractionEnabled = !model.isEnabled ? false : true
        self.accessibilityIdentifier = model.a11yId
        self.accessibilityLabel = model.a11yLabel
        self.accessibilityHint = model.a11yHint
        self.accessibilityTraits = .button
    }

    private func setupView() {
        self.addSubview(backgroundContentView)
        backgroundContentView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(icon)
        contentStackView.addArrangedSubview(titleLabel)
        NSLayoutConstraint.activate([
            backgroundContentView.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundContentView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundContentView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            backgroundContentView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            contentStackView.topAnchor.constraint(
                equalTo: backgroundContentView.topAnchor,
                constant: UX.contentViewTopMargin
            ),
            contentStackView.leadingAnchor.constraint(
                equalTo: backgroundContentView.leadingAnchor,
                constant: UX.contentViewHorizontalMargin
            ),
            contentStackView.trailingAnchor.constraint(
                equalTo: backgroundContentView.trailingAnchor,
                constant: -UX.contentViewHorizontalMargin
            ),
            contentStackView.bottomAnchor.constraint(
                equalTo: backgroundContentView.bottomAnchor,
                constant: -UX.contentViewBottomMargin
            ),
            icon.heightAnchor.constraint(equalToConstant: UX.iconSize)
        ])
    }

    // MARK: - Theme Applicable
    func applyTheme(theme: Theme) {
        backgroundColor = .clear
        contentStackView.backgroundColor = .clear
        backgroundContentView.backgroundColor = theme.colors.layer2
        icon.tintColor = theme.colors.iconPrimary
        titleLabel.textColor = theme.colors.textSecondary
    }
}
