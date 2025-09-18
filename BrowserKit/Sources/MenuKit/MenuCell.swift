// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

final class MenuCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let contentMargin: CGFloat = 16
        static let horizontalMargin: CGFloat = 24
        static let iconSize: CGFloat = 24
        static let contentSpacing: CGFloat = 3
        static let noDescriptionContentSpacing: CGFloat = 0
        static let cornerRadius: CGFloat = 16
    }

    // MARK: - UI Elements
    private var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
    }

    private var descriptionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.numberOfLines = 0
    }

    private var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.distribution = .fill
    }

    private var iconImageView: UIImageView = .build()

    private var horizontalMargin: CGFloat {
        if #available(iOS 26.0, *) {
            return UX.horizontalMargin
        } else {
            return UX.contentMargin
        }
    }

    // MARK: - Properties
    var model: MenuElement?

    private var isFirstCell = false
    private var isLastCell = false

    private var mainMenuHelper: MainMenuInterface?

    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        configureCornerRadiusForCellPosition()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        isFirstCell = false
        isLastCell = false
    }

    func configureCellWith(
        model: MenuElement,
        theme: Theme,
        isFirstCell: Bool,
        isLastCell: Bool,
        mainMenuHelper: MainMenuInterface = MainMenuHelper()
    ) {
        self.model = model
        self.mainMenuHelper = mainMenuHelper
        self.isFirstCell = isFirstCell
        self.isLastCell = isLastCell
        self.titleLabel.text = model.title
        self.descriptionLabel.text = model.description
        self.contentStackView.spacing = model.description != nil ? UX.contentSpacing : UX.noDescriptionContentSpacing
        self.iconImageView.image = UIImage(named: model.iconName)?
            .withRenderingMode(.alwaysTemplate)
            .imageFlippedForRightToLeftLayoutDirection()
        self.isAccessibilityElement = true
        self.isUserInteractionEnabled = !model.isEnabled ? false : true
        self.accessibilityIdentifier = model.a11yId
        self.accessibilityLabel = model.a11yLabel
        self.accessibilityHint = model.a11yHint
        self.accessibilityTraits = .button
        self.separatorInset = .zero
    }

    private func setupView() {
        self.addSubview(contentStackView)
        self.addSubview(iconImageView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)
        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalMargin),
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: UX.contentMargin),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.contentMargin),

            iconImageView.leadingAnchor.constraint(equalTo: contentStackView.trailingAnchor,
                                                   constant: UX.contentMargin),
            iconImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalMargin),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: UX.iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: UX.iconSize)
        ])
    }

    private func configureCornerRadiusForCellPosition() {
        if #unavailable(iOS 26.0) {
            guard isFirstCell || isLastCell else { return }
            self.clipsToBounds = true
            layer.cornerRadius = UX.cornerRadius
            layer.maskedCorners = {
                var corners: CACornerMask = []
                if isFirstCell { corners.formUnion([.layerMinXMinYCorner, .layerMaxXMinYCorner]) }
                if isLastCell { corners.formUnion([.layerMinXMaxYCorner, .layerMaxXMaxYCorner]) }
                return corners
            }()
        }
    }

    // MARK: - Theme Applicable
    func applyTheme(theme: Theme) {
        guard let model else { return }
        backgroundColor = theme.colors.layerSurfaceMedium.withAlphaComponent(mainMenuHelper?.backgroundAlpha() ?? 1.0)
        if model.isActive {
            titleLabel.textColor = theme.colors.textAccent
            descriptionLabel.textColor = theme.colors.textSecondary
            iconImageView.tintColor = theme.colors.iconAccentBlue
        } else if !model.isEnabled {
            titleLabel.textColor = theme.colors.textDisabled
            descriptionLabel.textColor = theme.colors.textDisabled
            iconImageView.tintColor = theme.colors.iconDisabled
        } else {
            titleLabel.textColor = theme.colors.textPrimary
            descriptionLabel.textColor = theme.colors.textSecondary
            iconImageView.tintColor = theme.colors.iconPrimary
        }
    }
}
