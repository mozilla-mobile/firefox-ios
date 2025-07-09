// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

final class MenuAccountCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let contentMargin: CGFloat = 16
        static let iconSize: CGFloat = 24
        static let contentSpacing: CGFloat = 3
        static let noDescriptionContentSpacing: CGFloat = 0
        static let cornerRadius: CGFloat = 16
        static let backgroundAlpha: CGFloat = 0.8
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

    // MARK: - Properties
    var model: MenuElement?

    var shouldConfigureImageView: Bool {
        return model?.iconImage != nil && (model?.needsReAuth == nil || model?.needsReAuth == false)
    }

    private var isFirstCell = false
    private var isLastCell = false

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
        if shouldConfigureImageView {
            iconImageView.layer.cornerRadius = iconImageView.frame.size.width / 2
        } else {
            iconImageView.layer.cornerRadius = 0
        }
        iconImageView.clipsToBounds = shouldConfigureImageView
        configureCornerRadiusForCellPosition()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        isFirstCell = false
        isLastCell = false
    }

    func configureCellWith(model: MenuElement, theme: Theme, isFirstCell: Bool, isLastCell: Bool) {
        self.model = model
        self.isFirstCell = isFirstCell
        self.isLastCell = isLastCell
        titleLabel.text = model.title
        descriptionLabel.text = model.description
        contentStackView.spacing = model.description != nil ? UX.contentSpacing : UX.noDescriptionContentSpacing
        if let needsReAuth = model.needsReAuth, needsReAuth {
            typealias Icons = StandardImageIdentifiers.Large
            if theme.type == .light {
                iconImageView.image = UIImage(named: Icons.avatarWarningCircleFillMulticolorLight)
            } else {
                iconImageView.image = UIImage(named: Icons.avatarWarningCircleFillMulticolorDark)
            }
        } else if let iconImage = model.iconImage {
            iconImageView.image = iconImage
        } else {
            iconImageView.image = UIImage(named: model.iconName)?.withRenderingMode(.alwaysTemplate)
        }
        isAccessibilityElement = true
        isUserInteractionEnabled = !model.isEnabled ? false : true
        accessibilityIdentifier = model.a11yId
        accessibilityLabel = model.a11yLabel
        accessibilityHint = model.a11yHint
        accessibilityTraits = .button
        separatorInset = .zero
    }

    private func setupView() {
        addSubview(contentStackView)
        addSubview(iconImageView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)
        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.contentMargin),
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: UX.contentMargin),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.contentMargin)
        ])

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentStackView.trailingAnchor,
                                                   constant: UX.contentMargin),
            iconImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.contentMargin),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: UX.iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: UX.iconSize)
        ])
    }

    private func configureCornerRadiusForCellPosition() {
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

    // MARK: - Theme Applicable
    func applyTheme(theme: Theme) {
        guard let model else { return }
        backgroundColor = theme.colors.layer2.withAlphaComponent(UX.backgroundAlpha)
        if let needsReAuth = model.needsReAuth, needsReAuth {
            descriptionLabel.textColor = theme.colors.textCritical
        } else if model.iconImage != nil {
            descriptionLabel.textColor = theme.colors.textSecondary
        } else {
            descriptionLabel.textColor = theme.colors.textSecondary
            iconImageView.tintColor = theme.colors.iconPrimary
        }
        titleLabel.textColor = theme.colors.textPrimary
    }
}
